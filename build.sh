#!/bin/bash
# Baut PingDot.app (Apple Silicon + Intel) nach ./build.
# Mit `CONFIGURATION=debug ./build.sh` entsteht ein unoptimierter Build mit Debug-Symbolen.
# Mit `./build.sh install` zusätzlich nach /Applications kopieren und starten.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/PingDot.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

if [ "${CONFIGURATION:-release}" = "debug" ]; then FLAGS="-Onone -g"; else FLAGS="-O"; fi

for arch in arm64 x86_64; do
    swiftc $FLAGS -target "$arch-apple-macos13.0" Sources/*.swift -o "build/PingDot-$arch"
done
lipo -create build/PingDot-arm64 build/PingDot-x86_64 -output "$APP/Contents/MacOS/PingDot"
rm build/PingDot-arm64 build/PingDot-x86_64

codesign --force --sign - "$APP"
echo "Gebaut: $APP"

if [ "${1:-}" = "install" ]; then
    pkill -x PingDot 2>/dev/null || true
    while pgrep -x PingDot >/dev/null; do sleep 0.2; done   # sonst scheitert das erneute Öffnen gelegentlich
    rm -rf /Applications/PingDot.app
    cp -R "$APP" /Applications/PingDot.app
    open /Applications/PingDot.app
    echo "Installiert und gestartet: /Applications/PingDot.app"
fi
