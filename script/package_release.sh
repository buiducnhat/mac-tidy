#!/usr/bin/env bash
set -euo pipefail

VERSION="${APP_VERSION:-0.1.1}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="MacTidy"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
RELEASE_DIR="$DIST_DIR/releases"
ARCHIVE_PATH="$RELEASE_DIR/$APP_NAME-v$VERSION-macos.zip"

cd "$ROOT_DIR"

APP_VERSION="$VERSION" script/build_and_run.sh --bundle

mkdir -p "$RELEASE_DIR"
rm -f "$ARCHIVE_PATH"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ARCHIVE_PATH"

echo "$ARCHIVE_PATH"
