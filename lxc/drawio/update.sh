#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of Draw.io and compares it to
# the local version. If out of date, it stops the service, downloads the
# latest version, and restarts the service.
#
# @author Nicholas Wilde, 0xb299a622
# @date 05 Jan 2026
# @version 0.1.1
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
SERVICE_NAME="tomcat10"
INSTALL_DIR="/var/lib/tomcat10/webapps"
GITHUB_REPO="jgraph/drawio"
DEBUG="false"

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
  if ! command_exists curl || ! command_exists jq || ! command_exists java; then
    log "ERRO" "Required dependencies (curl, jq, java) are not installed." >&2
    exit 1
  fi
}

function get_latest_version() {
  log "INFO" "Getting latest version of ${GITHUB_REPO} from GitHub..."
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  local json_response
  local curl_args=()
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  json_response=$(curl -s "${curl_args[@]}" "${api_url}")
  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ${SERVICE_NAME} from GitHub API."
    return 1
  fi

  local tag_name
  tag_name=$(echo "${json_response}" | jq -r '.tag_name')
  LATEST_VERSION=${tag_name#v}
  log "INFO" "Latest ${GITHUB_REPO} version: ${LATEST_VERSION}"
}

function get_current_version() {
  if [ -f "${INSTALL_DIR}/draw.version" ]; then
      CURRENT_VERSION=$(cat "${INSTALL_DIR}/draw.version")
  else
      CURRENT_VERSION="0"
  fi
  log "INFO" "Current ${GITHUB_REPO} version: ${CURRENT_VERSION}"
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting ${SERVICE_NAME} update script..."
  check_dependencies

  get_latest_version
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${GITHUB_REPO} is already up-to-date: ${CURRENT_VERSION}"
    log "INFO" "Script finished."
    exit 0
  fi

  log "INFO" "New version available for ${GITHUB_REPO}: ${LATEST_VERSION}"
  if systemctl status "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Stopping ${SERVICE_NAME} service..."
    systemctl stop "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping stop."
  fi

  log "INFO" "Downloading and installing update..."
  
  # Remove default ROOT application if it exists
  if [ -d "${INSTALL_DIR}/ROOT" ]; then
      log "INFO" "Removing default ROOT application..."
      rm -rf "${INSTALL_DIR}/ROOT"
  fi

  # Backup old ROOT.war?
  if [ -f "${INSTALL_DIR}/ROOT.war" ]; then
      mv "${INSTALL_DIR}/ROOT.war" "${INSTALL_DIR}/ROOT.war.bak"
  fi
  
  DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${LATEST_VERSION}/draw.war"
  
  if ! curl -L -o "${INSTALL_DIR}/ROOT.war" "${DOWNLOAD_URL}"; then
     log "ERRO" "Failed to download ${DOWNLOAD_URL}"
     exit 1
  fi
  
  # Update version file
  echo "${LATEST_VERSION}" > "${INSTALL_DIR}/draw.version"

  if systemctl status "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME} service..."
    systemctl restart "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping restart."
    # Try start
    systemctl start "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  fi

  get_current_version
  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "Successfully updated ${GITHUB_REPO} to ${LATEST_VERSION}."
  else
    log "ERRO" "Failed to update ${GITHUB_REPO}. Still on ${CURRENT_VERSION}."
  fi

  # Log Access URL
  local ip_address
  ip_address=$(hostname -I | awk '{print $1}')
  log "INFO" "Access Draw.io at http://${ip_address}:8080/"

  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"