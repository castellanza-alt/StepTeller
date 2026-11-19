#!/bin/bash
# T-030: Home con cuore e fumetto (N007) per gli screenshot dello store. Uso: shoot.sh APP OUT lingua...
set -euo pipefail
APP="$1"; OUT="$2"; shift 2
BID=it.castellanza.stepteller
UDID=$(xcrun simctl create T030Shots com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max com.apple.CoreSimulator.SimRuntime.iOS-27-0)
echo "$UDID" > /Volumes/SSD/Temp/NEAT/t030/udid
xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 || true
D() { xcrun simctl spawn "$UDID" defaults "$@"; }
D write $BID stepteller.reminder.on -bool NO
for L in "$@"; do
  case "$L" in it) LOC=it_IT;; en) LOC=en_US;; es) LOC=es_ES;; fr) LOC=fr_FR;; de) LOC=de_DE;; pt-BR) LOC=pt_BR;;
    ja) LOC=ja_JP;; ko) LOC=ko_KR;; zh-Hans) LOC=zh_CN;; zh-Hant) LOC=zh_TW;; esac
  mkdir -p "$OUT/$L"
  shot() { name=$1; theme=$2; speed=$3
    xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
    SINCE=$(python3 -c "import time;print(time.time()-978307200-30)")
    JSON=$(printf '{"id":"N007","level":"nasty","situations":["pochiPassi"],"since":%s,"heart":false}' "$SINCE")
    HEX=$(printf '%s' "$JSON" | xxd -p | tr -d '\n')
    xcrun simctl launch --terminate-running-process "$UDID" $BID -stepteller.debugSteps 3465 -stepteller.debugHistory 1 \
      -stepteller.speed "$speed" -stepteller.goal 10000 -stepteller.themeMode "$theme" -stepteller.voice.bubble "<$HEX>" -stepteller.voice.firstLine done \
      -AppleLanguages "($L)" -AppleLocale "$LOC" >/dev/null
    sleep 7
    xcrun simctl io "$UDID" screenshot "$OUT/$L/$name.png" >/dev/null 2>&1
  }
  shot home-4kmh-day day 4.0
  shot home-10kmh-day day 10.0
  shot home-10kmh-night night 10.0
  echo "$L ok"
done
xcrun simctl shutdown "$UDID"; xcrun simctl delete "$UDID"; rm -f /Volumes/SSD/Temp/NEAT/t030/udid
