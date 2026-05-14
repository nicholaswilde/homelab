#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of drawio and compares it to
# the local version. If out of date, it stops the service, downloads the
# latest version, and restarts the service.
#
# @author Nicholas Wilde, 0xb299a622
# @date 13 May 2026
# @version 0.2.0
#
################################################################################

# Options
set -o pipefail

# These are constants
SERVICE_NAME="tomcat10"
APP_NAME="drawio"
INSTALL_DIR="/var/lib/tomcat10/webapps"
GITHUB_REPO="jgraph/drawio"
DEBUG="false"
SERVICE_MODE="false"

# Default variables
ENABLE_NOTIFICATIONS="false"
UPDATE_SUCCESS="true"
UPDATE_MESSAGES=()

# Source .env file if it exists
if [ -f "$(dirname "$0")/.env" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/.env"
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
    BLUE_COL="\033[38;2;137;180;250m"
    RED_COL="\033[38;2;243;139;168m"
    YELLOW_COL="\033[38;2;249;226;175m"
    PURPLE_COL="\033[38;2;203;166;247m"
    RESET_COL="\033[0m"
    
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

  # LogWard Integration
  if [[ -n "${LOGWARD_API_KEY}" ]]; then
    local LOGWARD_API_URL="${LOGWARD_API_URL:-https://logward.l.nicholaswilde.io/api/v1/ingest/single}"
    local LOGWARD_SERVICE_NAME="${LOGWARD_SERVICE_NAME:-$(basename "$0")}"
    local json_payload
    json_payload=$(cat <<EOF
{
  "service": "${LOGWARD_SERVICE_NAME}",
  "level": "${type}",
  "message": "${message:-$(cat)}",
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
    EMAIL_BODY+=$'\n\nUpdate details:\n'
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
  for cmd in curl jq java; do
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
  local json_response
  json_response=$(curl -s "${curl_args[@]}" "${api_url}")
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
  if [ -f "${INSTALL_DIR}/draw.version" ]; then
      CURRENT_VERSION=$(cat "${INSTALL_DIR}/draw.version")
  else
      CURRENT_VERSION="0"
  fi
  log "INFO" "Current ${APP_NAME} version: ${CURRENT_VERSION}"
}

function stop_services(){
  if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
    log "INFO" "Stopping ${SERVICE_NAME}.service..."
    systemctl stop "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service is not running, skipping stop."
  fi
}

function restart_services(){
  if systemctl list-unit-files "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME} service..."
    systemctl restart "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping restart."
    # Try start
    systemctl start "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  fi
}

function download_and_install(){
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
  
  local DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${LATEST_VERSION}/draw.war"
  
  if ! curl -L -o "${INSTALL_DIR}/ROOT.war" "${DOWNLOAD_URL}"; then
     log "ERRO" "Failed to download ${DOWNLOAD_URL}"
     return 1
  fi
  
  # Update version file
  echo "${LATEST_VERSION}" > "${INSTALL_DIR}/draw.version"
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

  download_and_install || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to download or install update."); return 1; }
  
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
