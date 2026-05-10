#!/usr/bin/env bash
################################################################################
#
# Script Name: webhook_trigger.sh
# ----------------
# Triggered by a webhook call from changedetection.io to build a specific app.
#
# @author Nicholas Wilde, 0xb299a622
# @date 09 May 2026
# @version 1.0.0
#
################################################################################

APP=$1
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
BUILDERS_DIR=$(dirname "$SCRIPT_DIR")
PARENT_DIR=$(dirname "$BUILDERS_DIR")

# Load Configuration
ENV_FILE="${PARENT_DIR}/.env"
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
fi

if [ -z "$APP" ]; then
    echo "Error: No app name provided."
    exit 1
fi

cd "$BUILDERS_DIR" || exit 1

# 1. Map incoming 'app' to the correct repository
case "$APP" in
    "restic") REPO="restic/restic" ;;
    "sops")   REPO="getsops/sops" ;;
    "bat")    REPO="sharkdp/bat" ;;
    "fd")     REPO="sharkdp/fd" ;;
    "eget")   REPO="zyedidia/eget" ;;
    "ubi")    REPO="houseabsolute/ubi" ;;
    "fresh")  REPO="sinelaw/fresh" ;;
    "yazi")   REPO="sxyazi/yazi" ;;
    *)
        echo "Error: Unknown app '$APP'."
        exit 1
        ;;
esac

# 2. Check if a new version is actually needed
# This uses the check_version.sh script we created earlier.
if NEW_TAG=$(./scripts/check_version.sh "$APP" "$REPO" 2>/dev/null); then
    echo "🚀 Triggering build for $APP version $NEW_TAG"
    # Execute the build task. We pass VERSION as an env var to ensure it's inherited by included Taskfiles.
    VERSION="$NEW_TAG" task "$APP:build"
    
    # Upload the resulting .deb files
    if [ -f "./upload.sh" ]; then
        ./upload.sh
    else
        echo "Warning: upload.sh not found."
    fi
    # 3. (Optional) Selective cleanup
    # We no longer run 'task clean-all' here to preserve compiler caches.
else
    echo "✅ $APP is already up to date ($NEW_TAG), skipping."
fi
