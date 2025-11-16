#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of PatchMon and compares it to
# the local version. If out of date, it stops the service, downloads the
# latest version, and restarts the service.
#
# @author Nicholas Wilde, 0xb299a622
# @date 16 Nov 2025
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
APP_NAME="patchmon"
SERVICE_NAME="patchmon-server"
INSTALL_DIR="/opt"
GITHUB_REPO="PatchMon/PatchMon"
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

function usage() {
  cat <<EOF
Usage: $0 [options]

Checks for the latest release of PatchMon.

Options:
  -d, --debug         Enable debug mode, which prints more info.
  -h, --help          Display this help message.
EOF
}

# Checks if a command exists.
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! command_exists curl || ! command_exists jq || ! command_exists npm || ! command_exists npx; then
    log "ERRO" "Required dependencies (curl, jq, npm) are not installed." >&2
    exit 1
  fi
}

function get_latest_version() {
  log "INFO" "Getting latest version of ${APP_NAME} from GitHub..."
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  log "DEBU" "api_url: ${api_url}"
  export json_response
  if [ -n "${GITHUB_TOKEN}" ]; then
    local curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  json_response=$(curl -s "${curl_args[@]}" "${api_url}")
  # log "DEBU" "json_response \n ${json_response}"
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
  if [ ! -f "${INSTALL_DIR}/${APP_NAME}/backend/package.json" ]; then
    log "WARN" "${APP_NAME} is not installed"
    CURRENT_VERSION="0"
    return
  fi
  log "INFO" "Getting current version of ${APP_NAME}..."
  # The version output is like: "patchmon version 1.0.0"
  local current_version_full
  current_version_full=$(grep '"version"' "${INSTALL_DIR}/${APP_NAME}/backend/package.json" | head -1 | sed 's/.*"version": "\([^"]*\)".*/\1/')
  CURRENT_VERSION=$(echo "${current_version_full}" | sed 's/v//')
  log "INFO" "Current ${APP_NAME} version: ${CURRENT_VERSION}"
}

function make_temp_dir(){
  export TEMP_PATH=$(mktemp -d)
  if [ ! -d "${TEMP_PATH}" ]; then
    log "ERRO" "Could not create temp dir"
    exit 1
  fi
  log "INFO" "Temp path: ${TEMP_PATH}"
}

function backup() {
  log "INFO" "Creating Backups"
  if [ -f "${INSTALL_DIR}/${APP_NAME}/backend/.env" ]; then
    if ! sudo cp "${INSTALL_DIR}/${APP_NAME}/backend/.env" "${INSTALL_DIR}/backend.env"; then
      return 1
    fi
  else
    log "WARN" "File /opt/patchmon/backend/.env doesn't exist"
  fi
  if [ -f "${INSTALL_DIR}/${APP_NAME}/frontend/.env" ]; then
    if ! sudo cp "${INSTALL_DIR}/${APP_NAME}/frontend/.env" "${INSTALL_DIR}/frontend.env"; then
      return 1
    fi
  else
    log "WARN" "File /opt/patchmon/frontend/.env doesn't exist"
  fi
  if [ -f "${INSTALL_DIR}/${APP_NAME}/backend/update-settings.js" ]; then
    if ! sudo cp "${INSTALL_DIR}/${APP_NAME}/backend/update-settings.js" "${INSTALL_DIR}/update-settings.js"; then
      return 1
    fi
  else
    log "WARN" "File ${INSTALL_DIR}/${APP_NAME}/backend/update-settings.js doesn't exist"
  fi
}

function download() {
  log "INFO" "Downloading and installing update..."
  local tarball_url
  # log "DEBU" "json_response: ${json_response}"
  tarball_url=$(echo "${json_response}" | jq -r '.tarball_url')
  log "DEBU" "tarball_url: ${tarball_url}"
  if [ -z "${tarball_url}" ] || [ "${tarball_url}" == "null" ]; then
    log "ERRO" "Could not find tarball URL in GitHub API response."
    echo "${json_response}"
    exit 1
  fi

  log "INFO" "Downloading and extracting ${APP_NAME} version ${TAG_NAME} from ${tarball_url}"
  mkdir -p "${TEMP_PATH}/${APP_NAME}"
  curl -sL "${tarball_url}" | tar -xz --strip-components=1 -C "${TEMP_PATH}/${APP_NAME}" 2>&1 | log "INFO"
    }

function stop_service() {
  if systemctl status "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Stopping ${SERVICE_NAME} service..."
    sudo systemctl stop "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping stop."
  fi
}

function restart_service() {
  if systemctl status "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME} service..."
    sudo systemctl restart "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping restart."
  fi
}

