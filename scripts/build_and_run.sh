#!/bin/bash

# Sidepiece Build & Run Script
# This script builds the project to a stable path and assists with permissions.

set -e

APP_NAME="Sidepiece"
BUNDLE_ID="com.sidepiece.app"
STABLE_BUILD_DIR="$(pwd)/build/Debug"
APP_PATH="$STABLE_BUILD_DIR/$APP_NAME.app"

echo "🚀 Starting Build Process..."

# 1. Generate Xcode Project
if command -v xcodegen >/dev/null 2>&1; then
    echo "📦 Generating project with XcodeGen..."
    xcodegen generate
else
    echo "⚠️  XcodeGen not found. Skipping generation..."
fi

# 2. Handle Running Instances
echo "Stopping any existing instances..."
killall "$APP_NAME" 2>/dev/null || true

# 3. Build to Stable Path
echo "🛠 Building Sidepiece..."
mkdir -p "$STABLE_BUILD_DIR"

# Note: We build directly with xcodebuild. Removing xcbeautify for reliability.
xcodebuild -project "$APP_NAME.xcodeproj" \
           -scheme "$APP_NAME" \
           -configuration Debug \
           -derivedDataPath ./DerivedData \
           CONFIGURATION_BUILD_DIR="$STABLE_BUILD_DIR" \
           clean build

# 4. Handle Permissions (Fixes the "Ghost Permission" bug)
# Note: Automatic grant requires Full Disk Access and is usually blocked by SIP.
# Resetting ensures a fresh, working prompt/toggle.
# echo "🧹 Resetting Accessibility permissions for $BUNDLE_ID..."
# tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true

# 5. Launch
echo "🎈 Launching $APP_NAME..."
open "$APP_PATH"

# 6. Assist User
echo "----------------------------------------------------------------"
echo "✅ BUILD COMPLETE"
echo "----------------------------------------------------------------"
echo "Sidepiece is now running."
echo "If the HUD doesn't respond to keys, please ensure it's enabled in:"
echo "System Settings > Privacy & Security > Accessibility"
echo "----------------------------------------------------------------"

# Open settings just in case if not granted
# (We check manually in the app now)
