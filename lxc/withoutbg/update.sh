#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of withoutbg}} and compares it to
# the local version. If out of date, it stops the service, downloads the
# latest version, and restarts the service.
#
# @author Nicholas Wilde, 0xb299a622
# @date 22 Dec 2025
# @version 0.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# These are constants
# Catppuccin Mocha Colors
readonly BLUE="\033[38;2;137;180;250m"
readonly RED="\033[38;2;243;139;168m"
readonly YELLOW="\033[38;2;249;226;175m"
readonly PURPLE="\033[38;2;203;166;247m"
readonly RESET="\033[0m"
SERVICE_NAME="withoutbg"
INSTALL_DIR="/opt/withoutbg"
GITHUB_REPO="withoutbg/withoutbg"
BACKEND_DIR="${INSTALL_DIR}/apps/web/backend"
FRONTEND_DIR="${INSTALL_DIR}/apps/web/frontend"
DEBUG="true"

# Source .env file if it exists
if [ -f "$(dirname "$0")/.env" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/.env"
fi

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

  if [[ -n "${message}" ]]; then
    echo -e "${color}${type}${RESET}[${timestamp}] ${message}"
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[${timestamp}] ${line}"
    done
  fi
}

# Checks if a command exists.
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! command_exists curl || ! command_exists jq || ! command_exists uv || ! command_exists npx; then
    log "ERRO" "Required dependencies (curl, jq, uv, npx) are not installed." >&2
    exit 1
  fi
}

function get_latest_version() {
  log "INFO" "Getting latest version of ${SERVICE_NAME} from GitHub..."
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  local json_response
  local curl_args=()
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  json_response=$(curl -s "${curl_args[@]}" "${api_url}")
  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ${SERVICE_NAME} from GitHub API."
    echo "${json_response}" | while IFS= read -r line; do log "ERRO" "$line"; done
    return 1
  fi

  local tag_name
  tag_name=$(echo "${json_response}" | jq -r '.tag_name')
  LATEST_VERSION=${tag_name#v}
  log "INFO" "Latest ${SERVICE_NAME} version: ${LATEST_VERSION}"
}

function get_current_version() {
  if [ ! -d "${INSTALL_DIR}" ]; then
    log "WARN" "${SERVICE_NAME} is not installed or not executable at ${INSTALL_DIR}/${SERVICE_NAME}."
    CURRENT_VERSION="0"
    return
  fi
  log "INFO" "Getting current version of ${SERVICE_NAME}..."
  local current_version_full
  # Note: Adjust version command and parsing if needed for the specific app
  if [ -f "${FRONTEND_DIR}/package.json" ]; then
    current_version_full=$(jq -r '.version' "${FRONTEND_DIR}/package.json")
  else
    current_version_full="0.0.0"
  fi
  CURRENT_VERSION=$(echo "${current_version_full}" | awk '{print $NF}' | sed 's/v//')
  log "INFO" "Current ${SERVICE_NAME} version: ${CURRENT_VERSION}"
}

function stop_services(){
  if systemctl status "${SERVICE_NAME}-frontend.service" &> /dev/null; then
    log "INFO" "Stopping ${SERVICE_NAME}-frontend.service..."
    systemctl restart "${SERVICE_NAME}-frontend.service" 2>&1 | log "INFO"
  else
    log "INFO" "${SERVICE_NAME}-frontend not running"
  fi

  if systemctl status "${SERVICE_NAME}-backendend.service" &> /dev/null; then
    log "INFO" "Stopping ${SERVICE_NAME}-backend.service..."
    systemctl restart "${SERVICE_NAME}-backend.service" 2>&1 | log "INFO"
  else
    log "INFO" "${SERVICE_NAME}-backend not running"
  fi
}

function backup_and_remove(){  
  local basedir
  basedir=$(dirname "${}")
  if [ -f "${FRONTEND_DIR}/.env.local" ]; then
    log "INFO" "Backing up settings..."
    cp "${FRONTEND_DIR}/.env.local" "${basedir}/.env.local"
  fi

  log "INFO" "Removing application..."
  rm -rf "${INSTALL_DIR}"
}

function restart_services(){
  if systemctl status "${SERVICE_NAME}-backend.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME}-backend service..."
    systemctl restart "${SERVICE_NAME}-backend.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}-backend.service not found, skipping restart."
  fi

  if systemctl status "${SERVICE_NAME}-frontend.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME}-frontend service..."
    systemctl restart "${SERVICE_NAME}-frontend.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}-frontend.service not found, skipping restart."
  fi
}

function download_and_extract(){
  log "INFO" "Downloading and extracting update..."
}

function setup_app(){
  log "INFO" "Running setup..."
  setup_backend
  setup_frontend
}

function setup_backend(){
  cd "${BACKEND_DIR}"
  
  uv python install 3.12
  uv python pin 3.12
  uv sync
}

function setup_frontend(){
  cd "${FRONTEND_DIR}"
  npm install .
  npm run build
    
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting ${SERVICE_NAME} update script..."
  check_dependencies

  get_latest_version
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${SERVICE_NAME} is already up-to-date: ${CURRENT_VERSION}"
    log "INFO" "Script finished."
    exit 0
  fi

  log "INFO" "New version available for ${SERVICE_NAME}: ${LATEST_VERSION}"
  if systemctl status "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Stopping ${SERVICE_NAME} service..."
    systemctl stop "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping stop."
  fi

  stop_services
  backup_and_remove

  download_and_extract
  setup_app
  
  restart_services

  get_current_version
  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "Successfully updated ${SERVICE_NAME} to ${LATEST_VERSION}."
  else
    log "ERRO" "Failed to update ${SERVICE_NAME}. Still on ${CURRENT_VERSION}."
  fi

  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"
