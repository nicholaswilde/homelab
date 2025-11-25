#!/usr/bin/env bash
################################################################################
#
# Script Name: check-config.sh
# ----------------
# Checks if app.ini.enc needs to be updated by comparing it with the
# live configuration.
#
# @author Nicholas Wilde, 0xb299a622
# @date 24 Nov 2025
# @version 0.1.0
#
################################################################################

# Options
# set -e
# set -o pipefail

# Constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly RESET=$(tput sgr0)
readonly PURPLE=$(tput setaf 5)
readonly ENC_FILE="app.ini.enc"
readonly LIVE_FILE_NAME="app.ini"
ENABLE_NOTIFICATIONS="true"
DEBUG="false"

# Logging function
function log() {
  local type="$1"
  local color="$RESET"

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
function commandExists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! commandExists sops || ! commandExists diff; then
    log "ERRO" "Required dependencies (sops, diff) are not installed." >&2
    exit 1
  fi
}

function send_notification(){
  if [[ "${ENABLE_NOTIFICATIONS}" == "false" ]]; then
    log "WARN" "Notifications are disabled. Skipping."
    return 0
  fi
  if [[ -z "${MAILRISE_URL}" || -z "${MAILRISE_FROM}" || -z "${MAILRISE_RCPT}" ]]; then
    log "WARN" "Notification variables not set. Skipping notification."
    return 1
  fi

  local EMAIL_SUBJECT="Homelab - Gitea Settings"
  local EMAIL_BODY="Gitea config settings are out of date."

  log "INFO" "Sending email notification..."
  if ! curl -s \
    --url "${MAILRISE_URL}" \
    --mail-from "${MAILRISE_FROM}" \
    --mail-rcpt "${MAILRISE_RCPT}" \
    --upload-file - <<EOF
From: Application <${MAILRISE_FROM}>
To: User <${MAILRISE_RCPT}>
Subject: ${EMAIL_SUBJECT}

${EMAIL_BODY}
EOF
  then
    log "ERRO" "Failed to send notification."
  else
    log "INFO" "Email notification sent."
  fi
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting configuration check..."
  
  check_dependencies

  # Source .env to get CONFIG_DIR
  local env_file
  env_file="$(dirname "$0")/.env"
  
  if [ -f "$env_file" ]; then
    # shellcheck source=/dev/null
    source "$env_file"
  else
    log "WARN" ".env file not found at $env_file"
  fi

  # Set CONFIG_DIR if not set by .env
  if [ -z "${CONFIG_DIR}" ]; then
    CONFIG_DIR="/etc/gitea"
    log "WARN" "CONFIG_DIR not set. Using default: ${CONFIG_DIR}"
  fi
  
  local live_file="${CONFIG_DIR}/${LIVE_FILE_NAME}"
  local enc_file_path="$(dirname "$0")/${ENC_FILE}"

  if [ ! -f "$enc_file_path" ]; then
    log "ERRO" "Encrypted file not found: $enc_file_path"
    exit 1
  fi

  # Check if live file exists
  if [ ! -f "$live_file" ]; then
     log "ERRO" "Live config file not found: $live_file"
     exit 1
  fi
  
  local temp_decrypted
  temp_decrypted=$(mktemp)
  log "DEBU" "temp_decrypted: ${temp_decrypted}"
  # trap 'rm -f "${temp_decrypted}"' EXIT

  log "INFO" "Decrypting ${ENC_FILE} for comparison..."
  if ! sops -d --input-type ini --output-type ini "$enc_file_path" > "$temp_decrypted"; then
    log "ERRO" "Failed to decrypt $enc_file_path"
    exit 1
  fi

  log "INFO" "Comparing with live configuration at ${live_file}..."
  
  # Compare files
  # Using sudo for diff if read permissions are restricted
  if [ -r "$live_file" ]; then
    diff -q "$temp_decrypted" "$live_file" >/dev/null 2>&1
  else
    sudo diff -q "$temp_decrypted" "$live_file" >/dev/null 2>&1
  fi
  
  local diff_status=$?
  
  if [ $diff_status -eq 0 ]; then
    log "INFO" "Configuration is in sync."
  elif [ $diff_status -eq 1 ]; then
    log "WARN" "Configuration mismatch detected!"
    log "INFO" "The live file ($live_file) differs from the encrypted source ($ENC_FILE)."
    log "INFO" "Run 'task encrypt' to update the encrypted file, or 'task decrypt' to restore from source."
    send_notification
  else
    log "ERRO" "Error comparing files. Check permissions for $live_file."
    exit 1
  fi

  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"
