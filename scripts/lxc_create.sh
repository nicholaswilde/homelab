#!/usr/bin/env bash
# Name: lxc_create.sh
# Description: Automate Proxmox LXC creation and post-setup.
# Author: Gemini CLI
# Date: 2026-03-21
# Version: 1.0.0

set -e
set -o pipefail

# Catppuccin Mocha Colors
BLUE='\033[38;2;137;180;250m'
RED='\033[38;2;243;139;168m'
GREEN='\033[38;2;166;227;161m'
YELLOW='\033[38;2;249;226;175m'
RESET='\033[0m'

function log() {
  local level=$1
  local msg=$2
  local color=$RESET
  case $level in
    "INFO") color=$BLUE ;;
    "WARN") color=$YELLOW ;;
    "ERRO") color=$RED ;;
    "DEBU") color=$GREEN ;;
  esac
  echo -e "${color}${level}${RESET}: ${msg}"
}

function get_nodes() {
  # Mock nodes for now. In reality, would use 'pvecm nodes' or MCP.
  echo "pve01 pve03 pve04"
}

function detect_arch() {
  local node=$1
  case "$node" in
    "pve01"|"pve03") echo "x86_64" ;;
    "pve04") echo "aarch64" ;;
    *) echo "unknown" ;;
  esac
}

function generate_command() {
  local vmid=$1
  local hostname=$2
  local template=$3
  local bridge=$4
  local ip=$5
  local gw=$6
  echo "pct create $vmid $template --hostname=$hostname --net0 name=eth0,bridge=$bridge,ip=$ip,gw=$gw,ip6=slaac --features nesting=1 --unprivileged 0"
}

function generate_setup() {
  local vmid=$1
  echo "pct exec $vmid -- apt update"
  echo "pct exec $vmid -- apt upgrade -y"
  echo "pct exec $vmid -- apt install -y curl vim git htop sudo"
  echo "pct exec $vmid -- useradd -m -s /bin/bash nicholas"
  echo "pct exec $vmid -- tee /etc/sudoers.d/nicholas <<EOF
nicholas ALL=(ALL) NOPASSWD:ALL
EOF"
}

function interactive_create() {
  log "INFO" "Interactive LXC Creation"
  
  local nodes=$(get_nodes)
  echo "Available nodes: $nodes"
  read -p "Select node: " node
  
  local arch=$(detect_arch "$node")
  log "INFO" "Detected architecture for $node: $arch"
  
  read -p "Enter VMID: " vmid
  read -p "Enter Hostname: " hostname
  
  # Default template based on arch
  local template="debian-12-standard_12.0-1_amd64.tar.zst"
  if [ "$arch" == "aarch64" ]; then
    template="debian-12-standard_12.0-1_arm64.tar.zst"
  fi
  read -p "Template [$template]: " input_template
  template=${input_template:-$template}
  
  read -p "Bridge [vmbr0]: " bridge
  bridge=${bridge:-vmbr0}
  
  read -p "IP (e.g., 192.168.1.10/24): " ip
  read -p "Gateway: " gw
  
  local password=$(pass show default-lxc-password)
  
  local cmd=$(generate_command "$vmid" "$hostname" "$template" "$bridge" "$ip" "$gw")
  log "INFO" "Creation command: $cmd"
  
  # In a real environment, we'd execute:
  # $cmd --password "$password"
  
  local setup_cmds=$(generate_setup "$vmid")
  log "INFO" "Post-setup commands generated."
  # In a real environment, we'd execute setup_cmds
}

function main() {
  case "$1" in
    "--list-nodes")
      get_nodes | tr ' ' '\n'
      ;;
    "--detect-arch")
      detect_arch "$2"
      ;;
    "--generate-command")
      generate_command "$2" "$3" "$4" "$5" "$6" "$7"
      ;;
    "--generate-setup")
      generate_setup "$2"
      ;;
    *)
      interactive_create
      ;;
  esac
}

main "$@"
