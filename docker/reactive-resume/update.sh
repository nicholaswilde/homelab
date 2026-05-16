#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of reactive-resume and updates compose.yaml.
# If out of date, it updates the version tag and runs task update.
#
# @author Nicholas Wilde, 0xb299a622
# @date 16 May 2026
# @version 1.0.0
#
################################################################################

# Options
set -e
set -o pipefail

# Constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly GREEN=$(tput setaf 2)
readonly RESET=$(tput sgr0)

APP_NAME="reactive-resume"
GITHUB_REPO="amruthpillai/reactive-resume"
COMPOSE_FILE="compose.yaml"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Source environment variables if they exist
if [ -f "${SCRIPT_DIR}/.env" ]; then
  source "${SCRIPT_DIR}/.env"
fi

# Logging function
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  case "$type" in
    INFO) color="$BLUE";;
    WARN) color="$YELLOW";;
    ERRO) color="$RED";;
    SUCC) color="$GREEN";;
  esac

  echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
}

function get_latest_version() {
  log "INFO" "Getting latest version of ${APP_NAME} from GitHub..."
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  local json_response
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  json_response=$(curl "${curl_args[@]}" "${api_url}")
  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ${APP_NAME} from GitHub API."
    return 1
  fi

  LATEST_VERSION=$(echo "${json_response}" | jq -r '.tag_name')
  log "INFO" "Latest ${APP_NAME} version: ${LATEST_VERSION}"
}

function get_current_version() {
  if [ ! -f "${COMPOSE_FILE}" ]; then
    log "ERRO" "${COMPOSE_FILE} not found."
    exit 1
  fi
  # Extracts version from line like: image: ghcr.io/amruthpillai/reactive-resume:v5.1.4
  CURRENT_VERSION=$(grep -oP "image: ghcr.io/amruthpillai/reactive-resume:\K.*" "${COMPOSE_FILE}")
  log "INFO" "Current ${APP_NAME} version: ${CURRENT_VERSION}"
}

function send_notification(){
  if [[ "${ENABLE_NOTIFICATIONS}" != "true" ]]; then
    return 0
  fi
  if [[ -z "${MAILRISE_URL}" || -z "${MAILRISE_FROM}" || -z "${MAILRISE_RCPT}" ]]; then
    log "WARN" "Notification variables not set. Skipping."
    return 1
  fi

  local EMAIL_SUBJECT="Homelab - Update ${APP_NAME} Summary"
  local EMAIL_BODY="${APP_NAME} updated from ${CURRENT_VERSION} to ${LATEST_VERSION}."

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

function main() {
  log "INFO" "Starting ${APP_NAME} update script..."
  
  get_latest_version
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date: ${CURRENT_VERSION}"
    exit 0
  fi

  log "INFO" "New version available: ${LATEST_VERSION}. Updating ${COMPOSE_FILE}..."
  
  # Update compose.yaml
  sed -i "s|image: ghcr.io/amruthpillai/reactive-resume:.*|image: ghcr.io/amruthpillai/reactive-resume:${LATEST_VERSION}|" "${COMPOSE_FILE}"
  
  log "INFO" "Running task update..."
  if task update; then
    log "SUCC" "${APP_NAME} updated successfully to ${LATEST_VERSION}."
    send_notification
  else
    log "ERRO" "Failed to update ${APP_NAME}."
    exit 1
  fi

  log "INFO" "Script finished."
}

main "$@"
