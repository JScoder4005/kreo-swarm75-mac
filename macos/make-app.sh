#!/bin/sh
# Build SwarmGlow.app (universal: Apple Silicon + Intel) into macos/build/.
# Signs with the "Kreo Local Signing" keychain identity when present, so macOS keeps the
# Input Monitoring permission across rebuilds; falls back to ad hoc signing otherwise.
# Pass --zip to also make build/SwarmGlow-<version>.zip for a GitHub release.
set -e
cd "$(dirname "$0")"
VERSION=0.1.2
swift build -c release --product SwarmGlow --arch arm64 --arch x86_64
APP=build/SwarmGlow.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/apple/Products/Release/SwarmGlow "$APP/Contents/MacOS/SwarmGlow"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>SwarmGlow</string>
  <key>CFBundleDisplayName</key><string>SwarmGlow</string>
  <key>CFBundleIdentifier</key><string>com.jscoder4005.swarmglow</string>
  <key>CFBundleExecutable</key><string>SwarmGlow</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
  <key>NSHumanReadableCopyright</key><string>MIT License. Not affiliated with Kreo.</string>
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
if [ "$1" = "--zip" ]; then
  ZIP="build/SwarmGlow-$VERSION.zip"
  rm -f "$ZIP"
  ditto -c -k --keepParent "$APP" "$ZIP"
  shasum -a 256 "$ZIP"
fi