# Cleanup function to remove temporary directory
function cleanup() {
  if [ -d "${TEMP_PATH}" ]; then
    log "INFO" "Cleaning up temporary directory: ${TEMP_PATH}"
    rm -rf "${TEMP_PATH}"
  fi
}

function build_update() {
  cd "${TEMP_PATH}/${APP_NAME}"
  export NODE_ENV=production
  log "INFO" "Installing ${APP_NAME} ..."
  if ! npm install --no-audit --no-fund --no-save --ignore-scripts 2>&1 | log "DEBU"; then
    log "ERRO" "Could not build ${APP_NAME}"
    exit 1
  fi
  cd "${TEMP_PATH}/${APP_NAME}/backend"
  rm -rf "${TEMP_PATH}/${APP_NAME}/backend/node_modules"
  rm -f "${TEMP_PATH}/${APP_NAME}/backend/package-lock.json"
  log "INFO" "Installing ${APP_NAME}/backend ..."
  if ! npm install --include=dev --no-audit --no-fund --ignore-scripts 2>&1 | log "DEBU"; then
      log "ERRO" "Could not build ${APP_NAME}/backend"
      exit 1
    fi
  log "INFO" "Rebuilding vite ..."
  if ! npm rebuild vite 2>&1 | log "DEBU"; then
    log "ERRO" "Could not rebuild vite"
    exit 1
  fi
  log "INFO" "Rebuilding rollup ..."
  if ! npm rebuild rollup 2>&1 | log "DEBU"; then
    log "ERRO" "Could not rebuild rollup"
    exit 1
  fi
  log "INFO" "Building ${APP_NAME}/backend ..."
  if ! npm run build 2>&1 | log "DEBU"; then
    log "ERRO" "Could not build ${APP_NAME}/backend"
    exit 1
  fi
  cd "${TEMP_PATH}/${APP_NAME}/frontend"
  log "INFO" "Installing ${APP_NAME}/frontend ..."
  if ! npm install --include=dev --no-audit --no-fund --no-save --ignore-scripts 2>&1 | log "DEBU"; then
    log "ERRO" "Could not build ${APP_NAME}/frontend"
    exit 1
  fi
  log "INFO" "Building ${APP_NAME}/frontend ..."
  if ! npm run build 2>&1 | log "DEBU"; then
    log "ERRO" "Could not build ${APP_NAME}/frontend"
    exit 1
  fi
  cp /opt/backend.env "${TEMP_PATH}/${APP_NAME}/backend/.env"
  cp /opt/frontend.env "${TEMP_PATH}/${APP_NAME}/frontend/.env"
  cd "${TEMP_PATH}/${APP_NAME}/backend"
  log "INFO" "Running 'npx prisma migrate deploy' ..."
  if ! npx prisma migrate deploy 2>&1 | log "DEBU"; then
    log "ERRO" "Could not run 'npx prisma migrate deploy'"
    exit 1
  fi
  log "INFO" "Running 'npx prisma generate' ..."
  if ! npx prisma generate 2>&1 | log "DEBU"; then
    log "ERRO" "Could not run 'npx prisma generate'"
    exit 1
  fi
}

function replace_me() {
  log "INFO" "Removing install directory"
  if ! sudo rm -r "${INSTALL_DIR}/${APP_NAME}"; then
    log "ERRO" "Failed to remove the install directory ${INSTALL_DIR}/${APP_NAME}"
    exit 1
  fi
  log "INFO" "Installing update..."
  if ! sudo mv "${TEMP_PATH}/${APP_NAME}" "${INSTALL_DIR}/${APP_NAME}"; then
    log "ERRO" "Failed to move ${APP_NAME} to ${INSTALL_DIR}. Aborting update."
    exit 1
  fi
}

# Main function to orchestrate the script execution
function main() {
  trap cleanup EXIT

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -d|--debug) DEBUG="true"; shift;;
      -h|--help) usage; exit 0;;
      *) log "ERRO" "Unknown parameter passed: $1"; usage; exit 1;;
    esac
  done
    
  log "INFO" "Starting ${APP_NAME} update script..."
  check_dependencies
  make_temp_dir
  
  get_latest_version
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date: ${CURRENT_VERSION}"
    log "INFO" "Script finished."
    exit 0
  fi

  log "INFO" "New version available for ${APP_NAME}: ${LATEST_VERSION}"

  stop_service

  if ! backup; then
    log "ERRO" "Backup unsuccesful"
    exit 1
  else
    log "INFO" "Backup successful"
  fi
  
  download
  build_update
  replace_me
  restart_service
  get_current_version
  
  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "Successfully updated ${APP_NAME} to ${LATEST_VERSION}."
  else
    log "ERRO" "Failed to update ${APP_NAME}. Still on ${CURRENT_VERSION}."
  fi

  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"
