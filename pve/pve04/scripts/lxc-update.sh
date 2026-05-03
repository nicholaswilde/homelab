#!/usr/bin/env bash
################################################################################
#
# Script Name: lxc-update.sh
# ----------------
# Creates a temporary LXC, updates it, and exports it as a new template.
# Includes lock file management and automated .env updates.
#
# @author Nicholas Wilde, 0xb299a622
# @date 02 May 2026
# @version 0.1.8
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

# --- Configuration ---
ENV_FILE=".env"
DEFAULT_STORAGE="local-lvm"
DEFAULT_TEMPLATE_DIR="/var/lib/vz/template/cache"
LOCKFILE="/tmp/lxc-update.lock"

UPDATE_SUCCESS="false"
UPDATE_MESSAGES=()
# Variables below should be defined in your .env file
ENABLE_NOTIFICATIONS="${ENABLE_NOTIFICATIONS:-false}"
MAILRISE_URL="${MAILRISE_URL:-}"
MAILRISE_FROM="${MAILRISE_FROM:-}"
MAILRISE_RCPT="${MAILRISE_RCPT:-}"

# Global tracking
CURRENT_LXC_ID=""

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
  local timestamp
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')
  
  if [[ -n "${message}" ]]; then
    echo -e "${color}${type}${RESET}[${timestamp}] ${message}" >&2
    # Store important logs for the email body
    UPDATE_MESSAGES+=("${type}: ${message}")
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[${timestamp}] ${line}" >&2
    done
  fi
}

