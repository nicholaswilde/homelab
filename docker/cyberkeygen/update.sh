#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Updates CyberKeyGen by pulling the latest source repository, rebuilding the
# Vite static bundle, recreating the nginx Docker container, and verifying HTTP.
#
# @author Nicholas Wilde, 0xb299a622
# @date 14 Nov 2026
# @version 0.1.0
#
################################################################################

# Options
set -o pipefail

# Constants
APP_NAME="cyberkeygen"
INSTALL_DIR="/opt/cyberkeygen"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
COMPOSE_FILE="${SCRIPT_DIR}/compose.yaml"

# Default variables
TARGET_VERSION=""
ENABLE_NOTIFICATIONS="false"
UPDATE_SUCCESS="true"
UPDATE_MESSAGES=()
DEBUG="false"
SERVICE_MODE="false"

cd "${SCRIPT_DIR}" || exit 1

if [ -f "${SCRIPT_DIR}/.env" ]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/.env"
fi

function log() {
  local type="$1"
  local message="$2"
  local color=""
  local reset=""

  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi

  if [[ -t 1 ]] && [[ "${SERVICE_MODE}" == "false" ]]; then
    local blue="\033[38;2;137;180;250m"
    local red="\033[38;2;243;139;168m"
    local yellow="\033[38;2;249;226;175m"
    local purple="\033[38;2;203;166;247m"
    local green="\033[38;2;166;227;161m"
    reset="\033[0m"

    case "$type" in
      INFO) color="$blue";;
      WARN) color="$yellow";;
      ERRO) color="$red";;
      DEBU) color="$purple";;
      SUCC) color="$green";;
    esac
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

function check_dependencies() {
  local missing_deps=()
  for cmd in git docker curl; do
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

  if ! command_exists npm; then
    log "WARN" "npm not found; installing nodejs and npm via apt-get..."
    if apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs npm; then
      log "INFO" "Installed nodejs and npm."
      UPDATE_MESSAGES+=("Installed missing nodejs and npm packages.")
    else
      log "ERRO" "Failed to install nodejs and npm."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Failed to install nodejs and npm.")
      return 1
    fi
  fi
}

function send_notification() {
  if [[ "${ENABLE_NOTIFICATIONS}" != "true" ]]; then
    return 0
  fi
  if [[ -z "${MAILRISE_URL}" || -z "${MAILRISE_FROM}" || -z "${MAILRISE_RCPT}" ]]; then
    log "WARN" "Notification variables not set. Skipping."
    return 1
  fi

  local email_subject="Homelab - Update ${APP_NAME} Summary"
  local email_body
  if [[ "${UPDATE_SUCCESS}" == "true" ]]; then
    email_body="${APP_NAME} update completed successfully."
  else
    email_body="${APP_NAME} update encountered errors."
  fi

  if [ ${#UPDATE_MESSAGES[@]} -gt 0 ]; then
    email_body+=$'\n\nUpdate details:\n'
    for msg in "${UPDATE_MESSAGES[@]}"; do
      email_body+="- ${msg}"$'\n'
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
Subject: ${email_subject}

${email_body}
EOF
  log "INFO" "Email notification sent."
}

function update_script() {
  if [ ! -d "${INSTALL_DIR}/.git" ]; then
    log "ERRO" "Git repository not found at ${INSTALL_DIR}."
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("Git repository not found at ${INSTALL_DIR}.")
    return 1
  fi

  local current_sha target_ref target_sha
  current_sha=$(git -C "${INSTALL_DIR}" rev-parse --short HEAD)
  log "INFO" "Current ${APP_NAME} commit: ${current_sha}"

  log "INFO" "Fetching upstream changes in ${INSTALL_DIR}..."
  if ! git -C "${INSTALL_DIR}" fetch --tags origin; then
    log "ERRO" "Failed to fetch upstream changes."
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("Failed to fetch upstream changes.")
    return 1
  fi

  if [[ -n "${TARGET_VERSION}" ]]; then
    target_ref="${TARGET_VERSION}"
    if ! git -C "${INSTALL_DIR}" rev-parse --verify "${target_ref}" >/dev/null 2>&1; then
      target_ref="v${TARGET_VERSION#v}"
    fi
  else
    target_ref="origin/main"
  fi

  target_sha=$(git -C "${INSTALL_DIR}" rev-parse --short "${target_ref}") || {
    log "ERRO" "Target ref '${target_ref}' not found."
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("Target ref '${target_ref}' not found.")
    return 1
  }
  log "INFO" "Target ${APP_NAME} commit (${target_ref}): ${target_sha}"

  if [[ "${current_sha}" == "${target_sha}" ]] && [[ -f "${INSTALL_DIR}/dist/index.html" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date (${current_sha})."
    UPDATE_MESSAGES+=("${APP_NAME} is already up-to-date (${current_sha}).")
  else
    log "INFO" "Updating ${INSTALL_DIR} from ${current_sha} to ${target_sha}..."
    git -C "${INSTALL_DIR}" checkout -- .
    if ! git -C "${INSTALL_DIR}" reset --hard "${target_ref}"; then
      log "ERRO" "Failed to reset ${INSTALL_DIR} to ${target_ref}."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Failed to reset ${INSTALL_DIR} to ${target_ref}.")
      return 1
    fi

    log "INFO" "Installing npm dependencies..."
    if ! npm install --prefix "${INSTALL_DIR}" --no-audit --no-fund; then
      log "ERRO" "npm install failed."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("npm install failed.")
      return 1
    fi

    log "INFO" "Building static bundle..."
    if ! npm run --prefix "${INSTALL_DIR}" build; then
      log "ERRO" "npm run build failed."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("npm run build failed.")
      return 1
    fi

    log "INFO" "Recreating ${APP_NAME} container..."
    if ! docker compose -f "${COMPOSE_FILE}" pull || ! docker compose -f "${COMPOSE_FILE}" up -d --force-recreate --remove-orphans; then
      log "ERRO" "Failed to recreate ${APP_NAME} container."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Failed to recreate ${APP_NAME} container.")
      return 1
    fi

    docker image prune -f >/dev/null 2>&1 || true
    UPDATE_MESSAGES+=("Updated ${APP_NAME} from ${current_sha} to ${target_sha}.")
  fi

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ || echo "000")
  if [[ "${http_code}" =~ ^(200|301|302)$ ]]; then
    log "SUCC" "Verified ${APP_NAME} HTTP health (HTTP ${http_code})."
  else
    log "ERRO" "${APP_NAME} HTTP check failed (HTTP ${http_code})."
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("HTTP health check failed with status ${http_code}.")
    return 1
  fi
}

function main() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
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
