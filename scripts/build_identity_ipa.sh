#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild -project GestaltX.xcodeproj -scheme GestaltX -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/Payload"
ditto build/Build/Products/Release-iphoneos/GestaltX.app "$stage/Payload/GestaltX.app"
app="$stage/Payload/GestaltX.app"
# These signatures declare requests for the provisioner; they are not installable certificates.
codesign --force --sign - --entitlements ShareExtension/GestaltXShare.entitlements \
  --generate-entitlement-der "$app/PlugIns/GestaltXShare.appex"
codesign --force --sign - --entitlements GestaltX/GestaltX.entitlements \
  --generate-entitlement-der "$app"
codesign --verify --deep --strict "$app"
output="$PWD/build/GestaltX_Lab_1.0.4_AppGroupReady.ipa"
ditto -c -k --sequesterRsrc --keepParent "$stage/Payload" "$output"
echo "Prepared $output (requires provisioning before installation)"
