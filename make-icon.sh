#!/bin/bash
# Erzeugt AppIcon.icns aus make-icon.swift. Nur nötig, wenn das Icon geändert wird.
set -euo pipefail
cd "$(dirname "$0")"

TMP="$(mktemp -d)"
SET="$TMP/AppIcon.iconset"
mkdir "$SET"
swift make-icon.swift "$TMP/icon.png"

for s in 16 32 128 256 512; do
    sips -z $s $s "$TMP/icon.png" --out "$SET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s * 2)) $((s * 2)) "$TMP/icon.png" --out "$SET/icon_${s}x${s}@2x.png" >/dev/null
done

iconutil -c icns "$SET" -o AppIcon.icns
cp "$TMP/icon.png" icon-preview.png
rm -rf "$TMP"
echo "Erzeugt: AppIcon.icns"
