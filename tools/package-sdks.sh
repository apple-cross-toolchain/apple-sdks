#!/bin/bash

set -euxo pipefail

if [[ -z "${DEVELOPER_DIR:-}" ]]; then
  DEVELOPER_DIR="$(xcode-select -p)"
fi

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_ROOT/.." && pwd)"
NEW_DEVELOPER_DIR="$PROJECT_ROOT/Xcode.app/Contents/Developer"
mkdir -p "$NEW_DEVELOPER_DIR"

cp -a "$DEVELOPER_DIR/../Info.plist" "$NEW_DEVELOPER_DIR/.."
cp -a "$DEVELOPER_DIR/../version.plist" "$NEW_DEVELOPER_DIR/.."

## Copy SDKs
for sdk in MacOSX iPhoneOS iPhoneSimulator WatchOS WatchSimulator AppleTVOS AppleTVSimulator; do
  # xcrun relies on this Info.plist to find and invoke tools
  rsync -a --relative "$DEVELOPER_DIR/./Platforms/$sdk.platform/Info.plist" "$NEW_DEVELOPER_DIR"

  rsync -a --relative --exclude "$sdk.sdk/usr/share" "$DEVELOPER_DIR/./Platforms/$sdk.platform/Developer/SDKs/" "$NEW_DEVELOPER_DIR"

  if [[ -d "$DEVELOPER_DIR/Platforms/$sdk.platform/usr/lib" ]]; then
    rsync -a --relative "$DEVELOPER_DIR/./Platforms/$sdk.platform/usr/lib/" "$NEW_DEVELOPER_DIR"
  fi

  if [[ -d "$DEVELOPER_DIR/Platforms/$sdk.platform/Developer/usr/lib" ]]; then
    rsync -a --relative "$DEVELOPER_DIR/./Platforms/$sdk.platform/Developer/usr/lib/" "$NEW_DEVELOPER_DIR"
  fi

  if [[ -d "$DEVELOPER_DIR/Platforms/$sdk.platform/Developer/Library/Frameworks" ]]; then
    rsync -a --relative "$DEVELOPER_DIR/./Platforms/$sdk.platform/Developer/Library/Frameworks/" "$NEW_DEVELOPER_DIR"
  fi
done

# Copy toolchain libraries
rsync -a --relative "$DEVELOPER_DIR/./Toolchains/XcodeDefault.xctoolchain/ToolchainInfo.plist" "$NEW_DEVELOPER_DIR"
rsync -a --relative "$DEVELOPER_DIR/./Toolchains/XcodeDefault.xctoolchain/usr/include/" "$NEW_DEVELOPER_DIR"
rsync -a --relative "$DEVELOPER_DIR/./Toolchains/XcodeDefault.xctoolchain/usr/lib/arc/" "$NEW_DEVELOPER_DIR"
rsync -a --relative "$DEVELOPER_DIR/./Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/" "$NEW_DEVELOPER_DIR"
rsync -a --relative "$DEVELOPER_DIR/./Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/" "$NEW_DEVELOPER_DIR"
if [[ -d "$DEVELOPER_DIR/./Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.0" ]]; then
  rsync -a --relative "$DEVELOPER_DIR/./Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.0/" "$NEW_DEVELOPER_DIR"
fi

XCODE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_ROOT/Xcode.app/Contents/version.plist")"

tar -Jcf "apple-sdks-xcode-$XCODE_VERSION.tar.xz" Xcode.app
zip -qr "apple-sdks-xcode-$XCODE_VERSION.zip" Xcode.app
zstd --fast=7 -r Xcode.app -o "apple-sdks-xcode-$XCODE_VERSION.zstd"
