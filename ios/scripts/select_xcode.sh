#!/bin/bash
# Selects the most recent stable Xcode (>= 26) on the macOS runner and exports it in DEVELOPER_DIR.
set -euo pipefail
best=$(ls -d /Applications/Xcode_26*.app 2>/dev/null | grep -vi -e beta -e rc | sort -V | tail -1 || true)
if [ -z "$best" ]; then echo "::error::Nessun Xcode 26 stabile sul runner"; ls /Applications | grep -i xcode; exit 1; fi
echo "DEVELOPER_DIR=$best/Contents/Developer" >> "$GITHUB_ENV"
echo "Xcode selezionato: $best"
