#!/bin/bash
# Pubblica su TestFlight dal Mac: test sul simulatore, numero di build +1, Archive Release,
# upload su App Store Connect con xcodebuild e assegnazione al gruppo «Personale».
# La chiave API resta fuori dal repository (pubblico):
#   ~/.appstoreconnect/config                         ASC_KEY_ID=… e ASC_ISSUER_ID=…
#   ~/.appstoreconnect/private_keys/AuthKey_<ID>.p8   chiave privata scaricata da App Store Connect
# Il commit e il push li fa chi lancia lo script, dopo l'upload riuscito.
set -euo pipefail
cd "$(dirname "$0")/.."

CONF="$HOME/.appstoreconnect"
[ -f "$CONF/config" ] || { echo "❌ Manca $CONF/config (ASC_KEY_ID e ASC_ISSUER_ID)"; exit 1; }
# shellcheck disable=SC1091
source "$CONF/config"
KEY="$CONF/private_keys/AuthKey_${ASC_KEY_ID}.p8"
[ -f "$KEY" ] || { echo "❌ Manca la chiave $KEY"; exit 1; }
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEY"
      -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")

# Python con `cryptography` per asc.py, in un ambiente fuori dal repository.
if [ ! -x "$CONF/venv/bin/python" ]; then
  python3 -m venv "$CONF/venv"
  "$CONF/venv/bin/pip" install --quiet cryptography
fi

mkdir -p build
fail() { echo "❌ $1 (log: ios/$2)"; grep -E "error:|failed|FAILED" "$2" | sort -u | cut -c1-300 | head -20; exit 1; }

echo "▶ Genero il progetto"
xcodegen generate --quiet

echo "▶ Test sul simulatore"
SIM=$(xcrun simctl list devices available | grep -m1 -E '^[[:space:]]+iPhone' | grep -oE '[0-9A-F-]{36}')
xcodebuild test -project StepTeller.xcodeproj -scheme StepTeller -destination "id=$SIM" \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO > build/test.log 2>&1 \
  || fail "Test falliti" build/test.log
grep -q "TEST SUCCEEDED" build/test.log || fail "Test non conclusi" build/test.log

VERSION=$(grep -E '^[[:space:]]+MARKETING_VERSION:' project.yml | grep -oE '[0-9.]+')
OLD=$(grep -E '^[[:space:]]+CURRENT_PROJECT_VERSION:' project.yml | grep -oE '[0-9]+')
BUILD=$((OLD + 1))
sed -i '' -E "s/^([[:space:]]+CURRENT_PROJECT_VERSION: )\"$OLD\"/\1\"$BUILD\"/" project.yml
echo "▶ Versione $VERSION, build $BUILD"
xcodegen generate --quiet

echo "▶ Archive Release"
rm -rf build/StepTeller.xcarchive build/TestFlight
xcodebuild -project StepTeller.xcodeproj -scheme StepTeller -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/StepTeller.xcarchive \
  -derivedDataPath build/DerivedData "${AUTH[@]}" \
  COMMIT_SHA="$(git rev-parse --short HEAD)" archive > build/archive.log 2>&1 \
  || fail "Archive fallito" build/archive.log

echo "▶ Upload su App Store Connect"
cat > build/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>5E426PLFWN</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath build/StepTeller.xcarchive -exportPath build/TestFlight \
  -exportOptionsPlist build/ExportOptions.plist "${AUTH[@]}" > build/upload.log 2>&1 \
  || fail "Upload fallito" build/upload.log

echo "▶ Attendo Apple e assegno la build a «Personale»"
BUILD_NUMBER="$BUILD" ASC_KEY_ID="$ASC_KEY_ID" ASC_ISSUER_ID="$ASC_ISSUER_ID" ASC_PRIVATE_KEY="$(cat "$KEY")" \
  PYTHONDONTWRITEBYTECODE=1 "$CONF/venv/bin/python" scripts/asc.py distribute

echo "✅ PUBBLICATA $VERSION (build $BUILD)"
