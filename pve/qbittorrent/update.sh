#!/usr/bin/env bash
################################################################################
#
# update.sh
# ----------------
# Update qBittorrent
#
# @author Nicholas Wilde, 0xb299a622
# @date 28 Dec 2025
# @version 0.2.0
#
################################################################################

# Options
set -e
set -o pipefail

# Catppuccin Mocha Colors
BLUE="\033[38;2;137;180;250m"
readonly BLUE
RED="\033[38;2;243;139;168m"
readonly RED
YELLOW="\033[38;2;249;226;175m"
readonly YELLOW
PURPLE="\033[38;2;203;166;247m"
readonly PURPLE
RESET="\033[0m"
readonly RESET
DEBUG="false"

# Logging function
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi

  case "$type" in
    INFO)
      color="$BLUE";;
    WARN)
      color="$YELLOW";;
    ERRO)
      color="$RED";;
    DEBU)
      color="$PURPLE";;
    *)
      type="LOGS";;
  esac

  local timestamp
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')

  if [[ -t 0 ]]; then
    echo -e "${color}${type}${RESET}[${timestamp}] ${message}"
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[${timestamp}] ${line}"
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
  "message": "${message}",
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

# Checks if a command exists.
function commandExists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! commandExists curl || ! commandExists grep || ! commandExists awk ; then
    log "ERRO" "Required dependencies (curl, grep, awk) are not installed." >&2
    exit 1
  fi  
}

function get_arch() {
  local arch
  arch=$(uname -m)
  case "${arch}" in
    x86_64)
      echo "x86_64";;
    aarch64)
      echo "aarch64";;
    armv7l)
      echo "armv7";;
    armhf)
      echo "armhf";;
    *)
      log "ERRO" "Unsupported architecture: ${arch}"
      exit 1;; 
  esac
}

function update_script() {
  local APP="qbittorrent-nox"
  local BIN_PATH="${INSTALL_DIR}/${APP}"
  local VERSION_FILE="${INSTALL_DIR}/${APP}_version.txt"
  
  if [[ ! -x "${BIN_PATH}" ]]; then
    log "ERRO" "No executable qbittorrent-nox binary found at ${BIN_PATH}!"
    exit 1
  fi

  log "INFO" "Checking for updates..."
  
  local LATEST_RELEASE
  LATEST_RELEASE=$(curl -fsSL https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases/latest | grep "tag_name" | awk -F'"' '{print $4}')
  
  # The tag name is usually something like v4.6.3_4.0.3 or similar
  # We extract the release version for comparison
  local RELEASE="${LATEST_RELEASE}"
  
  local CURRENT_VERSION=""
  if [[ -f "${VERSION_FILE}" ]]; then
    CURRENT_VERSION=$(cat "${VERSION_FILE}")
  fi

  if [[ "${RELEASE}" != "${CURRENT_VERSION}" ]]; then
    log "INFO" "Updating ${APP} from ${CURRENT_VERSION:-unknown} to ${RELEASE}"
    
    local ARCH
    ARCH=$(get_arch)
    local DOWNLOAD_URL="https://github.com/userdocs/qbittorrent-nox-static/releases/download/${LATEST_RELEASE}/${ARCH}-qbittorrent-nox"
    
    log "INFO" "Stopping ${SERVICE_NAME}..."
    systemctl stop "${SERVICE_NAME}"
    
    log "INFO" "Downloading ${DOWNLOAD_URL}..."
    if ! curl -fsSL "${DOWNLOAD_URL}" -o "${BIN_PATH}"; then
      log "ERRO" "Failed to download update!"
      systemctl start "${SERVICE_NAME}"
      exit 1
    fi
    
    chmod +x "${BIN_PATH}"
    echo "${RELEASE}" > "${VERSION_FILE}"
    
    log "INFO" "Starting ${SERVICE_NAME}..."
    systemctl start "${SERVICE_NAME}"
    
    log "INFO" "Successfully updated to ${RELEASE}"
  else
    log "INFO" "No update required. ${APP} is already at ${RELEASE}"
  fi
}

function main() {
  # Load environment variables if .env exists
  if [[ -f ".env" ]]; then
    # shellcheck source=/dev/null
    source .env
  fi

  # Set defaults if not provided in .env
  INSTALL_DIR="${INSTALL_DIR:-/opt/qbittorrent}"
  SERVICE_NAME="${SERVICE_NAME:-qbittorrent-nox}"

  check_dependencies
  update_script
}

main "@"