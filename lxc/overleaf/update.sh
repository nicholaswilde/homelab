#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Updates the Overleaf Toolkit installation and runs bin/upgrade.
#
# @author Nicholas Wilde, 0xb299a622
# @date 06 Jun 2026
# @version 1.0.0
#
################################################################################

# Options
set -e
set -o pipefail

# Constants
readonly BLUE="\033[38;2;137;180;250m"
readonly RED="\033[38;2;243;139;168m"
readonly YELLOW="\033[38;2;249;226;175m"
readonly PURPLE="\033[38;2;203;166;247m"
readonly RESET="\033[0m"

readonly INSTALL_DIR="/opt/overleaf"

# Logging function
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  case "$type" in
    INFO) color="$BLUE";;
    WARN) color="$YELLOW";;
    ERRO) color="$RED";;
    DEBU) color="$PURPLE";;
  esac

  local timestamp
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')

  if [[ -n "${message}" ]]; then
    echo -e "${color}${type}${RESET}[${timestamp}] ${message}"
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[${timestamp}] ${line}"
    done
  fi
}

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! command_exists docker; then
    log "ERRO" "Docker is not installed." >&2
    exit 1
  fi
}

function main() {
  log "INFO" "Starting Overleaf update..."
  check_dependencies

  if [ ! -d "${INSTALL_DIR}" ]; then
    log "ERRO" "Overleaf installation directory not found at ${INSTALL_DIR}."
    exit 1
  fi

  log "INFO" "Pulling latest changes for Overleaf Toolkit..."
  git -C "${INSTALL_DIR}" pull origin master

  log "INFO" "Running Overleaf upgrade script..."
  cd "${INSTALL_DIR}"
  ./bin/upgrade

  log "INFO" "Overleaf update completed successfully."
}

main "$@"
