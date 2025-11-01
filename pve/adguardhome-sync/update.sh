#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of bakito/adguardhome-sync and compares it to
# the local version. If out of date, it stops the service, downloads the
# latest version, and restarts the service.
#
# @author Nicholas Wilde, 0xb299a622
# @date 01 Nov 2025
# @version 1.0.0
#
################################################################################

# Options
set -e
set -o pipefail

# These are constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly RESET=$(tput sgr0)
SERVICE_NAME="adguardhome-sync"
INSTALL_DIR="/opt/adguardhome-sync"
GITHUB_REPO="bakito/adguardhome-sync"

source "$(dirname "$0")/.env"

# Logging function
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  case "$type" in
    INFO)
      color="$BLUE";;
    WARN)
      color="$YELLOW";;
    ERRO)
      color="$RED";;
  esac

  echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
}

# Checks if a command exists.
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! command_exists curl || ! command_exists jq; then
    log "ERRO" "Required dependencies (curl, jq) are not installed." >&2
    exit 1
  fi
}

function get_latest_version() {
  log "INFO" "Getting latest version of ${SERVICE_NAME} from GitHub..."
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  local json_response
  if [ -n "${GITHUB_TOKEN}" ]; then
    local curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  json_response=$(curl -s "${curl_args[@]}" "${api_url}")
  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ${SERVICE_NAME} from GitHub API."
    echo "${json_response}"
    return 1
  fi

  local tag_name
  tag_name=$(echo "${json_response}" | jq -r '.tag_name')
  LATEST_VERSION=${tag_name#v}
  log "INFO" "Latest ${SERVICE_NAME} version: ${LATEST_VERSION}"
}

function get_current_version() {
  if [ ! -x "${INSTALL_DIR}/${SERVICE_NAME}" ]; then
    log "WARN" "${SERVICE_NAME} is not installed or not executable at ${INSTALL_DIR}/${SERVICE_NAME}."
    CURRENT_VERSION="0"
    return
  fi
  log "INFO" "Getting current version of ${SERVICE_NAME}..."
  # The version output is like: "version: v0.5.0"
  local current_version_full
  current_version_full=$("${INSTALL_DIR}/${SERVICE_NAME}" --version 2>&1)
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

  log "INFO" "New version available for ${SERVICE_NAME}: ${LATEST_VERSION}"
  log "INFO" "Stopping ${SERVICE_NAME} service..."
  systemctl stop "${SERVICE_NAME}.service"

  log "INFO" "Downloading and installing update..."
  curl -fsSL "${INSTALLER_URL}" | bash

  log "INFO" "Restarting ${SERVICE_NAME} service..."
  systemctl restart "${SERVICE_NAME}.service"

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