function send_notification(){
  if [[ "${ENABLE_NOTIFICATIONS}" == "false" ]]; then
    return 0
  fi
  if [[ -z "${MAILRISE_URL}" || -z "${MAILRISE_FROM}" || -z "${MAILRISE_RCPT}" ]]; then
    log "WARN" "Notification variables not set. Skipping."
    return 1
  fi

  local EMAIL_SUBJECT="Homelab - Update Summary ($(hostname))"
  local EMAIL_BODY

  if [[ "${UPDATE_SUCCESS}" == "true" ]]; then
    EMAIL_BODY="LXC Template update completed successfully."
  else
    EMAIL_BODY="LXC Template update encountered errors."
  fi

  if [ ${#UPDATE_MESSAGES[@]} -gt 0 ]; then
    EMAIL_BODY+=$'\n\nUpdate details:\n'
    for msg in "${UPDATE_MESSAGES[@]}"; do
      EMAIL_BODY+="- ${msg}"$'\n'
    done
  fi

  log "INFO" "Sending Mailrise notification..."
  # Added --connect-timeout and || true to prevent script crash
  curl -s --connect-timeout 5 \
    --url "${MAILRISE_URL}" \
    --mail-from "${MAILRISE_FROM}" \
    --mail-rcpt "${MAILRISE_RCPT}" \
    --upload-file - <<EOF || log "WARN" "Mailrise notification failed to send."
From: Proxmox Automation <${MAILRISE_FROM}>
To: Nicholas Wilde <${MAILRISE_RCPT}>
Subject: ${EMAIL_SUBJECT}

${EMAIL_BODY}
EOF
}

function cleanup() {
  local exit_code=$?
  
  # Remove our local script lock
  if [[ -f "$LOCKFILE" ]]; then rm -f "$LOCKFILE"; fi
  
  # If the script failed and a builder ID exists, purge it
  if [[ $exit_code -ne 0 ]]; then
    if [[ -n "$CURRENT_LXC_ID" ]]; then
      log "WARN" "Script interrupted or failed. Cleaning up builder ${CURRENT_LXC_ID}..."
      # Use --purge to ensure the config and disk are gone
      pct destroy "$CURRENT_LXC_ID" --purge >/dev/null 2>&1 || true
    fi
    
    # Ensure a failure notification is sent if main didn't finish
    if [[ "${UPDATE_SUCCESS}" == "false" ]]; then
      send_notification
    fi
  fi
  
  exit $exit_code
}

# Trap covers ERR, INT, and standard EXIT to ensure lock file removal
trap cleanup ERR INT EXIT

function get_next_id() {
  local next_id=999
  while pct status "$next_id" >/dev/null 2>&1; do ((next_id++)); done
  echo "$next_id"
}

function get_os_metadata() {
  local lxc_id="$1"
  pct exec "$lxc_id" -- bash -c 'source /etc/os-release && echo "${ID} $(cat /etc/debian_version) $(dpkg --print-architecture)"'
}

function refresh_storage() {
  log "INFO" "Refreshing Proxmox storage index..."
  # 'get' is safer for refreshing the index than 'set' in some PVE versions
  pvesh get /nodes/$(hostname)/storage/local/content >/dev/null 2>&1 || true
}

function create_new_template() {
  local lxc_id="$1"
  
  local metadata
  metadata=$(get_os_metadata "$lxc_id")
  local os_id=$(echo "$metadata" | awk '{print $1}')
  local os_ver=$(echo "$metadata" | awk '{print $2}')
  local os_arch=$(echo "$metadata" | awk '{print $3}')
  
  local major_ver="${os_ver%%.*}"
  local instance=1
  local new_filename
  local new_path
  
  while true; do
    new_filename="${os_id}-${major_ver}-standard_${os_ver}-${instance}_${os_arch}.tar.zst"
    new_path="${DEFAULT_TEMPLATE_DIR}/${new_filename}"
    if [[ ! -f "$new_path" ]]; then
      break
    fi
    log "WARN" "Instance ${instance} exists. Incrementing..."
    ((instance++))
  done

  log "INFO" "Stopping container..."
  pct stop "$lxc_id" 2>&1 | log "INFO"

  log "INFO" "Exporting to: ${new_filename}"
  vzdump "$lxc_id" --compress zstd --dumpdir "${DEFAULT_TEMPLATE_DIR}" --mode stop 2>&1 | log "INFO"
  
  local dump_file=$(ls -t "${DEFAULT_TEMPLATE_DIR}/vzdump-lxc-${lxc_id}-"*.tar.zst | head -n 1)
  local log_file=$(ls -t "${DEFAULT_TEMPLATE_DIR}/vzdump-lxc-${lxc_id}-"*.log | head -n 1)
  
  mv "$dump_file" "$new_path" 2>&1 | log "INFO"
  [[ -f "$log_file" ]] && rm -f "$log_file" 2>&1 | log "INFO"

  log "INFO" "New template successfully created at: ${new_path}"

  # Update the .env file with the newest template path
  if [[ -f "$ENV_FILE" ]]; then
    log "INFO" "Updating ${ENV_FILE} with the new template path..."
    # Use | as delimiter to avoid escaping forward slashes
    sed -i "s|^DEFAULT_TEMPLATE=.*|DEFAULT_TEMPLATE=\"${new_path}\"|" "$ENV_FILE"
  fi

  refresh_storage
}

# --- Sub-Functions ---

function validate_environment() {
  [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

  if [[ -z "$BASE_TEMPLATE" ]]; then
    log "ERRO" "No base template provided. Usage: $0 --template <path>"
    exit 1
  fi

  if [[ ! -f "$BASE_TEMPLATE" ]]; then
    log "ERRO" "Source template not found: ${BASE_TEMPLATE}"
    exit 1
  fi
}

function check_locks() {
  # 1. Script-level lock (our own)
  if [[ -f "$LOCKFILE" ]]; then
    log "WARN" "An update is already in progress (Lock: $LOCKFILE). Exiting."
    exit 0
  fi

  # 2. Proxmox system-wide lock check
  # We try to acquire a non-blocking shared lock. 
  # If it fails, something else (vzdump) has an exclusive lock.
  if [[ -f "/var/run/vzdump.lock" ]]; then
    if ! flock -n /var/run/vzdump.lock -c "true" 2>/dev/null; then
      local locking_pid
      locking_pid=$(fuser /var/run/vzdump.lock 2>/dev/null | awk '{print $NF}')

      local process_info="Unknown vzdump task"
      if [[ -n "$locking_pid" && -d "/proc/${locking_pid}" ]]; then
        local raw_cmd=$(tr '\0' ' ' < "/proc/${locking_pid}/cmdline" | xargs)
        local task_user=$(echo "$raw_cmd" | awk -F: '{print $NF}')
        process_info="Active Backup Job (User: ${task_user:-root})"
      fi

      log "WARN" "Proxmox host is busy: ${process_info}"
      log "WARN" "Skipping template update to avoid backup collision."
      
      UPDATE_SUCCESS="true"
      send_notification
      exit 0
    else
      log "INFO" "vzdump.lock file exists but is not held by any process. Proceeding..."
    fi
  fi
}

function provision_builder() {
  CURRENT_LXC_ID=$(get_next_id)
  log "INFO" "Provisioning builder ID: ${CURRENT_LXC_ID}"
  
  pct create "$CURRENT_LXC_ID" "$BASE_TEMPLATE" \
    --hostname "template-builder" \
    --storage "$STORAGE" \
    --password "temp-pass-$(date +%s)" \
    --net0 "name=eth0,bridge=vmbr0,ip=dhcp" \
    --unprivileged 0 \
    --start 1 2>&1 | log "INFO"

  log "INFO" "Waiting for network (5s)..."
  sleep 5
}

function run_updates_and_sanitization() {
  log "INFO" "Running system updates and sanitization..."
  pct exec "$CURRENT_LXC_ID" -- bash -c "
    apt-get update && apt-get dist-upgrade -y && apt-get autoremove -y && apt-get clean
    rm -rf /var/lib/apt/lists/*
    rm -f /etc/ssh/ssh_host_*
    truncate -s 0 /etc/machine-id
    rm -f /var/lib/dbus/machine-id
    truncate -s 0 /root/.bash_history
  " 2>&1 | log "INFO"
}

function finalize_and_cleanup() {
  create_new_template "$CURRENT_LXC_ID"

  log "INFO" "Purging builder..."
  pct destroy "$CURRENT_LXC_ID" --purge 2>&1 | log "INFO"

  UPDATE_SUCCESS="true"
  log "INFO" "Maintenance complete successfully."
  send_notification
  
  CURRENT_LXC_ID=""
}

function main() {
  # 1. Setup local variables
  local BASE_TEMPLATE=""
  local STORAGE="${DEFAULT_STORAGE}"

  # 2. Parse Arguments (Must happen before validation)
  while [[ $# -gt 0 ]]; do
    case $1 in
      --template) BASE_TEMPLATE="$2"; shift 2 ;;
      --storage)  STORAGE="$2"; shift 2 ;;
      --debug)    DEBUG=true; shift ;;
      *)          shift ;;
    esac
  done

  # 3. Logic Flow
  validate_environment      # Load .env and check template existence
  # check_locks               # Check for script and system locks
  
  touch "$LOCKFILE"         # Acquire script lock
  
  provision_builder         # Create and start the temporary LXC
  run_updates_and_sanitization # Apt upgrade and cleanup
  finalize_and_cleanup      # Export template and destroy LXC
}

main "$@"
