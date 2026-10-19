#!/bin/bash
# Screenshot sul simulatore (iPhone 15 Pro Max se disponibile), tema giorno e notte.
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
# Salute può rilanciare l'app in background senza argomenti di avvio: quella istanza non deve chiedere il
# permesso notifiche (il popup resterebbe sopra tutti gli screenshot). Promemoria spento in partenza.
xcrun simctl spawn "$UDID" defaults write $BID stepteller.reminder.on -bool NO
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 || true
shot() { # nome tema(day/night) passi velocità [argomenti extra…]
  name=$1; theme=$2; steps=$3; speed=$4; shift 4
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  xcrun simctl launch --terminate-running-process "$UDID" $BID -stepteller.debugSteps "$steps" -stepteller.debugHistory 1 -stepteller.speed "$speed" \
    -stepteller.goal 10000 -stepteller.themeMode "$theme" "$@" >/dev/null
  sleep 5
  xcrun simctl io "$UDID" screenshot "$OUT/$name-$theme.png"
}
for theme in day night; do
  shot home-4kmh $theme 3465 4.0
  shot home-16kmh $theme 3465 16.0
  shot home-fatto $theme 10729 6.0
  shot home-nodati $theme -1 4.0
  shot storico-sett $theme 3465 4.0 -stepteller.debugTab storico
  shot storico-mese $theme 3465 4.0 -stepteller.debugTab storico -stepteller.debugPeriod month
  shot storico-anno $theme 3465 4.0 -stepteller.debugTab storico -stepteller.debugPeriod year
  shot storico-sempre $theme 3465 4.0 -stepteller.debugTab storico -stepteller.debugPeriod all
done
shot impostazioni night 3465 4.0 -stepteller.debugSheet 1
oshot() { # introduzione: pagina (1–4) tema
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  xcrun simctl launch --terminate-running-process "$UDID" $BID -stepteller.debugOnboarding "$1" -stepteller.themeMode "$2" \
    -stepteller.reminder.on YES >/dev/null
  sleep 4
  xcrun simctl io "$UDID" screenshot "$OUT/intro-$1-$2.png"
}
for theme in day night; do for p in 1 2 3 4; do oshot $p $theme; done; done
wshot() { # nome passi (vuoto = dato non disponibile)
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  if [ -n "$2" ]; then
    xcrun simctl launch --terminate-running-process "$UDID" $BID -stepteller.debugWidget 1 -stepteller.debugSteps "$2" >/dev/null
  else
    xcrun simctl launch --terminate-running-process "$UDID" $BID -stepteller.debugWidget 1 >/dev/null
  fi
  sleep 3
  xcrun simctl io "$UDID" screenshot "$OUT/widget-$1.png"
}
fshot() { # festa «Obiettivo raggiunto» a metà animazione
  xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
  xcrun simctl launch --terminate-running-process "$UDID" $BID -stepteller.debugSteps 10729 -stepteller.debugCelebrate 1 -stepteller.goal 10000 -stepteller.themeMode "$1" >/dev/null
  sleep 2.2
  xcrun simctl io "$UDID" screenshot "$OUT/festa-$1.png"
}
fshot day
fshot night
xcrun simctl ui "$UDID" appearance dark
wshot parziale 7200
wshot fatto 10450
wshot zero 0
wshot nodati ""
xcrun simctl delete "$UDID"
ls -la "$OUT"
