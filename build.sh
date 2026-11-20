#!/bin/bash
# Baut PingDot.app nach ./build. Mit `./build.sh install` zusätzlich nach /Applications kopieren und starten.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/PingDot.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
swiftc -O main.swift -o "$APP/Contents/MacOS/PingDot"
codesign --force --sign - "$APP"
echo "Gebaut: $APP"

if [ "${1:-}" = "install" ]; then
    pkill -x PingDot 2>/dev/null || true
    rm -rf /Applications/PingDot.app
    cp -R "$APP" /Applications/PingDot.app
    open /Applications/PingDot.app
    echo "Installiert und gestartet: /Applications/PingDot.app"
fi
