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
set -o pipefail

# These are constants
SERVICE_NAME="nginx"
APP_NAME="omni-tools"
INSTALL_DIR="/opt/omni-tools"
GITHUB_REPO="iib0011/omni-tools"
DEBUG="false"
SERVICE_MODE="false"
readonly VERSION_FILENAME="omni-tools_version.txt"

# Default variables
ENABLE_NOTIFICATIONS="false"
UPDATE_SUCCESS="true"
UPDATE_MESSAGES=()

# Source .env file if it exists
if [ -f "$(dirname "$0")/.env" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/.env"
fi

# Load fnm if it exists (useful for background services)
if [ -d "$HOME/.local/share/fnm" ]; then
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env --use-on-cd)"
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

  # Define colors only if stdout is a terminal and not in service mode
  if [[ -t 1 ]] && [[ "${SERVICE_MODE}" == "false" ]]; then
    readonly BLUE_COL="\033[38;2;137;180;250m"
    readonly RED_COL="\033[38;2;243;139;168m"
    readonly YELLOW_COL="\033[38;2;249;226;175m"
    readonly PURPLE_COL="\033[38;2;203;166;247m"
    readonly RESET_COL="\033[0m"
    
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
}

# Checks if a command exists.
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function send_notification(){
  if [[ "${ENABLE_NOTIFICATIONS}" == "false" ]]; then
    log "WARN" "Notifications are disabled. Skipping."
    return 0
  fi
  if [[ -z "${MAILRISE_URL}" || -z "${MAILRISE_FROM}" || -z "${MAILRISE_RCPT}" ]]; then
    log "WARN" "Notification variables not set. Skipping notification."
    return 1
  fi

  local EMAIL_SUBJECT="Homelab - Update ${APP_NAME} Summary"
  local EMAIL_BODY

  if [[ "${UPDATE_SUCCESS}" == "true" ]]; then
    EMAIL_BODY="${APP_NAME} update completed successfully."
  else
    EMAIL_BODY="${APP_NAME} update encountered errors."
  fi

  if [ ${#UPDATE_MESSAGES[@]} -gt 0 ]; then
    EMAIL_BODY+=$'\\n\\nUpdate details:\\n'
    for msg in "${UPDATE_MESSAGES[@]}"; do
      EMAIL_BODY+="- ${msg}"$'\n'
    done
  fi

  log "INFO" "Sending email notification..."
  curl -s \
    --url "${MAILRISE_URL}" \
    --mail-from "${MAILRISE_FROM}" \
    --mail-rcpt "${MAILRISE_RCPT}" \
    --upload-file - <<EOF
From: ${APP_NAME} Update <${MAILRISE_FROM}>
To: Nicholas Wilde <${MAILRISE_RCPT}>
Subject: ${EMAIL_SUBJECT}

${EMAIL_BODY}
EOF
  log "INFO" "Email notification sent."
}

function check_dependencies() {
  local missing_deps=()
  for cmd in curl jq npm; do
    if ! command_exists "$cmd"; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -ne 0 ]; then
    log "ERRO" "Required dependencies are not installed: ${missing_deps[*]}" >&2
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("Missing dependencies: ${missing_deps[*]}")
    return 1
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
  
  log "INFO" "Getting current version of ${APP_NAME}..."
  local current_version_full
  if [ -f "${basedir}/${VERSION_FILENAME}" ]; then
    current_version_full=$(cat "${basedir}/${VERSION_FILENAME}")
  else
    current_version_full="0.0.0"
  fi
  CURRENT_VERSION=$(echo "${current_version_full}" | sed 's/v//')
  log "INFO" "Current ${APP_NAME} version: ${CURRENT_VERSION}"
}

function stop_services(){
  if systemctl status "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Stopping ${SERVICE_NAME}.service..."
    systemctl stop "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping stop."
  fi
}

function remove_old_install(){  
  export basedir=$(dirname "${INSTALL_DIR}")
  log "INFO" "Removing old application files..."
  if ! rm -rf "${INSTALL_DIR}"; then
    log "ERRO" "There was an error removing the application"
    return 1
  fi
}

function restart_services(){
  if systemctl list-unit-files "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME} service..."
    systemctl restart "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping restart."
  fi
}

function download_and_extract(){
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "${TEMP_DIR}"' EXIT
  
  tarball_url=$(echo "${json_response}" | jq -r '.tarball_url')
  log "INFO" "Downloading update..."
  if ! curl -LsSf "${tarball_url}" -o "${TEMP_DIR}/omni-tools.tar.gz"; then
    log "ERRO" "There was an error downloading the update"
    return 1
  fi

  mkdir -p "${INSTALL_DIR}"
  log "INFO" "Extracting update..."
  if ! tar -xzf "${TEMP_DIR}/omni-tools.tar.gz" -C "${INSTALL_DIR}" --strip-components=1; then
    log "ERRO" "There was an error extracting the update"
    return 1
  fi
}

function setup_app(){
  setup_frontend
}

function setup_frontend(){
  log "INFO" "Setting up frontend..."
  cd "${INSTALL_DIR}"
  
  log "INFO" "  -> Running npm install..."
  if npm install --no-audit --no-fund &> /dev/null; then
    log "INFO" "  -> npm install successful"
  else
    log "ERRO" "  -> There was an error installing npm packages"
    return 1
  fi
  
  log "INFO" "  -> Running npm run build..."
  if npm run build &> /dev/null; then
    log "INFO" "  -> npm build successful"
  else
    log "ERRO" "  -> There was an error building the application"
    return 1
  fi

  log "INFO" "  -> Copying distribution files to /var/www/html/"
  if ! cp -r "${INSTALL_DIR}/dist/"* /var/www/html/; then
    log "ERRO" "  -> There was an error copying the distribution files"
    return 1
  fi
}

function update_script() {
  get_latest_version || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to get latest version from GitHub."); return 1; }
  get_current_version || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to get current version."); return 1; }
  
  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date: ${CURRENT_VERSION}"
    UPDATE_MESSAGES+=("${APP_NAME} is already up-to-date: ${CURRENT_VERSION}")
    return 0
  fi
  
  log "INFO" "New version available for ${APP_NAME}: ${LATEST_VERSION}"
  UPDATE_MESSAGES+=("Updating ${APP_NAME} from ${CURRENT_VERSION} to ${LATEST_VERSION}.")
  
  stop_services || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to stop services."); }
  remove_old_install || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to remove old installation."); return 1; }

  download_and_extract || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to download or extract update."); return 1; }
  setup_app || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to setup application."); return 1; }
  write_version || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to write version file."); }
  restart_services || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to restart services."); }
  
  get_current_version
  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "Successfully updated ${APP_NAME} to ${LATEST_VERSION}."
    UPDATE_MESSAGES+=("Successfully updated to ${LATEST_VERSION}.")
  else
    log "ERRO" "Failed to update ${APP_NAME}. Still on ${CURRENT_VERSION}."
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("Update verification failed. Still on ${CURRENT_VERSION}.")
    return 1
  fi
}

function write_version(){
  printf "%s" "${LATEST_VERSION}" > "${basedir}/${VERSION_FILENAME}"
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

  log "INFO" "Starting ${APP_NAME} update script..."
  if check_dependencies; then
    update_script
  fi
  
  send_notification
  log "INFO" "Script finished."
  if [[ "${UPDATE_SUCCESS}" == "false" ]]; then
    exit 1
  fi
}

# Call main to start the script
main "$@"
