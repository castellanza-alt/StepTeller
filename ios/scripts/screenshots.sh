#!/bin/bash
# Screenshots on the simulator (iPhone 15 Pro Max when available), day and night theme.
# Uses the fake provider of the Debug build ONLY (launch arguments), never the shipped app.
# Usage: screenshots.sh APP OUTPUT [language] [day]
#   language: it (default), en, es, fr, de, pt-BR, ja, ko, zh-Hans, zh-Hant → -AppleLanguages and -AppleLocale
#   day: day theme only (Settings included), to check a language faster
set -euo pipefail
APP="$1"; OUT="$2"; LINGUA="${3:-it}"; MODO="${4:-completo}"; mkdir -p "$OUT"
case "$LINGUA" in
  it) LOCALE=it_IT ;; en) LOCALE=en_US ;; es) LOCALE=es_ES ;; fr) LOCALE=fr_FR ;; de) LOCALE=de_DE ;;
  pt-BR) LOCALE=pt_BR ;; ja) LOCALE=ja_JP ;; ko) LOCALE=ko_KR ;; zh-Hans) LOCALE=zh_CN ;; zh-Hant) LOCALE=zh_TW ;;
  *) echo "lingua sconosciuta: $LINGUA"; exit 1 ;;
esac
LOC=(-AppleLanguages "($LINGUA)" -AppleLocale "$LOCALE")
THEMES="day night"; SHEET_THEME=night
if [ "$MODO" = giorno ]; then THEMES=day; SHEET_THEME=day; fi
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
# Health may relaunch the app in the background without launch arguments: that instance must not ask for
# the notification permission (the popup would stay over every screenshot). Reminder off from the start.
xcrun simctl spawn "$UDID" defaults write $BID stepteller.reminder.on -bool NO
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 || true
shot() { # name theme(day/night) steps speed [extra arguments…]
  name=$1; theme=$2; steps=$3; speed=$4; shift 4
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  xcrun simctl launch --terminate-running-process "$UDID" $BID -stepteller.debugSteps "$steps" -stepteller.debugHistory 1 -stepteller.speed "$speed" \
    -stepteller.goal 10000 -stepteller.themeMode "$theme" "$@" "${LOC[@]}" >/dev/null
  sleep 5
  xcrun simctl io "$UDID" screenshot "$OUT/$name-$theme.png"
}
for theme in $THEMES; do
  shot home-4kmh $theme 3465 4.0
  shot home-16kmh $theme 3465 16.0
  shot home-fatto $theme 10729 6.0
  shot home-nodati $theme -1 4.0
  shot storico-sett $theme 3465 4.0 -stepteller.debugTab storico
  shot storico-mese $theme 3465 4.0 -stepteller.debugTab storico -stepteller.debugPeriod month
  shot storico-anno $theme 3465 4.0 -stepteller.debugTab storico -stepteller.debugPeriod year
  shot storico-sempre $theme 3465 4.0 -stepteller.debugTab storico -stepteller.debugPeriod all
  # lower part of the History screen (tabs, chart, «My best»): to check text lengths
  shot storico-sett-grafico $theme 3465 4.0 -stepteller.debugTab storico -stepteller.debugScroll 0.62
  shot storico-anno-meglio $theme 3465 4.0 -stepteller.debugTab storico -stepteller.debugPeriod year -stepteller.debugScroll 1
done
shot impostazioni $SHEET_THEME 3465 4.0 -stepteller.debugSheet 1
oshot() { # introduction: page (1–4) theme
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  xcrun simctl launch --terminate-running-process "$UDID" $BID -stepteller.debugOnboarding "$1" -stepteller.themeMode "$2" \
    -stepteller.reminder.on YES "${LOC[@]}" >/dev/null
  sleep 4
  xcrun simctl io "$UDID" screenshot "$OUT/intro-$1-$2.png"
}
for theme in $THEMES; do for p in 1 2 3 4; do oshot $p $theme; done; done
wshot() { # name steps (empty = data unavailable) [night]
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  EXTRA=(); SUFFIX=""
  if [ -n "${3:-}" ]; then EXTRA=(-stepteller.themeMode "$3"); SUFFIX="-$3"; fi
  if [ -n "$2" ]; then EXTRA+=(-stepteller.debugSteps "$2"); fi
  xcrun simctl launch --terminate-running-process "$UDID" $BID -stepteller.debugWidget 1 ${EXTRA[@]+"${EXTRA[@]}"} "${LOC[@]}" >/dev/null
  sleep 3
  xcrun simctl io "$UDID" screenshot "$OUT/widget-$1$SUFFIX.png"
}
fshot() { # «Goal reached» celebration mid-animation
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  xcrun simctl launch --terminate-running-process "$UDID" $BID -stepteller.debugSteps 10729 -stepteller.debugCelebrate 1 -stepteller.goal 10000 -stepteller.themeMode "$1" "${LOC[@]}" >/dev/null
  sleep 2.2
  xcrun simctl io "$UDID" screenshot "$OUT/festa-$1.png"
}
for theme in $THEMES; do fshot $theme; done
xcrun simctl ui "$UDID" appearance dark
wshot parziale 7200
wshot fatto 10450
wshot zero 0
wshot nodati ""
if [ "$MODO" != giorno ]; then wshot parziale 7200 night; wshot fatto 10450 night; fi
xcrun simctl delete "$UDID"
ls -la "$OUT"
