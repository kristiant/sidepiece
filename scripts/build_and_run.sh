#!/bin/bash

# Sidepiece Build & Run Script
# This script builds the project to a stable path and assists with permissions.

set -e

APP_NAME="Sidepiece"
BUNDLE_ID="com.sidepiece.Sidepiece"
STABLE_BUILD_DIR="$(pwd)/build/Debug"
APP_PATH="$STABLE_BUILD_DIR/$APP_NAME.app"

echo "🚀 Starting Build Process..."

# 1. Generate Xcode Project
if command -v xcodegen >/dev/null 2>&1; then
    echo "📦 Generating project with XcodeGen..."
    xcodegen generate
else
    echo "⚠️  XcodeGen not found. Skipping generation (assuming .xcodeproj exists)..."
fi

# 2. Build to Stable Path
# Using a fixed path helps macOS keep track of Accessibility permissions.
echo "🛠 Building Sidepiece..."
mkdir -p "$STABLE_BUILD_DIR"

xcodebuild -project "$APP_NAME.xcodeproj" \
           -scheme "$APP_NAME" \
           -configuration Debug \
           -derivedDataPath ./DerivedData \
           CONFIGURATION_BUILD_DIR="$STABLE_BUILD_DIR" \
           clean build | xcbeautify || (echo "❌ Build failed. Check logs." && exit 1)

# 3. Handle Running Instances
echo "Stopping any existing instances..."
killall "$APP_NAME" 2>/dev/null || true

# 4. Reset Permissions (Fixes the "Ghost Permission" bug)
# If the app binary changes, macOS sometimes shows it as enabled when it's not.
# Resetting ensures a fresh, working prompt/toggle.
echo "🧹 Resetting Accessibility permissions for $BUNDLE_ID..."
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true
tccutil reset Accessibility "Sidepiece" 2>/dev/null || true

# 5. Launch
echo "🎈 Launching $APP_NAME..."
# Using 'open' ensures it starts in the background like a normal app
open "$APP_PATH"

# 6. Assist User
echo "----------------------------------------------------------------"
echo "✅ BUILD COMPLETE"
echo "----------------------------------------------------------------"
echo "Sidepiece is now running from: $APP_PATH"
echo ""
echo "CRITICAL: You must enable Accessibility for Sidepiece now."
echo "1. The Privacy settings should open automatically."
echo "2. Find 'Sidepiece' in the list and toggle it ON."
echo "3. If it's already there but OFF, toggle it ON."
echo "----------------------------------------------------------------"

# Open the settings page
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
