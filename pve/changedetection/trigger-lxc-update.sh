#!/usr/bin/env bash
################################################################################
#
# Script Name: trigger-lxc-update.sh
# ----------------
# Orchestration script for privileged containers to trigger remote LXC 
# maintenance on a Proxmox node via SSH.
#
# @author Nicholas Wilde, 0xb299a622
# @date 02 May 2026
# @version 0.1.0
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
PURPLE='\033[38;5;176m'

# --- Configuration & Defaults ---
DEBUG=false
# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
PVE_IP="192.168.1.141"
PVE_USER="root"
PVE_KEY="/root/.ssh/id_pve_automation"
REMOTE_SCRIPT_PATH="/root/git/nicholaswilde/homelab/pve/pve03/scripts/lxc-update.sh"

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
    DEBU) color="$PURPLE";;
    *)    type="LOGS";;
  esac

  local timestamp
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')

  if [[ -n "${message}" ]]; then
    echo -e "${color}${type}${RESET}[${timestamp}] ${message}" >&2
  else
    while IFS= read -r line; do
      # 1. Strip ANSI colors to create a plain text version for checking
      local clean_line
      clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*[mG]//g')

      # 2. Check if the clean line starts with the log pattern
      if [[ "$clean_line" =~ ^(INFO|WARN|ERRO|DEBU|LOGS)\[[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        # Remote log detected: Print original colored line exactly as received
        echo -e "$line" >&2
      else
        # Raw output: Wrap in local timestamp and level
        echo -e "${color}${type}${RESET}[${timestamp}] ${line}" >&2
      fi
    done
  fi
}

function check_connection() {
  log "DEBU" "Testing SSH connection to ${PVE_IP}..."
  ssh -i "${PVE_KEY}" -o BatchMode=yes -o ConnectTimeout=5 "${PVE_USER}@${PVE_IP}" "true" 2>/dev/null || return 1
}

function sync_env_from_remote() {
  log "INFO" "Syncing latest template path from remote node..."
  
  # Get the absolute path of the newest template from the Proxmox node
  local latest_template
  latest_template=$(ssh -i "${PVE_KEY}" "${PVE_USER}@${PVE_IP}" "ls -t /var/lib/vz/template/cache/debian-*.tar.zst | head -n 1")
  
  if [[ -n "$latest_template" && -f "$ENV_FILE" ]]; then
    log "INFO" "Updating local ${ENV_FILE} with: $(basename "$latest_template")"
    sed -i "s|^DEFAULT_TEMPLATE=.*|DEFAULT_TEMPLATE=\"${latest_template}\"|" "$ENV_FILE"
  fi
}

function main() {
  # Load local environment if it exists
  [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

  # Argument parsing
  while [[ $# -gt 0 ]]; do
    case $1 in
      --debug) DEBUG=true; shift ;;
      *) shift ;;
    esac
  done

  # 1. Validate Connection
  if ! check_connection; then
    log "ERRO" "Unable to connect to Proxmox host at ${PVE_IP}. Check SSH keys/Network."
    exit 1
  fi

  # 2. Trigger Remote Script
  log "INFO" "Triggering remote LXC update on ${PVE_IP}..."
  
  # We pass the current DEFAULT_TEMPLATE from our local .env to the remote script
  ssh -i "${PVE_KEY}" -o BatchMode=yes "${PVE_USER}@${PVE_IP}" \
    "bash ${REMOTE_SCRIPT_PATH} --template \"${DEFAULT_TEMPLATE}\"" 2>&1 | log "INFO"

  # 3. Post-Update Sync
  sync_env_from_remote

  log "INFO" "Remote orchestration complete."
}

main "$@"
