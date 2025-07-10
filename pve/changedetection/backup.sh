#!/usr/bin/env bash
################################################################################
#
# backup_changedetection.sh
# ----------------
# This script creates a zip archive of the /opt/changedetection directory,
# excluding any zip files within it. The backup file is saved in the current
# working directory.
#
# @author Nicholas Wilde
# @date 10 jul 2025
# @version 0.5.0
#
################################################################################

# Options
set -e
set -o pipefail

# These are constants
BLUE=$(tput setaf 4)
readonly BLUE
RED=$(tput setaf 1)
readonly RED
YELLOW=$(tput setaf 3)
readonly YELLOW
RESET=$(tput sgr0)
readonly RESET

# Backup directory
BACKUP_DIR="${HOME}/backups/changedetection"
INSTALL_DIR="/opt/changedetection"

# Logging function
function log() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  case "${level}" in
    "ERRO")
      echo -e "${RED}${level}[${timestamp}] ${message}${RESET}"
      ;;
    "INFO")
      echo -e "${BLUE}${level}[${timestamp}] ${message}${RESET}"
      ;;
    "WARN")
      echo -e "${YELLOW}${level}[${timestamp}] ${message}${RESET}"
      ;;
    *)
      echo "${level}[${timestamp}] ${message}"
      ;;
  esac
}

# This function loads the .env file
function load_env() {
    local env_file
    env_file="$(dirname "$0")/.env"
    if [ -f "${env_file}" ]; then
        log "INFO" "Loading .env file from ${env_file}"
        set -o allexport
        # shellcheck source=/dev/null
        source "${env_file}"
        set +o allexport
    else
        log "WARN" ".env file not found at ${env_file}. Using default INSTALL_DIR."
    fi
}

# This function checks for required dependencies.
function check_dependencies() {
  if ! command -v zip &> /dev/null; then
    log "ERRO" "zip command not found. Please install zip."
    exit 1
  fi
  if ! command -v tput &> /dev/null; then
    log "ERRO" "tput command not found. Please install ncurses."
    exit 1
  fi
  if ! command -v sops &> /dev/null; then
    log "ERRO" "sops command not found. Please install sops."
    exit 1
  fi
  if ! command -v age &> /dev/null; then
    log "ERRO" "age command not found. Please install age."
    exit 1
  fi
}

# This function encrypts the backup file.
function encrypt_backup() {
  local file_to_encrypt="$1"
  local encrypted_filename="${file_to_encrypt}.age"
  
  log "INFO" "Encrypting ${file_to_encrypt}..."
  
  sops -e "${file_to_encrypt}" > "${encrypted_filename}"
  
  if [ -f "${encrypted_filename}" ]; then
    log "INFO" "Encryption successful: ${encrypted_filename}"
    rm "${file_to_encrypt}"
    log "INFO" "Removed unencrypted backup: ${file_to_encrypt}"
  else
    log "ERRO" "Encryption failed."
    return 1
  fi
}

# This function creates the zip archive.
function create_backup() {
  log "INFO" "Starting backup of ${INSTALL_DIR}..."
  local backup_filename="changedetection-backup-$(date +%Y%m%d%H%M%S).zip"
  local backup_filepath="${BACKUP_DIR}/${backup_filename}"
  
  # Go to the parent of the directory to be zipped to get clean paths in the archive
  cd "$(dirname "${INSTALL_DIR}")" || { log "ERRO" "Could not change to $(dirname "${INSTALL_DIR}") directory."; exit 1; }
  
  zip -r "${backup_filepath}" "$(basename "${INSTALL_DIR}")" -x "*.zip" > /dev/null 2>&1
  
  # Return to the original directory
  cd - >/dev/null || { log "ERRO" "Could not return to original directory."; exit 1; }
  
  if [ -f "${backup_filepath}" ]; then
    log "INFO" "Backup created successfully: ${backup_filepath}"
    encrypt_backup "${backup_filepath}"
  else
    log "ERRO" "Backup creation failed."
    return 1
  fi
}

# Main function to orchestrate the script execution
function main() {
  load_env
  check_dependencies
  # Ensure backup directory exists
  log "INFO" "Ensuring backup directory exists: ${BACKUP_DIR}"
  mkdir -p "${BACKUP_DIR}"
  create_backup
}

# Call main to start the script
main "$@"
