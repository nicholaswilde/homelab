#!/usr/bin/env bash
################################################################################
#
# Script Name: create-crontab.sh
# ----------------
# Creates a daily crontab job to run the frame-fi download script.
#
# @author Nicholas Wilde, 0xb299a622
# @date 29 Aug 2025
# @version 0.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# These are constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly RESET=$(tput sgr0)

# Logging function
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  case "$type" in
    INFO)
      color="$BLUE";;
    WARN)
      color="$YELLOW";;
    ERRO)
      color="$RED";;
  esac

  echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
}

# Checks if a command exists.
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  log "INFO" "Checking for required dependencies..."
  if ! command_exists crontab; then
    log "ERRO" "Required dependency 'crontab' is not installed. Please install cron to proceed." >&2
    exit 1
  fi
  log "INFO" "All dependencies found."
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting crontab creation script..."
  check_dependencies

  local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  local DOWNLOAD_SCRIPT="${SCRIPT_DIR}/download.sh"
  local CRON_JOB="0 3 * * * /bin/bash -c "cd ${SCRIPT_DIR} && ${DOWNLOAD_SCRIPT}""

  log "INFO" "Adding cron job: ${CRON_JOB}"

  # Add the cron job, ensuring it's not duplicated
  (crontab -l 2>/dev/null | grep -v -F "${DOWNLOAD_SCRIPT}" ; echo "${CRON_JOB}") | crontab -
  
  log "INFO" "Crontab job created successfully. To verify, run 'crontab -l'."
  log "INFO" "Crontab creation script finished."
}

# Call main to start the script
main "@"
