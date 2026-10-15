#!/bin/bash
# Builds to the fixed ./build/Debug path so macOS keeps the Accessibility grant, then launches.
set -euo pipefail

xcodegen generate
killall Sidepiece 2>/dev/null || true
xcodebuild -project Sidepiece.xcodeproj -scheme Sidepiece -configuration Debug -derivedDataPath DerivedData build
open build/Debug/Sidepiece.app

echo "If keys do nothing, enable Sidepiece in System Settings > Privacy & Security > Accessibility."
