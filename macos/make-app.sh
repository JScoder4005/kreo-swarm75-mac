#!/bin/sh
# Build Kreo.app into macos/build/ for use on this Mac.
# Signs with the "Kreo Local Signing" keychain identity when present, so macOS keeps the
# Input Monitoring permission across rebuilds; falls back to ad hoc signing otherwise.
set -e
cd "$(dirname "$0")"
swift build -c release
APP=build/Kreo.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/KreoMenu "$APP/Contents/MacOS/Kreo"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Kreo</string>
  <key>CFBundleDisplayName</key><string>Kreo</string>
  <key>CFBundleIdentifier</key><string>com.jscoder4005.kreo</string>
  <key>CFBundleExecutable</key><string>Kreo</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict>
</plist>
PLIST
IDENTITY="${KREO_SIGN_ID:-Kreo Local Signing}"
if security find-identity -p codesigning | grep -q "\"$IDENTITY\""; then
  codesign --force --sign "$IDENTITY" "$APP"
else
  echo "note: no \"$IDENTITY\" identity; signing ad hoc (Input Monitoring must be re-allowed after each build)"
  codesign --force --sign - "$APP"
fi
echo "built $APP"
