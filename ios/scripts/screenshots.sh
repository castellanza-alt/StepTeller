#!/bin/bash
# Screenshot sul simulatore (iPhone 15 Pro Max se disponibile) in chiaro e scuro.
# Usa il fornitore finto SOLO della build Debug (argomenti di avvio), mai l'app distribuita.
set -euo pipefail
APP="$1"; OUT="$2"; mkdir -p "$OUT"
BID=it.castellanza.stepteller
RUNTIME=$(xcrun simctl list runtimes available -j | python3 -c "import json,sys;r=[x for x in json.load(sys.stdin)['runtimes'] if x['platform']=='iOS'];print(sorted(r,key=lambda x:x['version'])[-1]['identifier'])")
TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max
if ! xcrun simctl list devicetypes | grep -q "iPhone-15-Pro-Max"; then
  TYPE=$(xcrun simctl list devicetypes | grep -o 'com.apple.CoreSimulator.SimDeviceType.iPhone-[0-9]*-Pro-Max' | sort -V | tail -1)
fi
echo "runtime=$RUNTIME tipo=$TYPE"
UDID=$(xcrun simctl create StepTellerShots "$TYPE" "$RUNTIME")
xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 || true
shot() { # nome tema passi velocità
  xcrun simctl ui "$UDID" appearance "$2"
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  xcrun simctl launch "$UDID" $BID -stepteller.debugSteps "$3" -stepteller.speed "$4" -stepteller.goal 10000 >/dev/null
  sleep 5
  xcrun simctl io "$UDID" screenshot "$OUT/$1-$2.png"
}
for theme in light dark; do
  shot cammino-6 $theme 7200 6.0
  shot corsa-8-3 $theme 7200 8.3
  shot fatto $theme 10729 4.5
  shot zero-10 $theme 0 10.0
done
wshot() { # nome passi (vuoto = dato non disponibile)
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  if [ -n "$2" ]; then
    xcrun simctl launch "$UDID" $BID -stepteller.debugWidget 1 -stepteller.debugSteps "$2" >/dev/null
  else
    xcrun simctl launch "$UDID" $BID -stepteller.debugWidget 1 >/dev/null
  fi
  sleep 3
  xcrun simctl io "$UDID" screenshot "$OUT/widget-$1.png"
}
fshot() { # festa «Obiettivo raggiunto» a metà animazione
  xcrun simctl ui "$UDID" appearance "$1"
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  xcrun simctl launch "$UDID" $BID -stepteller.debugSteps 10729 -stepteller.debugCelebrate 1 -stepteller.goal 10000 >/dev/null
  sleep 2.2
  xcrun simctl io "$UDID" screenshot "$OUT/festa-$1.png"
}
fshot light
fshot dark
xcrun simctl ui "$UDID" appearance dark
wshot parziale 7200
wshot fatto 10450
wshot zero 0
wshot nodati ""
hshot() { # nome tab periodo [sheet]
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  extra=""
  [ "${4:-}" = "sheet" ] && extra="-stepteller.debugSheet 1"
  xcrun simctl launch "$UDID" $BID -stepteller.debugSteps 7200 -stepteller.debugHistory 1 -stepteller.debugTab "$2" -stepteller.debugPeriod "$3" -stepteller.speed 6.0 -stepteller.goal 10000 $extra >/dev/null
  sleep 5
  xcrun simctl io "$UDID" screenshot "$OUT/$1.png"
}
for theme in dark light; do
  xcrun simctl ui "$UDID" appearance $theme
  hshot storico-sett-$theme storico week
  hshot storico-mese-$theme storico month
  hshot storico-anno-$theme storico year
  hshot streak-$theme streak week
done
xcrun simctl ui "$UDID" appearance dark
hshot oggi-storia-dark oggi week
hshot impostazioni-dark storico week sheet
xcrun simctl delete "$UDID"
ls -la "$OUT"
