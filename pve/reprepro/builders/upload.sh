#!/usr/bin/env bash
################################################################################
#
# Script Name: upload.sh
# ----------------
# Uploads built .deb files to a remote reprepro server and triggers the import.
# Includes logging and remote cleanup.
#
# @author Nicholas Wilde, 0xb299a622
# @date 09 May 2026
# @version 1.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# --- Colors (Catppuccin Mocha) ---
RESET='\033[0m'
BLUE='\033[38;5;111m'
YELLOW='\033[38;5;221m'
RED='\033[38;5;203m'
GREEN='\033[38;5;120m'

# --- Configuration ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PARENT_DIR=$(dirname "${SCRIPT_DIR}")
ENV_FILE="${PARENT_DIR}/.env"
DEFAULT_REMOTE_HOST="root@reprepro.l.nicholaswilde.io"
DEFAULT_REMOTE_REPO_PATH="/root/git/nicholaswilde/homelab/pve/reprepro"
LOCAL_DIST_DIR="${SCRIPT_DIR}/dist"
REMOTE_TEMP_DIR="/tmp/reprepro-upload"

# --- Functions ---

function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"
  [[ "${type}" = "DEBU" ]] && [[ "${DEBUG}" != "true" ]] && return 0

  case "$type" in
    INFO) color="$BLUE";;
    WARN) color="$YELLOW";;
    ERRO) color="$RED";;
    SUCC) color="$GREEN";;
  esac
  local timestamp
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')
  
  if [[ -n "${message}" ]]; then
    echo -e "${color}${type}${RESET}[${timestamp}] ${message}" >&2
  else
    while IFS= read -r line; do
      # Strip existing prefixes like "INFO[2026-05-10 06:57:40] "
      local clean_line
      clean_line=$(echo "$line" | sed -E 's/^[A-Z]{4}\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] //')
      echo -e "${color}${type}${RESET}[${timestamp}] ${clean_line}" >&2
    done
  fi
}

function cleanup() {
  local exit_code=$?
  # Optional: Add local cleanup here if needed
  exit $exit_code
}

# Trap covers ERR, INT, and standard EXIT
trap cleanup ERR INT EXIT

function main() {
  local REMOTE_HOST=""
  local REMOTE_REPO_PATH="${DEFAULT_REMOTE_REPO_PATH}"
  
  # Load environment variables if available
  if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
  fi

  # Build REMOTE_HOST from .env variables if available
  if [[ -n "${REMOTE_USER}" && -n "${REMOTE_IP}" ]]; then
    REMOTE_HOST="${REMOTE_USER}@${REMOTE_IP}"
  else
    REMOTE_HOST="${DEFAULT_REMOTE_HOST}"
  fi

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --host)   REMOTE_HOST="$2"; shift 2 ;;
      --path)   REMOTE_REPO_PATH="$2"; shift 2 ;;
      --debug)  DEBUG=true; shift ;;
      *)        shift ;;
    esac
  done

  # 1. Validation
  if [ ! -d "$LOCAL_DIST_DIR" ]; then
    log "ERRO" "Local dist directory '$LOCAL_DIST_DIR' does not exist."
    log "INFO" "Run 'task build-all' or a specific build task first."
    exit 1
  fi

  shopt -s nullglob
  local deb_files=("$LOCAL_DIST_DIR"/*.deb)
  if [ ${#deb_files[@]} -eq 0 ]; then
    log "WARN" "No .deb files found in $LOCAL_DIST_DIR. Nothing to upload."
    exit 0
  fi

  log "INFO" "Targeting remote host: ${REMOTE_HOST}"

  # 2. Prepare Remote Environment
  log "INFO" "Creating remote temp directory: ${REMOTE_TEMP_DIR}"
  ssh "$REMOTE_HOST" "mkdir -p ${REMOTE_TEMP_DIR}" 2>&1 | log "INFO"

  # 3. Upload
  log "INFO" "Uploading ${#deb_files[@]} .deb file(s) from ${LOCAL_DIST_DIR}..."
  scp "$LOCAL_DIST_DIR"/*.deb "$REMOTE_HOST":"$REMOTE_TEMP_DIR/" 2>&1 | log "INFO"

  # 4. Trigger Import
  log "INFO" "Triggering remote import scripts at ${REMOTE_REPO_PATH}..."
  ssh "$REMOTE_HOST" "
    sudo ${REMOTE_REPO_PATH}/add-debs.sh ${REMOTE_TEMP_DIR}
    sudo ${REMOTE_REPO_PATH}/add-raspi-debs.sh ${REMOTE_TEMP_DIR}
  " 2>&1 | log "INFO"

  # 5. Remote Cleanup
  log "INFO" "Cleaning up remote temp directory..."
  ssh "$REMOTE_HOST" "rm -rf ${REMOTE_TEMP_DIR}" 2>&1 | log "INFO"

  log "SUCC" "Upload and import complete!"
}

main "$@"
