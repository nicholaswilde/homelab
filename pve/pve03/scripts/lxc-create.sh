#!/usr/bin/env bash
################################################################################
#
# Script Name: lxc-create.sh
# ----------------
# A helper script for creating Proxmox LXC containers using the 'pct' command.
# Includes an automated cleanup trap for failed deployments.
#
# @author Nicholas Wilde, 0xb299a622
# @date 02 May 2026
# @version 0.1.9
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
ENV_FILE=".env"
DEFAULT_PASS_ENTRY="proxmox/lxc-default-password"
# DEFAULT_TEMPLATE="/var/lib/vz/template/cache/debian-13-standard_13.1-2_amd64.tar.zst"
DEFAULT_TEMPLATE="/var/lib/vz/template/cache/debian-13-standard_13.4-1_amd64.tar.zst"
DEFAULT_STORAGE="local-lvm"
DEFAULT_OSTYPE="debian"
DEFAULT_MEMORY="512"
DEFAULT_CORES="1"
DEFAULT_NET0="name=eth0,bridge=vmbr0,ip=dhcp"
DEFAULT_DNS="192.168.1.88 192.168.1.250"
DEFAULT_PACKAGES="openssh-server micro python3"

# Global variable to track the LXC ID for the cleanup trap
CURRENT_LXC_ID=""

# --- Functions ---

function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi

  case "$type" in
    INFO) color="$BLUE";;
    WARN) color="$YELLOW";;
    ERRO) color="$RED";;
    DEBU) color="$PURPLE";;
    *)    type="LOGS";;
  esac

  local timestamp
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')

  # Use stderr (>&2) to prevent polluting variable captures $(...)
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
  # Only trigger cleanup if an error occurred or script was interrupted
  if [ $exit_code -ne 0 ] && [ -n "$CURRENT_LXC_ID" ]; then
    log "WARN" "Cleanup triggered for LXC ${CURRENT_LXC_ID}..."
    
    # Check if container exists
    if pct status "$CURRENT_LXC_ID" >/dev/null 2>&1; then
      log "INFO" "Stopping and destroying failed LXC ${CURRENT_LXC_ID}..."
      pct stop "$CURRENT_LXC_ID" >/dev/null 2>&1 || true
      pct destroy "$CURRENT_LXC_ID" --purge >/dev/null 2>&1 || true
      log "INFO" "LXC ${CURRENT_LXC_ID} purged."
    fi
  fi
  exit $exit_code
}

# Trap ERR and INT (Ctrl+C) to run cleanup
trap cleanup ERR INT

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  local deps=("curl" "jq" "pass" "pct")
  for dep in "${deps[@]}"; do
    if ! command_exists "$dep"; then
      log "ERRO" "Required tool missing: ${dep}"
      exit 1
    fi
  done
}

function get_next_id() {
  local reserved
  reserved=$(pct list | awk 'NR>1 {print $1}' | sort -n | xargs)
  local next_id=101
  while grep -q -w "$next_id" <<< "$reserved"; do
    ((next_id++))
  done
  echo "$next_id"
}

function get_lxc_ip() {
  local lxc_id="$1"
  local counter=0
  local ip=""
  while [ $counter -lt 10 ]; do
    log "DEBU" "Polling for IP (Attempt $((counter+1)))..."
    ip=$(pct exec "$lxc_id" -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' || true)
    if [[ -n "$ip" ]]; then
      echo "$ip"
      return 0
    fi
    sleep 2
    ((counter++))
  done
  return 1
}

function create_lxc() {
  local lxc_id="$1" hostname="$2" storage="$3" password="$4" template="$5" dns="$6"
  
  CURRENT_LXC_ID="$lxc_id" # Set global for trap

  log "INFO" "Creating LXC ${lxc_id} (${hostname})..."
  pct create "$lxc_id" "$template" \
    --hostname "$hostname" \
    --password "$password" \
    --memory "$DEFAULT_MEMORY" \
    --cores "$DEFAULT_CORES" \
    --net0 "$DEFAULT_NET0" \
    --nameserver "$dns" \
    --storage "$storage" \
    --ostype "$DEFAULT_OSTYPE" \
    --unprivileged 0 \
    --features nesting=1 \
    --start 1 2>&1 | log "INFO"
}

function deploy_and_configure() {
  local lxc_id="$1" hostname="$2" storage="$3" password="$4" template="$5" packages="$6" dns="$7"

  create_lxc "$lxc_id" "$hostname" "$storage" "$password" "$template" "$dns"

  log "INFO" "Configuring network..."
  local ip_cidr
  ip_cidr=$(get_lxc_ip "$lxc_id") || { log "ERRO" "Could not acquire IP."; exit 1; }
  
  local gateway
  gateway=$(pct exec "$lxc_id" -- ip route | grep default | awk '{print $3}' | head -n 1 | tr -d '[:space:]')
  
  log "INFO" "Setting static IP: ${ip_cidr}"
  pct set "$lxc_id" --net0 "name=eth0,bridge=vmbr0,ip=${ip_cidr}${gateway:+,gw=${gateway}}" 2>&1 | log "INFO"
  
  sleep 2

  log "INFO" "Running post-install: ${packages}"
  pct exec "$lxc_id" -- bash -c "apt-get update && apt-get install -y ${packages}" 2>&1 | log "INFO"

  log "INFO" "Updating SSH configuration..."
  pct exec "$lxc_id" -- bash -c "
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    systemctl restart ssh sshd
  " 2>&1 | log "INFO"

  log "INFO" "Deployment finished. IP: ${ip_cidr}"
  CURRENT_LXC_ID="" # Clear global to prevent cleanup on successful exit
}

function main() {
  local HOSTNAME="" LXC_ID="" STORAGE="${DEFAULT_STORAGE}" TEMPLATE="${DEFAULT_TEMPLATE}" PACKAGES="${DEFAULT_PACKAGES}" DNS="${DEFAULT_DNS}"

  [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
  check_dependencies

  while [[ $# -gt 0 ]]; do
    case $1 in
      --id) LXC_ID="$2"; shift 2 ;;
      --storage) STORAGE="$2"; shift 2 ;;
      --template) TEMPLATE="$2"; shift 2 ;;
      --packages) PACKAGES="$2"; shift 2 ;;
      --dns) DNS="$2"; shift 2 ;;
      --debug) DEBUG=true; shift ;;
      *) HOSTNAME="$1"; shift ;;
    esac
  done

  [[ -z "$HOSTNAME" ]] && { log "ERRO" "Hostname missing."; exit 1; }

  LXC_ID="${LXC_ID:-$(get_next_id)}"
  local ROOT_PASSWORD
  ROOT_PASSWORD=$(pass show "$DEFAULT_PASS_ENTRY" | head -n 1)

  deploy_and_configure "$LXC_ID" "$HOSTNAME" "$STORAGE" "$ROOT_PASSWORD" "$TEMPLATE" "$PACKAGES" "$DNS"
}

main "$@"
