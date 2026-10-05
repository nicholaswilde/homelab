#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of ConvertX and updates compose.yaml.
# If out of date, updates the image tag and restarts the containers.
#
# @author Nicholas Wilde
# @date 04 Oct 2026
# @version 1.0.0
#
################################################################################

# Options
set -o pipefail

# Constants
APP_NAME="convertx"
GITHUB_REPO="C4illin/ConvertX"
COMPOSE_FILE="compose.yaml"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Default variables
TARGET_VERSION=""
ENABLE_NOTIFICATIONS="false"
UPDATE_SUCCESS="true"
UPDATE_MESSAGES=()
DEBUG="false"
SERVICE_MODE="false"

# Change to script directory
cd "${SCRIPT_DIR}" || exit 1

# Source .env file if it exists
if [ -f "${SCRIPT_DIR}/.env" ]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/.env"
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
    GREEN_COL="\033[38;2;166;227;161m"
    RESET_COL="\033[0m"

    case "$type" in
      INFO) color="$BLUE_COL";;
      WARN) color="$YELLOW_COL";;
      ERRO) color="$RED_COL";;
      DEBU) color="$PURPLE_COL";;
      SUCC) color="$GREEN_COL";;
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
  if [[ "${ENABLE_NOTIFICATIONS}" != "true" ]]; then
    return 0
  fi
  if [[ -z "${MAILRISE_URL}" || -z "${MAILRISE_FROM}" || -z "${MAILRISE_RCPT}" ]]; then
    log "WARN" "Notification variables not set. Skipping."
    return 1
  fi

  local EMAIL_SUBJECT="Homelab - Update ${APP_NAME} Summary"
  local EMAIL_BODY
  if [[ "${UPDATE_SUCCESS}" == "true" ]]; then
    EMAIL_BODY="${APP_NAME} updated from ${CURRENT_VERSION} to ${LATEST_VERSION}."
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
  for cmd in curl jq docker; do
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
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  local json_response
  json_response=$(curl "${curl_args[@]}" "${api_url}")
  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ${APP_NAME} from GitHub API."
    return 1
  fi

  local tag_name
  tag_name=$(echo "${json_response}" | jq -r '.tag_name')
  LATEST_VERSION="${tag_name#v}"
  log "INFO" "Latest ${APP_NAME} version: ${LATEST_VERSION}"
}

function get_current_version() {
  if [ ! -f "${COMPOSE_FILE}" ]; then
    log "ERRO" "${COMPOSE_FILE} not found."
    return 1
  fi
  local raw_version
  raw_version=$(grep -oP 'image:\s*"?ghcr.io/c4illin/convertx:\K[^"]+' "${COMPOSE_FILE}")
  CURRENT_VERSION="${raw_version#v}"
  log "INFO" "Current ${APP_NAME} version: ${CURRENT_VERSION}"
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

  log "INFO" "Updating ${COMPOSE_FILE} image tag to v${LATEST_VERSION}..."
  sed -i "s|image: \"ghcr.io/c4illin/convertx:.*\"|image: \"ghcr.io/c4illin/convertx:v${LATEST_VERSION}\"|" "${COMPOSE_FILE}"

  log "INFO" "Pulling new Docker image..."
  docker compose pull convertx || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to pull docker image."); return 1; }

  log "INFO" "Recreating convertx container..."
  docker compose up -d --force-recreate --remove-orphans convertx || { UPDATE_SUCCESS="false"; UPDATE_MESSAGES+=("Failed to recreate container."); return 1; }

  log "INFO" "Pruning dangling docker images..."
  docker image prune -f >/dev/null 2>&1 || true

  get_current_version
  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "SUCC" "Successfully updated ${APP_NAME} to ${LATEST_VERSION}."
    UPDATE_MESSAGES+=("Successfully updated to ${LATEST_VERSION}.")
  else
    log "ERRO" "Update verification failed. Still on ${CURRENT_VERSION}."
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("Update verification failed.")
    return 1
  fi
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
  if check_dependencies; then
    update_script
  fi

  send_notification
  log "INFO" "Script finished."
  if [[ "${UPDATE_SUCCESS}" == "false" ]]; then
    exit 1
  fi
}

main "$@"
