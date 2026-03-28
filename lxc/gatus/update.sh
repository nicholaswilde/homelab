#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of gatus and compares it to
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
SERVICE_NAME="gatus"
INSTALL_DIR="/opt/gatus"
GITHUB_REPO="TwiN/gatus"
DEBUG="false"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

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
  if ! command_exists curl || ! command_exists jq || ! command_exists go; then
    log "ERRO" "Required dependencies (curl, jq, go) are not installed." >&2
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
  log "DEBU" "${json_response}"
  local tag_name
  tag_name=$(echo "${json_response}" | jq -r '.tag_name')
  LATEST_VERSION=${tag_name#v}
  log "INFO" "Latest ${SERVICE_NAME} version: ${LATEST_VERSION}"
  TARBALL_URL=$(echo "${json_response}" | grep '"tarball_url":' | sed -E 's/.*"tarball_url": "(.*)",/\1/')
  export TARBALL_URL
}

function get_current_version() {
  if [ ! -f "/opt/${SERVICE_NAME}_version.txt" ]; then
    log "WARN" "${SERVICE_NAME} is not installed or not executable at ${INSTALL_DIR}/${SERVICE_NAME}."
    CURRENT_VERSION="0"
    return
  fi
  log "INFO" "Getting current version of ${SERVICE_NAME}..."
  local current_version_full
  # Note: Adjust version command and parsing if needed for the specific app
  current_version_full=$(cat "/opt/${SERVICE_NAME}_version.txt")
  CURRENT_VERSION=$(echo "${current_version_full}" | awk '{print $NF}' | sed 's/v//')
  log "INFO" "Current ${SERVICE_NAME} version: ${CURRENT_VERSION}"
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

  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  log "INFO" "New version available for ${SERVICE_NAME}: ${LATEST_VERSION}"
  if systemctl list-unit-files "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Stopping ${SERVICE_NAME} service..."
    systemctl stop "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME} is not running, skipping stop."
  fi

  if [ -f /opt/gatus/config/config.yaml ]; then
    log "INFO" "Removing previous config"
    unlink "${CONFIG_DIR}/config.yaml"
  fi

  log "INFO" "Removing previous version..."
  rm -rf "${INSTALL_DIR}/*"

  log "INFO" "Downloading update..."
  curl -fsSL "${TARBALL_URL}" -o "${tmp_dir}/gatus.tar.gz"

  log "INFO" "Extracting to ${INSTALL_DIR}..." 
  tar -xf "${tmp_dir}/gatus.tar.gz" -C "${INSTALL_DIR}/" --strip-components=1

  log "INFO" "Building ${SERVICE_NAME}..."
  cd "${INSTALL_DIR}"
  go mod tidy
  CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
  setcap CAP_NET_RAW+ep gatus
  
  log "INFO" "Making link to config"
  ln -sf "${SCRIPT_DIR}/config.yaml" "${CONFIG_DIR}/config.yaml"
  echo "${LATEST_VERSION}" > "/opt/${SERVICE_NAME}_version.txt"
  
  if systemctl list-unit-files "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME} service..."
    systemctl restart "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping restart."
  fi

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
