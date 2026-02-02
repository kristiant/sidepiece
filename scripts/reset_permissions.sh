# Sidepiece Development Helper
# This script clears accessibility permissions for Sidepiece to fix "stale" permission issues during development.

BUNDLE_ID="com.sidepiece.app"

echo "🔄 Resetting Accessibility permissions for $BUNDLE_ID..."
tccutil reset Accessibility $BUNDLE_ID
tccutil reset Accessibility com.sidepiece.Sidepiece
tccutil reset Accessibility Sidepiece

# Kill the target if running so it can't hold any locks
pkill -x Sidepiece 2>/dev/null

echo "✅ Permissions reset."
echo "1. Rebuild the app in Xcode (Cmd+R)."
echo "2. When the permission prompt appears (or when you go to System Settings), grant it ONE LAST TIME."
echo "3. Because we now use a fixed build path (./build/Debug), macOS should remember it much better."
