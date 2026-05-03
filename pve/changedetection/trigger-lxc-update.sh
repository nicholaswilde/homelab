#!/usr/bin/env bash
################################################################################
#
# Script Name: trigger-lxc-update.sh
# ----------------
# Orchestration script to trigger remote LXC maintenance.
# Supports multiple Proxmox nodes (amd64/arm64).
#
# @author Nicholas Wilde, 0xb299a622
# @date 02 May 2026
# @version 0.1.2
################################################################################

# Options
set -e
set -o pipefail

# --- Colors ---
RESET='\033[0m'
BLUE='\033[38;5;111m'
YELLOW='\033[38;5;221m'
RED='\033[38;5;203m'

# --- Defaults ---
DEBUG=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVE_USER="root"
PVE_KEY="/root/.ssh/id_pve_automation"
REMOTE_SCRIPT_PATH="/root/git/nicholaswilde/homelab/pve/scripts/lxc-update.sh"

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
  esac
  local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

  if [[ -n "${message}" ]]; then
    echo -e "${color}${type}${RESET}[${timestamp}] ${message}" >&2
  else
    while IFS= read -r line; do
      local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*[mG]//g')
      if [[ "$clean_line" =~ ^(INFO|WARN|ERRO|DEBU|LOGS)\[[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        echo -e "$line" >&2
      else
        echo -e "${color}${type}${RESET}[${timestamp}] ${line}" >&2
      fi
    done
  fi
}

function main() {
  local PVE_IP=""
  
  # Argument parsing
  while [[ $# -gt 0 ]]; do
    case $1 in
      --host)  PVE_IP="$2"; shift 2 ;;
      --debug) DEBUG=true; shift ;;
      *)       shift ;;
    esac
  done

  if [[ -z "$PVE_IP" ]]; then
    log "ERRO" "Usage: $0 --host <ip_address>"
    exit 1
  fi

  # Find the specific .env for this host
  # Expects: .env.192.168.1.66 or defaults to .env
  local TARGET_ENV="${SCRIPT_DIR}/.env.${PVE_IP}"
  [[ ! -f "$TARGET_ENV" ]] && TARGET_ENV="${SCRIPT_DIR}/.env"
  
  log "INFO" "Loading configuration from ${TARGET_ENV}..."
  source "$TARGET_ENV"

  log "INFO" "Triggering maintenance on ${PVE_IP} (Arm64 Node)..."
  
  ssh -i "${PVE_KEY}" -o BatchMode=yes "${PVE_USER}@${PVE_IP}" \
    "bash ${REMOTE_SCRIPT_PATH} --template \"${DEFAULT_TEMPLATE}\"" 2>&1 | log "INFO"

  # Post-update sync
  log "INFO" "Syncing latest template path from ${PVE_IP}..."
  local latest_template=$(ssh -i "${PVE_KEY}" "${PVE_USER}@${PVE_IP}" "ls -t /var/lib/vz/template/cache/debian-*.tar.zst | head -n 1")
  
  if [[ -n "$latest_template" ]]; then
    log "INFO" "Updating ${TARGET_ENV} with: $(basename "$latest_template")"
    sed -i "s|^DEFAULT_TEMPLATE=.*|DEFAULT_TEMPLATE=\"${latest_template}\"|" "$TARGET_ENV"
  fi
}

main "$@"
