#!/bin/bash
# Baut, signiert und notarisiert PingDot für die Veröffentlichung.
#
# Einmalig vorher:
#   1. „Developer ID Application"-Zertifikat im Schlüsselbund installieren.
#   2. Zugangsdaten für die Notarisierung hinterlegen:
#        xcrun notarytool store-credentials pingdot-notary --apple-id <Apple-ID> --team-id <Team-ID>
#
# Aufruf:
#   PINGDOT_IDENTITY="Developer ID Application: Name (TEAMID)" ./release.sh
set -euo pipefail
cd "$(dirname "$0")"

IDENTITY="${PINGDOT_IDENTITY:?PINGDOT_IDENTITY fehlt (siehe Kopf dieser Datei)}"
PROFILE="${PINGDOT_NOTARY_PROFILE:-pingdot-notary}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)"
APP="build/PingDot.app"
ZIP="build/PingDot-$VERSION.zip"

./build.sh
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"

ditto -c -k --keepParent "$APP" build/notarize.zip
xcrun notarytool submit build/notarize.zip --keychain-profile "$PROFILE" --wait
rm build/notarize.zip

xcrun stapler staple "$APP"
ditto -c -k --keepParent "$APP" "$ZIP"
spctl --assess --type execute --verbose "$APP"
echo "Fertig: $ZIP"
