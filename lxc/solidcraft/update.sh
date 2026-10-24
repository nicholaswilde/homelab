#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of SolidCraft web and compares it to
# the local version. If out of date, it downloads the latest version,
# unpacks it to the installation directory, and reloads nginx.
#
# @author Nicholas Wilde, 0xb299a622
# @date 20 Oct 2026
# @version 0.1.0
#
################################################################################

# Options
set -o pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}"

# Constants
SERVICE_NAME="nginx"
APP_NAME="solidcraft"
INSTALL_DIR="/srv/solidcraft"
GITHUB_REPO="tangency-labs/solidcraft"
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

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function send_notification() {
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
  for cmd in curl jq unzip nginx; do
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
  if [[ -n "${TARGET_VERSION}" ]]; then
    LATEST_VERSION="${TARGET_VERSION#v}"
    log "INFO" "Target ${APP_NAME} version specified: ${LATEST_VERSION}"
    return 0
  fi

  log "INFO" "Getting latest version of ${APP_NAME} from GitHub..."
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  local json_response
  local curl_args=()
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
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
  if [ -f "${INSTALL_DIR}/version.txt" ]; then
    CURRENT_VERSION=$(cat "${INSTALL_DIR}/version.txt")
  elif [ -f "${INSTALL_DIR}/build.json" ]; then
    CURRENT_VERSION=$(jq -r '.version // "0"' "${INSTALL_DIR}/build.json" | cut -d'-' -f1)
  else
    log "WARN" "Version file not found at ${INSTALL_DIR}."
    CURRENT_VERSION="0"
    return 0
  fi
  log "INFO" "Current ${APP_NAME} version: ${CURRENT_VERSION}"
}

function download_and_install() {
  log "INFO" "Downloading and installing update..."
  local download_url="https://github.com/${GITHUB_REPO}/releases/download/v${LATEST_VERSION}/solidcraft-web-${LATEST_VERSION}.zip"
  local temp_dir
  temp_dir=$(mktemp -d)

  log "INFO" "Downloading web bundle from ${download_url}..."
  if ! curl -fsSL "${download_url}" -o "${temp_dir}/bundle.zip"; then
    log "ERRO" "Failed to download update. Aborting."
    rm -rf "${temp_dir}"
    return 1
  fi

  log "INFO" "Extracting bundle..."
  if ! unzip -q "${temp_dir}/bundle.zip" -d "${temp_dir}/extracted"; then
    log "ERRO" "Failed to extract bundle. Aborting."
    rm -rf "${temp_dir}"
    return 1
  fi

  mkdir -p "${INSTALL_DIR}"
  if [ -d "${temp_dir}/extracted/solidcraft-web-${LATEST_VERSION}" ]; then
    cp -rf "${temp_dir}/extracted/solidcraft-web-${LATEST_VERSION}/"* "${INSTALL_DIR}/"
  else
    cp -rf "${temp_dir}/extracted/"* "${INSTALL_DIR}/"
  fi

  echo "${LATEST_VERSION}" > "${INSTALL_DIR}/version.txt"
  rm -rf "${temp_dir}"

  log "INFO" "Testing nginx configuration..."
  if nginx -t 2>&1 | log "INFO"; then
    log "INFO" "Reloading nginx..."
    systemctl reload "${SERVICE_NAME}" || systemctl restart "${SERVICE_NAME}"
  else
    log "ERRO" "Nginx configuration test failed."
    return 1
  fi

  # Verify HTTP endpoint
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")
  if [[ "${http_code}" =~ ^(200|301|302)$ ]]; then
    log "INFO" "Verification succeeded (HTTP ${http_code})."
    UPDATE_MESSAGES+=("Successfully updated ${APP_NAME} to ${LATEST_VERSION} (HTTP ${http_code}).")
  else
    log "WARN" "Service responded with HTTP ${http_code}."
    UPDATE_MESSAGES+=("Updated ${APP_NAME} to ${LATEST_VERSION} but received HTTP ${http_code}.")
  fi
}

function update_script() {
  check_dependencies || return 1
  get_latest_version || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to get latest version from GitHub."); return 1; }
  get_current_version || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to get current version."); return 1; }

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date: ${CURRENT_VERSION}"
    UPDATE_MESSAGES+=("${APP_NAME} is already up-to-date: ${CURRENT_VERSION}")
    return 0
  fi

  log "INFO" "New version available for ${APP_NAME}: ${LATEST_VERSION}"
  UPDATE_MESSAGES+=("Updating ${APP_NAME} from ${CURRENT_VERSION} to ${LATEST_VERSION}.")

  download_and_install || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to download or install update."); return 1; }
}

function main() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -s|--service) SERVICE_MODE="true"; shift;;
      -d|--debug) DEBUG="true"; shift;;
      -v|--version) TARGET_VERSION="$2"; shift 2;;
      *) shift;;
    esac
  done

  log "INFO" "Starting ${APP_NAME} update script..."
  update_script
  local exit_code=$?

  if [[ "${exit_code}" -ne 0 ]]; then
    UPDATE_SUCCESS="false"
  fi

  send_notification
  log "INFO" "Script finished."

  if [[ "${UPDATE_SUCCESS}" == "false" ]]; then
    exit 1
  fi
}

main "$@"
