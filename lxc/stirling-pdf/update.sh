#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of Stirling-PDF and compares it to
# the local version. If out of date, it stops the service, downloads the
# latest version, and restarts the service.
#
# @author Nicholas Wilde, 0xb299a622
# @date 04 Oct 2026
# @version 0.2.0
#
################################################################################

# Options
set -o pipefail

# These are constants
SERVICE_NAME="stirlingpdf"
APP_NAME="stirling-pdf"
INSTALL_DIR="/opt/Stirling-PDF"
JAR_FILE="${INSTALL_DIR}/Stirling-PDF.jar"
GITHUB_REPO="Stirling-Tools/Stirling-PDF"
DEBUG="false"
SERVICE_MODE="false"

# Default variables
TARGET_VERSION=""
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
}

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
  for cmd in curl jq java unzip; do
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

  local java_ver
  java_ver=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
  if [[ -n "${java_ver}" && "${java_ver}" -lt 25 ]]; then
    if command_exists apt-get; then
      log "WARN" "Java version ${java_ver} detected. Stirling-PDF requires Java 25+. Installing openjdk-25-jre-headless..."
      apt-get update && apt-get install -y openjdk-25-jre-headless
      update-alternatives --set java "$(update-alternatives --list java | grep 'java-25' | head -n 1)" 2>/dev/null || true
    fi
  fi
}

function check_root() {
  if [ "$UID" -ne 0 ]; then
    log "ERRO" "Please run as root or with sudo."
    exit 1
  fi
}

function get_latest_version() {
  if [[ -n "${TARGET_VERSION}" ]]; then
    LATEST_VERSION="${TARGET_VERSION#v}"
    log "INFO" "Target ${APP_NAME} version specified: ${LATEST_VERSION}"
    return 0
  fi

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
  if [ -f "${JAR_FILE}" ]; then
    CURRENT_VERSION=$(unzip -q -c "${JAR_FILE}" META-INF/MANIFEST.MF 2>/dev/null | grep '^Implementation-Version:' | awk '{print $2}' | tr -d '\r\n')
    if [ -z "${CURRENT_VERSION}" ]; then
      CURRENT_VERSION="unknown"
    fi
  else
    CURRENT_VERSION="0"
  fi
  log "INFO" "Current ${APP_NAME} version: ${CURRENT_VERSION}"
}

function stop_services() {
  if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
    log "INFO" "Stopping ${SERVICE_NAME}.service..."
    systemctl stop "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service is not running, skipping stop."
  fi
}

function restart_services() {
  if systemctl list-unit-files "${SERVICE_NAME}.service" &> /dev/null; then
    log "INFO" "Restarting ${SERVICE_NAME} service..."
    systemctl restart "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  else
    log "WARN" "Service ${SERVICE_NAME}.service not found, skipping restart."
    systemctl start "${SERVICE_NAME}.service" 2>&1 | log "INFO"
  fi
}

function download_and_install() {
  log "INFO" "Downloading Stirling-PDF.jar v${LATEST_VERSION}..."
  local temp_jar="/tmp/Stirling-PDF.jar"
  rm -f "${temp_jar}"

  local download_url="https://github.com/${GITHUB_REPO}/releases/download/v${LATEST_VERSION}/Stirling-PDF.jar"
  if ! curl -fsSL -o "${temp_jar}" "${download_url}"; then
    log "WARN" "Failed download with 'v' prefix, trying without 'v'..."
    download_url="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_VERSION}/Stirling-PDF.jar"
    if ! curl -fsSL -o "${temp_jar}" "${download_url}"; then
      log "ERRO" "Failed to download Stirling-PDF.jar from ${download_url}"
      return 1
    fi
  fi

  # Validate downloaded file size (> 50MB)
  local file_size
  file_size=$(stat -c%s "${temp_jar}" 2>/dev/null || stat -f%z "${temp_jar}" 2>/dev/null)
  if [[ -z "${file_size}" || "${file_size}" -lt 50000000 ]]; then
    log "ERRO" "Downloaded jar is too small (${file_size} bytes). Download may be corrupted."
    rm -f "${temp_jar}"
    return 1
  fi

  stop_services

  if [ -f "${JAR_FILE}" ]; then
    log "INFO" "Backing up existing JAR to ${JAR_FILE}.bak..."
    cp -f "${JAR_FILE}" "${JAR_FILE}.bak"
  fi

  log "INFO" "Installing new Stirling-PDF.jar..."
  mv -f "${temp_jar}" "${JAR_FILE}"
  chmod 644 "${JAR_FILE}"
  chown root:root "${JAR_FILE}"

  restart_services

  log "INFO" "Verifying service status..."
  local attempt=0
  local max_attempts=30
  while [ $attempt -lt $max_attempts ]; do
    if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
      log "INFO" "${SERVICE_NAME}.service is running."
      return 0
    fi
    sleep 1
    attempt=$((attempt + 1))
  done

  log "ERRO" "${SERVICE_NAME}.service failed to start after update."
  if [ -f "${JAR_FILE}.bak" ]; then
    log "WARN" "Restoring previous JAR backup..."
    mv -f "${JAR_FILE}.bak" "${JAR_FILE}"
    systemctl restart "${SERVICE_NAME}.service"
  fi
  return 1
}

function update_script() {
  get_latest_version || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to get latest version from GitHub."); return 1; }
  get_current_version || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to get current version."); return 1; }

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date: ${CURRENT_VERSION}"
    UPDATE_MESSAGES+=("${APP_NAME} is already up-to-date: ${CURRENT_VERSION}")
    return 0
  fi

  if download_and_install; then
    log "INFO" "Successfully updated ${APP_NAME} from ${CURRENT_VERSION} to ${LATEST_VERSION}"
    UPDATE_MESSAGES+=("Successfully updated ${APP_NAME} from ${CURRENT_VERSION} to ${LATEST_VERSION}")
  else
    log "ERRO" "Failed to update ${APP_NAME}"
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("Failed to update ${APP_NAME}")
    return 1
  fi
}

function main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--debug) DEBUG="true"; shift;;
      -s|--service) SERVICE_MODE="true"; shift;;
      -v|--version) TARGET_VERSION="$2"; shift 2;;
      *) shift;;
    esac
  done

  log "INFO" "Starting ${APP_NAME} update script..."
  check_root
  check_dependencies || exit 1
  update_script
  send_notification
  log "INFO" "Script finished."

  if [[ "${UPDATE_SUCCESS}" == "false" ]]; then
    exit 1
  fi
}

main "$@"
