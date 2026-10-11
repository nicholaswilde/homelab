#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of Homebox and updates it via the upstream
# community script updater, verifies systemd service, and checks HTTP endpoint.
#
# @author Nicholas Wilde, 0xb299a622
# @date 10 Oct 2026
# @version 0.2.0
#
################################################################################

# Options
set -o pipefail
export TERM="${TERM:-xterm-25color}"

# Headless terminal compatibility for community updater scripts
clear() {
  return 0
}
export -f clear

# Constants
SERVICE_NAME="homebox"
APP_NAME="homebox"
INSTALL_DIR="/opt/homebox"
DEBUG="false"
SERVICE_MODE="false"

# Default variables
UPDATE_SUCCESS="true"
UPDATE_MESSAGES=()

# Source .env file if it exists
if [ -f "$(dirname "$0")/.env" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/.env"
fi

# Logging function
function log() {
  local type="$1"
  local message="$2"
  local color=""
  local reset=""

  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi

  if [[ -t 1 ]] && [[ "${SERVICE_MODE}" == "false" ]]; then
    BLUE_COL="\033[38;2;137;180;250m"
    RED_COL="\033[38;2;243;139;168m"
    YELLOW_COL="\033[38;2;249;226;175m"
    PURPLE_COL="\033[38;2;203;166;247m"
    RESET_COL="\033[0m"

    case "$type" in
      INFO) color="$BLUE_COL";;
      WARN) color="$YELLOW_COL";;
      ERRO) color="$RED_COL";;
      DEBU) color="$PURPLE_COL";;
    esac
    reset="$RESET_COL"
  fi

  local timestamp
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')

  if [[ -n "${message}" ]]; then
    echo -e "${color}${type}${reset}[${timestamp}] ${message}"
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${reset}[${timestamp}] ${line}"
    done
  fi

  # LogWard Integration
  if [[ -n "${LOGWARD_API_KEY}" ]]; then
    local LOGWARD_API_URL="${LOGWARD_API_URL:-https://logward.l.nicholaswilde.io/api/v1/ingest/single}"
    local LOGWARD_SERVICE_NAME="${LOGWARD_SERVICE_NAME:-$(basename "$0")}"
    local json_payload
    json_payload=$(cat <<EOF
{
  "service": "${LOGWARD_SERVICE_NAME}",
  "level": "${type}",
  "message": "${message:-$(cat)}",
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF
)
    curl -s -X POST "${LOGWARD_API_URL}" \
      -H "X-API-Key: ${LOGWARD_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "${json_payload}" >/dev/null 2>&1 &
  fi
}

function update_script() {
  if [ ! -d "${INSTALL_DIR}" ]; then
    log "ERRO" "Installation directory ${INSTALL_DIR} does not exist."
    UPDATE_SUCCESS="false"
    return 1
  fi

  log "INFO" "Starting ${APP_NAME} update..."
  if [ -x /usr/bin/update ]; then
    log "INFO" "Executing /usr/bin/update..."
    if /usr/bin/update; then
      log "INFO" "Community update completed."
    else
      log "ERRO" "/usr/bin/update failed."
      UPDATE_SUCCESS="false"
      return 1
    fi
  else
    log "INFO" "Fetching upstream community update script..."
    if bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/homebox.sh)"; then
      log "INFO" "Upstream community script finished successfully."
    else
      log "ERRO" "Upstream update script failed."
      UPDATE_SUCCESS="false"
      return 1
    fi
  fi

  log "INFO" "Verifying ${SERVICE_NAME}.service..."
  if systemctl is-active --quiet "${SERVICE_NAME}"; then
    log "INFO" "${SERVICE_NAME}.service is running."
  else
    log "WARN" "${SERVICE_NAME}.service is not active, attempting restart..."
    systemctl restart "${SERVICE_NAME}" || systemctl start "${SERVICE_NAME}"
  fi

  # Verify HTTP endpoint
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:7745/ || echo "000")
  if [[ "${http_code}" =~ ^(200|301|302)$ ]]; then
    log "INFO" "Verification succeeded (HTTP ${http_code})."
    UPDATE_MESSAGES+=("Successfully updated ${APP_NAME} (HTTP ${http_code}).")
  else
    log "WARN" "Service responded with HTTP ${http_code}."
    UPDATE_MESSAGES+=("Updated ${APP_NAME} but received HTTP ${http_code}.")
  fi
}

function main() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -s|--service) SERVICE_MODE="true"; shift;;
      -d|--debug) DEBUG="true"; shift;;
      *) shift;;
    esac
  done

  log "INFO" "Starting ${APP_NAME} update script..."
  update_script
  log "INFO" "Script finished."

  if [[ "${UPDATE_SUCCESS}" == "false" ]]; then
    exit 1
  fi
}

main "$@"