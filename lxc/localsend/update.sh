#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest commits of localsend web and compares it to
# the local version. If out of date, it pulls updates, builds the static
# site with pnpm, and reloads Caddy.
#
# @author Nicholas Wilde, 0xb299a622
# @date 04 Oct 2026
# @version 0.1.0
#
################################################################################

# Options
set -o pipefail

# Constants
SERVICE_NAME="caddy"
APP_NAME="localsend"
INSTALL_DIR="/opt/localsend"
DEBUG="false"
SERVICE_MODE="false"

# Default variables
UPDATE_SUCCESS="true"
UPDATE_MESSAGES=()

# Source .env file if it exists
if [ -f "$(dirname "$0")/.env" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/.env"
fi

# Ensure NVM / Node / pnpm are in PATH
export PATH="/root/.nvm/versions/node/v25.2.1/bin:/usr/local/bin:/usr/bin:$PATH"

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

function check_dependencies() {
  local missing_deps=()
  for cmd in git node pnpm caddy; do
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

function apply_custom_config() {
  local config_file="${INSTALL_DIR}/nuxt.config.ts"
  if [ -f "${config_file}" ]; then
    log "INFO" "Applying custom base URL to nuxt.config.ts..."
    sed -i 's|baseUrl: "https://web.localsend.org"|baseUrl: "https://localsend.l.nicholaswilde.io"|' "${config_file}"
  fi
}

function update_script() {
  if [ ! -d "${INSTALL_DIR}/.git" ]; then
    log "ERRO" "Installation directory ${INSTALL_DIR} is not a git repository."
    UPDATE_SUCCESS="false"
    return 1
  fi

  log "INFO" "Fetching latest changes for ${APP_NAME}..."
  git -C "${INSTALL_DIR}" fetch origin main 2>&1 | log "INFO"

  local current_commit
  current_commit=$(git -C "${INSTALL_DIR}" rev-parse HEAD)
  local target_commit
  target_commit=$(git -C "${INSTALL_DIR}" rev-parse origin/main)

  log "INFO" "Current commit: ${current_commit:0:7}"
  log "INFO" "Target commit:  ${target_commit:0:7}"

  if [[ "${current_commit}" == "${target_commit}" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date."
    UPDATE_MESSAGES+=("${APP_NAME} is already up-to-date at ${current_commit:0:7}")
    return 0
  fi

  log "INFO" "Updating ${APP_NAME} from ${current_commit:0:7} to ${target_commit:0:7}..."
  # Discard local uncommitted changes before pull
  git -C "${INSTALL_DIR}" checkout -- nuxt.config.ts pnpm-lock.yaml 2>/dev/null || true
  if ! git -C "${INSTALL_DIR}" pull origin main; then
    log "ERRO" "Failed to pull updates from origin/main."
    UPDATE_SUCCESS="false"
    return 1
  fi

  apply_custom_config

  log "INFO" "Installing npm dependencies via pnpm..."
  if ! CI=true pnpm -C "${INSTALL_DIR}" install --force; then
    log "ERRO" "Failed to install dependencies with pnpm."
    UPDATE_SUCCESS="false"
    return 1
  fi

  log "INFO" "Building static web application..."
  if ! pnpm -C "${INSTALL_DIR}" run generate; then
    log "ERRO" "Failed to generate static site."
    UPDATE_SUCCESS="false"
    return 1
  fi

  log "INFO" "Reloading ${SERVICE_NAME}..."
  if systemctl is-active --quiet "${SERVICE_NAME}"; then
    systemctl reload "${SERVICE_NAME}" || systemctl restart "${SERVICE_NAME}"
  else
    systemctl start "${SERVICE_NAME}"
  fi

  # Verify HTTP endpoint
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ || echo "000")
  if [[ "${http_code}" =~ ^(200|301|302)$ ]]; then
    log "INFO" "Verification succeeded (HTTP ${http_code})."
    UPDATE_MESSAGES+=("Successfully updated to ${target_commit:0:7} (HTTP ${http_code}).")
  else
    log "WARN" "Service responded with HTTP ${http_code}."
    UPDATE_MESSAGES+=("Updated to ${target_commit:0:7} but received HTTP ${http_code}.")
  fi
}

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
  log "INFO" "Script finished."

  if [[ "${UPDATE_SUCCESS}" == "false" ]]; then
    exit 1
  fi
}

main "$@"
