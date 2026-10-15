#!/bin/bash
# Clears stale Accessibility grants. Rebuild and grant again afterwards.
set -u

pkill -x Sidepiece 2>/dev/null
tccutil reset Accessibility com.sidepiece.app
