#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of gatus and compares it to
# the local version. If out of date, it stops the service, downloads the
# latest version, builds it, and restarts the service.
#
# @author Nicholas Wilde, 0xb299a622
# @date 10 Oct 2026
# @version 0.2.0
#
################################################################################

# Options
set -o pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/bin:${PATH}"

# Source GVM if available to ensure Go is in PATH (temporarily disable set -e as gvm internal functions return non-zero)
set +e
if [[ -s "/root/.gvm/scripts/gvm" ]]; then
  # shellcheck source=/dev/null
  source "/root/.gvm/scripts/gvm"
elif [[ -s "${HOME}/.gvm/scripts/gvm" ]]; then
  # shellcheck source=/dev/null
  source "${HOME}/.gvm/scripts/gvm"
fi
unset -f cd 2>/dev/null || true
set -e

# These are constants
# Catppuccin Mocha Colors
readonly BLUE="\033[38;2;137;180;250m"
readonly RED="\033[38;2;243;139;168m"
readonly YELLOW="\033[38;2;249;226;175m"
readonly PURPLE="\033[38;2;203;166;247m"
readonly RESET="\033[0m"
SERVICE_NAME="gatus"
APP_NAME="gatus"
INSTALL_DIR="/opt/gatus"
GITHUB_REPO="TwiN/gatus"
DEBUG="false"
SERVICE_MODE="false"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Source .env file if it exists
if [ -f "${SCRIPT_DIR}/.env" ]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/.env"
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
  TARBALL_URL=$(echo "${json_response}" | jq -r '.tarball_url')
  export TARBALL_URL
}

function get_current_version() {
  if [ ! -f "/opt/${SERVICE_NAME}_version.txt" ]; then
    log "WARN" "${SERVICE_NAME} is not installed or version file not found at /opt/${SERVICE_NAME}_version.txt."
    CURRENT_VERSION="0"
    return
  fi
  log "INFO" "Getting current version of ${SERVICE_NAME}..."
  local current_version_full
  current_version_full=$(cat "/opt/${SERVICE_NAME}_version.txt")
  CURRENT_VERSION=$(echo "${current_version_full}" | awk '{print $NF}' | sed 's/v//')
  log "INFO" "Current ${SERVICE_NAME} version: ${CURRENT_VERSION}"
}

# Main function to orchestrate the script execution
function main() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -s|--service) SERVICE_MODE="true"; shift;;
      -d|--debug) DEBUG="true"; shift;;
      *) shift;;
    esac
  done

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

  log "INFO" "Downloading update..."
  curl -fsSL "${TARBALL_URL}" -o "${tmp_dir}/gatus.tar.gz"

  log "INFO" "Extracting to ${INSTALL_DIR}..." 
  mkdir -p "${INSTALL_DIR}"
  tar -xf "${tmp_dir}/gatus.tar.gz" -C "${INSTALL_DIR}/" --strip-components=1

  log "INFO" "Building ${SERVICE_NAME}..."
  cd "${INSTALL_DIR}"
  go mod tidy
  CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
  if command_exists setcap; then
    setcap CAP_NET_RAW+ep gatus
  fi
  
  # Ensure config file exists in /opt/gatus/config/config.yaml
  mkdir -p "${INSTALL_DIR}/config"
  if [ -f "${SCRIPT_DIR}/config.yaml" ]; then
    log "INFO" "Linking config from ${SCRIPT_DIR}/config.yaml..."
    ln -sf "${SCRIPT_DIR}/config.yaml" "${INSTALL_DIR}/config/config.yaml"
  elif [ ! -f "${INSTALL_DIR}/config/config.yaml" ]; then
    log "WARN" "No config.yaml found in ${SCRIPT_DIR} or ${INSTALL_DIR}/config."
  fi

  echo "${LATEST_VERSION}" > "/opt/${SERVICE_NAME}_version.txt"
  
  if systemctl list-unit-files "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME} service..."
    systemctl restart "${SERVICE_NAME}.service" 2>&1 | log "INFO" || systemctl start "${SERVICE_NAME}.service" 2>&1 | log "INFO"
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
