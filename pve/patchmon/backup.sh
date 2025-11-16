#!/usr/bin/env bash
################################################################################
#
# Script Name: backup.sh
# ----------------
# This script backs up a Redis database by triggering a BGSAVE, waits for it
# to complete, and then encrypts the dump file using SOPS.
#
# @author Nicholas Wilde, 0xb299a622
# @date 16 Nov 2025
# @version 1.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# These are constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly PURPLE=$(tput setaf 5)
readonly RESET=$(tput sgr0)
DEBUG="false"

# Logging function
function log() {
  local type="$1"
  local color="$RESET"

  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi

  case "$type" in
    INFO)
      color="$BLUE";;
    WARN)
      color="$YELLOW";;
    ERRO)
      color="$RED";;
    DEBU)
      color="$PURPLE";;
    *)
      type="LOGS";;
  esac
  if [[ -t 0 ]]; then
    local message="$2"
    echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${line}"
    done
  fi
}

# Checks if a command exists.
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! command_exists redis-cli; then
    log "ERRO" "Required dependency 'redis-cli' is not installed." >&2
    exit 1
  fi
  if ! command_exists sops; then
    log "ERRO" "Required dependency 'sops' is not installed." >&2
    exit 1
  fi
}

function get_redis_config() {
  log "INFO" "Fetching Redis database directory and filename..."
  local redis_dir
  redis_dir=$(redis-cli CONFIG GET dir | sed -n '2p')
  local redis_dbfilename
  redis_dbfilename=$(redis-cli CONFIG GET dbfilename | sed -n '2p')
  REDIS_DUMP_FILE="${redis_dir}/${redis_dbfilename}"
  log "INFO" "Redis data is stored in: ${REDIS_DUMP_FILE}"
}

function wait_for_persistence() {
  while [[ $(redis-cli INFO persistence | grep 'rdb_bgsave_in_progress:1') ]]; do
    log "WARN" "A BGSAVE operation is already in progress. Waiting..."
    sleep 5
  done
  while [[ $(redis-cli INFO persistence | grep 'aof_rewrite_in_progress:1') ]]; do
    log "WARN" "An AOF rewrite operation is already in progress. Waiting..."
    sleep 5
  done
}

function ensure_initial_dump_exists() {
  if [[ ! -f "$REDIS_DUMP_FILE" ]]; then
    log "WARN" "Redis dump file not found at ${REDIS_DUMP_FILE}. Attempting to save."
    wait_for_persistence
    redis-cli SAVE
    if [ $? -ne 0 ]; then
      log "ERRO" "Initial SAVE command failed."
      exit 1
    fi
    if [[ ! -f "$REDIS_DUMP_FILE" ]]; then
      log "ERRO" "Redis dump file could not be created at ${REDIS_DUMP_FILE}."
      exit 1
    fi
  fi
}

function trigger_bgsave() {
  log "INFO" "Initiating BGSAVE..."
  INITIAL_LASTSAVE=$(redis-cli LASTSAVE)
  log "INFO" "Initial LASTSAVE timestamp: ${INITIAL_LASTSAVE}"

  local bgsave_output
  bgsave_output=$(redis-cli BGSAVE)
  if [[ "$bgsave_output" != "Background saving started" ]]; then
    log "ERRO" "Failed to start BGSAVE: $bgsave_output"
    exit 1
  fi
}

function wait_for_bgsave_completion() {
  log "INFO" "Waiting for BGSAVE to complete..."
  while true; do
    local current_lastsave
    current_lastsave=$(redis-cli LASTSAVE)
    if [[ "$current_lastsave" -gt "$INITIAL_LASTSAVE" ]]; then
      log "INFO" "BGSAVE completed. New LASTSAVE timestamp: ${current_lastsave}"
      break
    fi
    log "DEBU" "Still waiting for BGSAVE... (current: ${current_lastsave}, initial: ${INITIAL_LASTSAVE})"
    sleep 1
  done
}

function verify_bgsave_status() {
  if [[ $(redis-cli INFO persistence | grep 'rdb_last_bgsave_status:ok') ]]; then
    log "INFO" "BGSAVE was successful."
  else
    log "ERRO" "BGSAVE failed. Check Redis logs for more information."
    exit 1
  fi
}

function encrypt_and_cleanup() {
  local encrypted_dump_file="${REDIS_DUMP_FILE}.enc"
  log "INFO" "Encrypting ${REDIS_DUMP_FILE} to ${encrypted_dump_file} using sops..."

  sops --encrypt "${REDIS_DUMP_FILE}" > "${encrypted_dump_file}"
  if [ $? -ne 0 ]; then
    log "ERRO" "SOPS encryption failed."
    exit 1
  fi

  log "INFO" "Encryption complete."
  log "INFO" "Removing unencrypted dump file..."
  rm "${REDIS_DUMP_FILE}"
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting Redis backup script..."
  check_dependencies

  get_redis_config
  ensure_initial_dump_exists
  
  wait_for_persistence
  trigger_bgsave
  wait_for_bgsave_completion
  verify_bgsave_status
  
  encrypt_and_cleanup

  log "INFO" "Backup script finished successfully."
}

# Call main to start the script
main "$@"
