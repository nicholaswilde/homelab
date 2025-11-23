#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of go-gitea/gitea and compares it to
# the local version. If out of date, it downloads the latest version.
#
# @author Nicholas Wilde, 0xb299a622
# @date 09 Nov 2025
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
readonly PURPLE=$(tput setaf 5)
readonly RESET=$(tput sgr0)
SERVICE_NAME="gitea"
BINARY_NAME="gitea"
INSTALL_DIR="/usr/local/bin"
GITHUB_REPO="go-gitea/gitea"
DEBUG="false"

# Source .env file if it exists
if [ -f "$(dirname "$0")/.env" ]; then
  source "$(dirname "$0")/.env"
fi

# Logging function
function log() {
  local type="$1"
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
  if [[ -t 0 ]]; then
    local message="$2"
    echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${line}"
    done
  fi
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
  log "INFO" "Getting latest version of ${BINARY_NAME} from GitHub..."
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases"
  if [ -n "${GITHUB_TOKEN}" ]; then
    local curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  local all_releases_json
  all_releases_json=$(curl -s "${curl_args[@]}" "${api_url}")

  LATEST_RELEASE_JSON=$(echo "${all_releases_json}" | jq '[.[] | select(.prerelease == false)] | .[0]')

  if [ -z "${LATEST_RELEASE_JSON}" ] || [ "${LATEST_RELEASE_JSON}" == "null" ]; then
    log "ERRO" "Failed to find a matching stable release for ${BINARY_NAME} from GitHub API."
    return 1
  fi

  local tag_name
  tag_name=$(echo "${LATEST_RELEASE_JSON}" | jq -r '.tag_name')
  if [ -z "${tag_name}" ] || [ "${tag_name}" == "null" ]; then
    log "ERRO" "Could not extract tag_name from release JSON."
    return 1
  fi
  LATEST_VERSION=${tag_name#v}
  log "INFO" "Latest ${BINARY_NAME} version: ${LATEST_VERSION}"
}

function get_current_version() {
  if ! command_exists "${BINARY_NAME}"; then
    log "WARN" "${BINARY_NAME} is not installed or not in PATH."
    CURRENT_VERSION="0"
    return
  fi
  log "INFO" "Getting current version of ${BINARY_NAME}..."
  local version_output
  version_output=$("${BINARY_NAME}" --version 2>&1)
  CURRENT_VERSION=$(echo "${version_output}" | awk '{print $3}')
  log "INFO" "Current ${BINARY_NAME} version: ${CURRENT_VERSION}"
}

function download_and_install() {
  local temp_file
  temp_file=$(mktemp)

  if systemctl status "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Stopping ${SERVICE_NAME} service..."
    systemctl stop "${SERVICE_NAME}.service"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping stop."
  fi

  local installer_url="${INSTALLER_URL}"
  local fallback_repo="${GITHUB_REPO}"
  if [[ "${installer_url}" == *! ]]; then
    fallback_repo="${GITHUB_REPO}!"
  fi
  log "INFO" "Downloading and installing update..."
  if ! ({ curl -fsSL "${installer_url}" | bash;} 2>&1 | log "INFO"); then
    log "WARN" "Failed to download from ${installer_url}. Trying fallback installer..."
    if ! ( { curl -fsSL "https://i.jpillora.com/${fallback_repo}" | bash; } | log "INFO"); then
      log "ERRO" "Failed to download from fallback URL. Aborting update."
      exit 1
    fi
  fi
  
  if systemctl status "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME} service..."
    systemctl restart "${SERVICE_NAME}.service"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping restart."
  fi
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting ${BINARY_NAME} update script..."
  check_dependencies

  get_latest_version
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${BINARY_NAME} is already up-to-date: ${CURRENT_VERSION}"
    log "INFO" "Script finished."
    exit 0
  fi

  log "INFO" "New version available for ${BINARY_NAME}: ${LATEST_VERSION}"

  download_and_install

  get_current_version
  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "Successfully updated ${BINARY_NAME} to ${LATEST_VERSION}."
  else
    log "ERRO" "Failed to update ${BINARY_NAME}. Still on ${CURRENT_VERSION}."
  fi

  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"
