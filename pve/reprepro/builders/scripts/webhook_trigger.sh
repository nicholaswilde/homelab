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
    "cookcli") REPO="cooklang/cookcli" ;;
    "cooklang-import") REPO="cooklang/cooklang-import" ;;
    "procs")  REPO="dalance/procs" ;;
    "tapmap") REPO="olalie/tapmap" ;;
    *)
        echo "Error: Unknown app '$APP'."
        exit 1
        ;;
esac

function send_notification(){
  if [[ "${ENABLE_NOTIFICATIONS}" == "false" ]]; then
    return 0
  fi
  if [[ -z "${MAILRISE_URL}" || -z "${MAILRISE_FROM}" || -z "${MAILRISE_RCPT}" ]]; then
    echo "Warning: Notification variables not set. Skipping notification."
    return 1
  fi

  local EMAIL_SUBJECT="Homelab - Update ${APP} Summary"
  local EMAIL_BODY="${APP} version ${NEW_TAG} build and upload completed successfully."

  echo "INFO: Sending email notification..."
  curl -s \
    --url "${MAILRISE_URL}" \
    --mail-from "${MAILRISE_FROM}" \
    --mail-rcpt "${MAILRISE_RCPT}" \
    --upload-file - <<EOF
From: ${APP} Builder <${MAILRISE_FROM}>
To: Nicholas Wilde <${MAILRISE_RCPT}>
Subject: ${EMAIL_SUBJECT}

${EMAIL_BODY}
EOF
  echo "INFO: Email notification sent."
}

# 2. Check if a new version is actually needed
# This uses the check_version.sh script we created earlier.
if NEW_TAG=$(./scripts/check_version.sh "$APP" "$REPO" 2>/dev/null); then
    echo "🚀 Triggering build for $APP version $NEW_TAG"
    # Execute the build task. We pass VERSION as an env var to ensure it's inherited by included Taskfiles.
    VERSION="$NEW_TAG" task "$APP:build"
    
    # Upload the resulting .deb files
    if [ -f "./upload.sh" ]; then
        ./upload.sh
        send_notification
    else
        echo "Warning: upload.sh not found."
    fi
    # 3. (Optional) Selective cleanup
    # We no longer run 'task clean-all' here to preserve compiler caches.
else
    echo "✅ $APP is already up to date, skipping."
fi
