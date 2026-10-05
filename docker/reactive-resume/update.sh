#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Checks for the latest release of reactive-resume and updates compose.yaml.
# If out of date, it updates the version tag and recreates the containers.
#
# @author Nicholas Wilde, 0xb299a622
# @date 04 Oct 2026
# @version 1.1.0
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
GITHUB_REPO="reactive-resume/reactive-resume"
COMPOSE_FILE="compose.yaml"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Target version if passed via -v
TARGET_VERSION=""
ENABLE_NOTIFICATIONS="false"

# Change to script directory
cd "${SCRIPT_DIR}" || exit 1

# Source environment variables if they exist
if [ -f "${SCRIPT_DIR}/.env" ]; then
  source "${SCRIPT_DIR}/.env"
fi

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
  if [[ -n "${TARGET_VERSION}" ]]; then
    LATEST_VERSION="${TARGET_VERSION}"
    if [[ ! "${LATEST_VERSION}" =~ ^v ]]; then
      LATEST_VERSION="v${LATEST_VERSION}"
    fi
    log "INFO" "Target ${APP_NAME} version specified: ${LATEST_VERSION}"
    return 0
  fi

  log "INFO" "Getting latest version of ${APP_NAME} from GitHub..."
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  local json_response
  local curl_args=('-s' '-L')
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
  local running_image
  if command -v docker >/dev/null 2>&1 && running_image=$(docker inspect reactive_resume-reactive_resume-1 --format '{{.Config.Image}}' 2>/dev/null) && [[ -n "${running_image}" ]]; then
    local parsed_ver
    parsed_ver=$(echo "${running_image}" | grep -oP 'reactive-resume:\K.*' || true)
    if [[ -n "${parsed_ver}" ]]; then
      CURRENT_VERSION="${parsed_ver}"
      log "INFO" "Current ${APP_NAME} version (running container): ${CURRENT_VERSION}"
      return 0
    fi
  fi

  if [ ! -f "${COMPOSE_FILE}" ]; then
    log "ERRO" "${COMPOSE_FILE} not found."
    exit 1
  fi
  CURRENT_VERSION=$(grep -oP "image:\s*\"?ghcr.io/(amruthpillai|reactive-resume)/reactive-resume:\K[^\"]+" "${COMPOSE_FILE}")
  log "INFO" "Current ${APP_NAME} version (compose): ${CURRENT_VERSION}"
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
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -v|--version) TARGET_VERSION="$2"; shift 2;;
      -s|--service) shift;;
      -d|--debug) shift;;
      *) shift;;
    esac
  done

  log "INFO" "Starting ${APP_NAME} update script..."

  get_latest_version
  get_current_version

  local running_image
  running_image=$(docker inspect reactive_resume-reactive_resume-1 --format '{{.Config.Image}}' 2>/dev/null || true)

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]] && [[ "${running_image}" =~ :${LATEST_VERSION}$ ]]; then
    log "INFO" "${APP_NAME} is already up-to-date and running: ${CURRENT_VERSION}"
    exit 0
  fi

  log "INFO" "New version available: ${LATEST_VERSION}. Updating ${COMPOSE_FILE}..."

  # Update compose.yaml
  sed -i -E "s|image: ghcr.io/(amruthpillai\|reactive-resume)/reactive-resume:.*|image: ghcr.io/reactive-resume/reactive-resume:${LATEST_VERSION}|" "${COMPOSE_FILE}"

  # Database pre-upgrade backup
  if command -v docker >/dev/null 2>&1 && docker ps | grep -q "postgres"; then
    log "INFO" "Creating database backup before upgrade..."
    mkdir -p /root/backups
    docker exec reactive_resume-postgres-1 pg_dump -U postgres postgres > "/root/backups/reactive-resume-pre-${LATEST_VERSION}.sql" 2>/dev/null || true
  fi

  log "INFO" "Pulling new image..."
  docker compose pull reactive_resume

  log "INFO" "Recreating reactive-resume container..."
  docker compose up -d --force-recreate --remove-orphans reactive_resume

  log "INFO" "Pruning dangling docker images..."
  docker image prune -f >/dev/null 2>&1 || true

  get_current_version
  log "SUCC" "${APP_NAME} updated successfully to ${CURRENT_VERSION}."
  send_notification

  log "INFO" "Script finished."
}

main "$@"
