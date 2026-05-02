#!/usr/bin/env bash
################################################################################
#
# Script Name: lxc-update.sh
# ----------------
# Creates a temporary LXC, updates it, and exports it as a new template.
# Dynamic versioning and architecture detection (amd64/arm64).
#
# @author Nicholas Wilde, 0xb299a622
# @date 02 May 2026
# @version 0.1.6
#
################################################################################

# Options
set -e
set -o pipefail

# --- Colors ---
RESET='\033[0m'
BLUE='\033[38;5;111m'
YELLOW='\033[38;5;221m'
RED='\033[38;5;203m'

# --- Configuration ---
ENV_FILE=".env"
DEFAULT_STORAGE="local-lvm"
DEFAULT_TEMPLATE_DIR="/var/lib/vz/template/cache"

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
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[${timestamp}] ${line}" >&2
    done
  fi
}

function cleanup() {
  local exit_code=$?
  if [ $exit_code -ne 0 ] && [ -n "$CURRENT_LXC_ID" ]; then
    log "WARN" "Error detected. Purging temporary LXC ${CURRENT_LXC_ID}..."
    pct stop "$CURRENT_LXC_ID" 2>&1 | log "INFO" || true
    pct destroy "$CURRENT_LXC_ID" --purge 2>&1 | log "INFO" || true
  fi
  exit $exit_code
}

trap cleanup ERR INT

function get_next_id() {
  local next_id=999
  while pct status "$next_id" >/dev/null 2>&1; do ((next_id++)); done
  echo "$next_id"
}

function get_os_metadata() {
  local lxc_id="$1"
  # Pull ID, precise version, and the native architecture
  pct exec "$lxc_id" -- bash -c 'source /etc/os-release && echo "${ID} $(cat /etc/debian_version) $(dpkg --print-architecture)"'
}

function refresh_storage() {
  log "INFO" "Refreshing Proxmox storage index..."
  pvesh set /nodes/$(hostname)/storage/local/content 2>&1 | log "INFO" || true
}

function create_new_template() {
  local lxc_id="$1"
  
  local metadata
  metadata=$(get_os_metadata "$lxc_id")
  local os_id
  os_id=$(echo "$metadata" | awk '{print $1}')
  local os_ver
  os_ver=$(echo "$metadata" | awk '{print $2}')
  local os_arch
  os_arch=$(echo "$metadata" | awk '{print $3}')
  
  local major_ver="${os_ver%%.*}"
  local instance=1
  local new_filename
  local new_path
  
  # Construction: debian-13-standard_13.4-1_arm64.tar.zst
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
  
  local dump_file
  dump_file=$(ls -t "${DEFAULT_TEMPLATE_DIR}/vzdump-lxc-${lxc_id}-"*.tar.zst | head -n 1)
  local log_file
  log_file=$(ls -t "${DEFAULT_TEMPLATE_DIR}/vzdump-lxc-${lxc_id}-"*.log | head -n 1)
  
  mv "$dump_file" "$new_path" 2>&1 | log "INFO"
  [[ -f "$log_file" ]] && rm -f "$log_file" 2>&1 | log "INFO"

  log "INFO" "New template successfully created at: ${new_path}"
  refresh_storage
}

function main() {
  local BASE_TEMPLATE=""
  local STORAGE="${DEFAULT_STORAGE}"
  
  [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

  while [[ $# -gt 0 ]]; do
    case $1 in
      --template) BASE_TEMPLATE="$2"; shift 2 ;;
      --storage)  STORAGE="$2"; shift 2 ;;
      *)          shift ;;
    esac
  done

  if [[ -z "$BASE_TEMPLATE" ]]; then
    log "ERRO" "Usage: $0 --template <path>"
    exit 1
  fi

  CURRENT_LXC_ID=$(get_next_id)
  
  log "INFO" "Provisioning builder ID: ${CURRENT_LXC_ID}"
  pct create "$CURRENT_LXC_ID" "$BASE_TEMPLATE" \
    --hostname "template-builder" \
    --storage "$STORAGE" \
    --password "temp-pass-$(date +%s)" \
    --net0 "name=eth0,bridge=vmbr0,ip=dhcp" \
    --unprivileged 0 \
    --start 1 2>&1 | log "INFO"

  log "INFO" "Waiting for network..."
  sleep 5

  log "INFO" "Updating and cleaning system..."
  pct exec "$CURRENT_LXC_ID" -- bash -c "
    apt-get update && apt-get dist-upgrade -y && apt-get autoremove -y && apt-get clean
    rm -rf /var/lib/apt/lists/*
    rm -f /etc/ssh/ssh_host_*
    truncate -s 0 /etc/machine-id
    rm -f /var/lib/dbus/machine-id
  " 2>&1 | log "INFO"

  create_new_template "$CURRENT_LXC_ID"

  log "INFO" "Purging builder..."
  pct destroy "$CURRENT_LXC_ID" --purge 2>&1 | log "INFO"
  
  log "INFO" "Maintenance complete."
  CURRENT_LXC_ID=""
}

main "$@"
