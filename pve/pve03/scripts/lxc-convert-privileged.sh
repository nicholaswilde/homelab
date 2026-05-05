#!/usr/bin/env bash
################################################################################
#
# Script Name: lxc-convert-privileged.sh
# ----------------
# Converts an LXC container from unprivileged to privileged.
# Uses backup/restore to ensure correct UID/GID mapping.
#
# @author Nicholas Wilde, 0xb299a622
# @date 03 May 2026
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
STORAGE_BACKUP="local"
STORAGE_TARGET="local-lvm"

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
      echo -e "${color}${type}${RESET}[${timestamp}] ${line}" >&2
    done
  fi
}

function pre_flight_check() {
  local vmid="$1"
  
  log "INFO" "Performing pre-flight check for VMID ${vmid}..."

  # Check if ID exists and is an LXC using Proxmox native tools
  if ! pct config "$vmid" >/dev/null 2>&1; then
    log "ERRO" "ID ${vmid} is not a valid LXC on this node."
    return 1
  fi

  log "INFO" "Pre-flight check passed: ID ${vmid} is a valid LXC."
  return 0
}

function convert_container() {
  local vmid="$1"
  
  # 1. Stop container
  log "INFO" "Stopping container ${vmid}..."
  pct stop "$vmid" 2>/dev/null || log "WARN" "Container already stopped or busy."

  # 2. Create Backup
  log "INFO" "Creating temporary backup on ${STORAGE_BACKUP}..."
  vzdump "$vmid" --storage "$STORAGE_BACKUP" --compress zstd --mode stop 2>&1 | log "INFO"

  # 3. Locate Backup File
  local backup_file
  backup_file=$(ls -t /var/lib/vz/dump/vzdump-lxc-"$vmid"-*.tar.zst 2>/dev/null | head -n 1)
  
  if [[ ! -f "$backup_file" ]]; then
    log "ERRO" "Backup file could not be located in /var/lib/vz/dump/"
    return 1
  fi
  log "INFO" "Backup created: $(basename "${backup_file}")"

  # 4. Destroy Old Container
  log "WARN" "Destroying unprivileged container ${vmid}..."
  pct destroy "$vmid"

  # 5. Restore as Privileged
  log "INFO" "Restoring ${vmid} as PRIVILEGED to ${STORAGE_TARGET}..."
  if pct restore "$vmid" "$backup_file" --storage "$STORAGE_TARGET" --ignore-unpack-errors 1 2>&1 | log "INFO"; then
    # Force config update to ensure privileged status
    sed -i 's/unprivileged: 1/unprivileged: 0/' /etc/pve/lxc/"$vmid".conf
    log "INFO" "Successfully converted ${vmid} to privileged."
    
    # Cleanup
    log "INFO" "Cleaning up temporary backup..."
    rm -f "$backup_file"
  else
    log "ERRO" "Restore failed for ${vmid}. Backup remains at ${backup_file}"
    return 1
  fi
}

function main() {
  local VMID=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      --vmid)    VMID="$2"; shift 2 ;;
      --storage) STORAGE_TARGET="$2"; shift 2 ;;
      --debug)   DEBUG=true; shift ;;
      *)         shift ;;
    esac
  done

  if [[ -z "$VMID" ]]; then
    log "ERRO" "Usage: $0 --vmid <vmid> [--storage <target_storage>]"
    exit 1
  fi

  # Run Pre-flight
  if ! pre_flight_check "$VMID"; then
    exit 1
  fi

  log "INFO" "Starting conversion workflow..."
  
  if convert_container "$VMID"; then
    log "INFO" "Workflow complete for CT ${VMID}."
  else
    log "ERRO" "Conversion workflow failed."
    exit 1
  fi
}

main "$@"
