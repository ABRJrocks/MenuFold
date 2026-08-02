#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
BUILD_ROOT="$PROJECT_ROOT/build"
APP_BUNDLE="$BUILD_ROOT/MenuFold.app"
SIGN_IDENTITY="${1:-Apple Development: Abdul Rafay (6ZJ47FNNCB)}"

"$PROJECT_ROOT/scripts/make-icon.sh" >/dev/null

cd "$PROJECT_ROOT"
swift build -c release --arch arm64
SWIFT_BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

ditto "$SWIFT_BIN_DIR/MenuFold" "$APP_BUNDLE/Contents/MacOS/MenuFold"
ditto "$PROJECT_ROOT/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
ditto "$PROJECT_ROOT/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

codesign --force --options runtime --timestamp=none --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

print "$APP_BUNDLE"
