#!/bin/bash
# Baut PingDot für die Veröffentlichung und packt es als build/PingDot-<Version>.zip.
#
# Ohne PINGDOT_IDENTITY entsteht ein unsigniertes Zip (Nutzer müssen die App beim ersten Start freigeben).
# Mit PINGDOT_IDENTITY wird mit Developer ID signiert und bei Apple notarisiert:
#
#   PINGDOT_IDENTITY="Developer ID Application: Name (TEAMID)" ./release.sh
#
# Zugangsdaten für die Notarisierung, eine der beiden Varianten:
#   a) Umgebungsvariablen APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD (so macht es der GitHub-Workflow)
#   b) einmalig lokal hinterlegt:
#        xcrun notarytool store-credentials pingdot-notary --apple-id <Apple-ID> --team-id <Team-ID>
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)"
APP="build/PingDot.app"
ZIP="build/PingDot-$VERSION.zip"

./build.sh

if [ -n "${PINGDOT_IDENTITY:-}" ]; then
    codesign --force --options runtime --timestamp --sign "$PINGDOT_IDENTITY" "$APP"

    if [ -n "${APPLE_APP_PASSWORD:-}" ]; then
        CREDENTIALS=(--apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD")
    else
        CREDENTIALS=(--keychain-profile "${PINGDOT_NOTARY_PROFILE:-pingdot-notary}")
    fi
    ditto -c -k --keepParent "$APP" build/notarize.zip
    xcrun notarytool submit build/notarize.zip "${CREDENTIALS[@]}" --wait
    rm build/notarize.zip

    xcrun stapler staple "$APP"
    spctl --assess --type execute --verbose "$APP"
else
    echo "Hinweis: PINGDOT_IDENTITY ist nicht gesetzt, die App wird unsigniert gepackt."
fi

ditto -c -k --keepParent "$APP" "$ZIP"
echo "Fertig: $ZIP"
