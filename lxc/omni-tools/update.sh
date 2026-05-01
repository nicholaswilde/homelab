#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of omni-tools and compares it to
# the local version. If out of date, it stops the service, downloads the
# latest version, and restarts the service.
#
# @author Nicholas Wilde, 0xb299a622
# @date 29 Apr 2026
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
SERVICE_NAME="nginx"
APP_NAME="omni-tools"
INSTALL_DIR="/opt/omni-tools"
GITHUB_REPO="iib0011/omni-tools"
DEBUG="false"
readonly VERSION_FILENAME="omni-tools_version.txt"

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
  if ! command_exists curl || ! command_exists jq || ! command_exists npx; then
    log "ERRO" "Required dependencies (curl, jq, uv, npx) are not installed." >&2
    exit 1
  fi
}

function get_latest_version() {
  log "INFO" "Getting latest version of ${APP_NAME} from GitHub..."
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  local curl_args=()
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  export json_response=$(curl -s "${curl_args[@]}" "${api_url}")
  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ${APP_NAME} from GitHub API."
    echo "${json_response}" | while IFS= read -r line; do log "ERRO" "$line"; done
    return 1
  fi

  local tag_name
  tag_name=$(echo "${json_response}" | jq -r '.tag_name')
  LATEST_VERSION=${tag_name#v}
  log "INFO" "Latest ${APP_NAME} version: ${LATEST_VERSION}"
}

function get_current_version() {
  if [ ! -d "${INSTALL_DIR}" ]; then
    log "WARN" "${APP_NAME} is not installed at ${INSTALL_DIR}."
    CURRENT_VERSION="0"
    return
  fi
  export basedir=$(dirname "${INSTALL_DIR}")
  log "DEBU" "basedir: ${basedir}"
    
  log "INFO" "Getting current version of ${APP_NAME}..."
  local current_version_full
  # Note: Adjust version command and parsing if needed for the specific app
  if [ -f "${basedir}/${VERSION_FILENAME}" ]; then
    current_version_full=$(cat "${basedir}/${VERSION_FILENAME}")
  else
    current_version_full="0.0.0"
  fi
  log "DEBU" "current_version_full: ${current_version_full}"
  CURRENT_VERSION=$(echo "${current_version_full}" | sed 's/v//')
  log "INFO" "Current ${APP_NAME} version: ${CURRENT_VERSION}"
}

function stop_services(){
  if systemctl status "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Stopping ${SERVICE_NAME}.service..."
    systemctl restart "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping stop."
  fi
}

function backup_and_remove(){  
  export basedir=$(dirname "${INSTALL_DIR}")
  log "DEBU" "basedir: ${basedir}"

  log "INFO" "Removing application..."
  if ! rm -rf "${INSTALL_DIR}"; then
    log "ERRO" "There was an error removing the application"
    exit 1
  fi
}

function restart_services(){
  if systemctl status "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME} service..."
    systemctl restart "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping restart."
  fi
}

function download_and_extract(){
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "${TEMP_DIR}"' EXIT
  log "DEBU" "TEMP_DIR: ${TEMP_DIR}"
  cd ${TEMP_DIR}
  
  tarball_url=$(echo "${json_response}" | jq -r '.tarball_url')
  log "DEBU" "tarball_url: ${tarball_url}"
  log "INFO" "Downloading update..."
  if ! curl -LsSf "${tarball_url}" -o "${TEMP_DIR}/omni-tools.tar.gz"; then
    log "ERRO" "There was an error downloading the update"
    exit 1
  fi

  mkdir -p "${INSTALL_DIR}"
  log "INFO" "Extracting update..."
  if ! tar -xzf "${TEMP_DIR}/omni-tools.tar.gz" -C "${INSTALL_DIR}" --strip-components=1; then
    log "ERRO" "There was an error extracting the update"
    exit 1
  fi
}

function setup_app(){
  setup_frontend
}

function setup_frontend(){
  log "DEBU" "INSTALL_DIR: ${INSTALL_DIR}"
  cd "${INSTALL_DIR}"
  log "INFO" "Setting up frontend..."
  if npm install .  &> /dev/null; then
    log "INFO" "npm install successful"
  else
    log "ERRO" "There was an error installing npm"
    exit 1
  fi
  
  if npm run build  &> /dev/null; then
    log "INFO" "npm run build successful"
  else
    log "ERRO" "There was an error building npm"
    exit 1
  fi

  log "INFO" "Copying dist files"
  if ! cp -r "${INSTALL_DIR}/dist/"* /var/www/html/; then
    log "ERRO" "There was an error copying the dist files"
    exit 1
  fi
}

function check_version(){
  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date: ${CURRENT_VERSION}"
    log "INFO" "Script finished."
    exit 0
  else
    log "INFO" "New version available for ${APP_NAME}: ${LATEST_VERSION}"
  fi
}

function verify_version(){
  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "Successfully updated ${APP_NAME} to ${LATEST_VERSION}."
  else
    log "ERRO" "Failed to update ${APP_NAME}. Still on ${CURRENT_VERSION}."
  fi
}

function write_version(){
  printf "%s" "${LATEST_VERSION}" > "${basedir}/${VERSION_FILENAME}"
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting ${APP_NAME} update script..."
  check_dependencies

  get_latest_version
  get_current_version
  check_version
  stop_services
  backup_and_remove

  download_and_extract
  setup_app
  write_version
  restart_services
  
  get_current_version
  verify_version
  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"
