#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(grep -m1 'MARKETING_VERSION' "$ROOT/project.yml" | sed -E 's/.*"([^"]+)".*/\1/')}"
APP="${2:-$ROOT/build/Build/Products/Release/Notey.app}"
OUT="$ROOT/dist"
VOLUME="Notey"
STAGE="$(mktemp -d)"
RW="$STAGE/rw.dmg"
FINAL="$OUT/Notey-$VERSION.dmg"

if [ ! -d "$APP" ]; then
    xcodebuild -project "$ROOT/Notey.xcodeproj" -scheme Notey -configuration Release \
        -derivedDataPath "$ROOT/build" CODE_SIGNING_ALLOWED=NO build >/dev/null
fi

mkdir -p "$OUT" "$STAGE/bg"
swiftc -o "$STAGE/bgtool" "$ROOT/scripts/dmg-background.swift"
"$STAGE/bgtool" "$STAGE/bg"
tiffutil -cathidpicheck "$STAGE/bg/background.png" "$STAGE/bg/background@2x.png" -out "$STAGE/bg/background.tiff"

hdiutil detach "/Volumes/$VOLUME" >/dev/null 2>&1 || true
hdiutil create -size 80m -fs HFS+ -volname "$VOLUME" -ov "$RW" >/dev/null
hdiutil attach "$RW" -noverify -noautoopen -mountpoint "/Volumes/$VOLUME" >/dev/null

ditto "$APP" "/Volumes/$VOLUME/Notey.app"
ln -s /Applications "/Volumes/$VOLUME/Applications"
mkdir "/Volumes/$VOLUME/.background"
cp "$STAGE/bg/background.tiff" "/Volumes/$VOLUME/.background/background.tiff"

osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 860, 520}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 112
        set text size of viewOptions to 13
        set background picture of viewOptions to file ".background:background.tiff"
        set position of item "Notey.app" of container window to {170, 200}
        set position of item "Applications" of container window to {490, 200}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

sync
chmod -Rf go-w "/Volumes/$VOLUME" || true
hdiutil detach "/Volumes/$VOLUME" >/dev/null
rm -f "$FINAL"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$FINAL" >/dev/null
rm -rf "$STAGE"
echo "$FINAL"
