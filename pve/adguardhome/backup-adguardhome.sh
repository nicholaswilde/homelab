#!/usr/bin/env bash
################################################################################
#
# backup-adguardhome.sh
# ----------------
# Backs up pve/adguardhome/AdGuardHome.yaml.enc periodically. Before backing
# up, it compares the SOPS decrypted AdGuardHome.yaml.enc with the
# @pve/adguardhome/AdGuardHome.yaml and then encrypts AdGuardHome.yaml using
# SOPS when the comparison is different. Then it creates a git commit and
# pushes it with a standard message. A git pull origin should be done before
# the push.
#
# @author Nicholas Wilde, 0xb299a622
# @date 10 Nov 2025
# @version 0.2.0
#
################################################################################

# Options
# set -e
# set -o pipefail

# These are constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly PURPLE=$(tput setaf 5)
readonly RESET=$(tput sgr0)
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
readonly PROJECT_ROOT=$(git rev-parse --show-toplevel)
readonly ENCRYPTED_FILE="${PROJECT_ROOT}/pve/adguardhome/AdGuardHome.yaml.enc"
readonly UNENCRYPTED_FILE="${PROJECT_ROOT}/pve/adguardhome/AdGuardHome.yaml"
readonly TMP_DECRYPTED_FILE="/tmp/AdGuardHome.yaml.decrypted"

# Default variables
ENABLE_NOTIFICATIONS="true"
UPDATE_SUCCESS="true"
UPDATE_MESSAGES=()
CHANGES_DETECTED=false

if [ -f "${SCRIPT_DIR}/.env" ]; then
  source "${SCRIPT_DIR}/.env"
fi

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
  if ! command_exists sops || ! command_exists git || ! command_exists curl || ! command_exists diff; then
    log "ERRO" "Required dependencies (sops, git, curl, diff) are not installed." >&2
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("Missing required dependencies.")
    send_notification
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

  local EMAIL_SUBJECT="Homelab - AdGuardHome Backup Summary"
  local EMAIL_BODY

  if [[ "${UPDATE_SUCCESS}" == "true" ]]; then
    EMAIL_BODY="AdGuardHome backup completed successfully."
  else
    EMAIL_BODY="AdGuardHome backup encountered errors."
  fi

  if [ ${#UPDATE_MESSAGES[@]} -gt 0 ]; then
    EMAIL_BODY+=$'\n\nUpdate details:\n'
    for msg in "${UPDATE_MESSAGES[@]}"; do
      EMAIL_BODY+="- ${msg}"
    done
  fi

  log "INFO" "Sending email notification..."
  if ! curl -s \
    --url "${MAILRISE_URL}" \
    --mail-from "${MAILRISE_FROM}" \
    --mail-rcpt "${MAILRISE_RCPT}" \
    --upload-file - <<EOF
From: AdGuardHome Backup <${MAILRISE_FROM}>
To: Nicholas Wilde <${MAILRISE_RCPT}>
Subject: ${EMAIL_SUBJECT}

${EMAIL_BODY}
EOF
  then
    log "ERRO" "Failed to send notification."
    UPDATE_SUCCESS="false"
  else
    log "INFO" "Email notification sent."
  fi
}

function cleanup() {
  rm -f "${TMP_DECRYPTED_FILE}"
  log "INFO" "Cleaned up temporary files."
}

function backup_config() {
  log "INFO" "Starting AdGuardHome backup process..."

  if [ ! -f "${ENCRYPTED_FILE}" ]; then
      log "ERRO" "Encrypted file not found at ${ENCRYPTED_FILE}"
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Encrypted file not found.")
      return
  fi

  if [ ! -f "${UNENCRYPTED_FILE}" ]; then
      log "ERRO" "Unencrypted file not found at ${UNENCRYPTED_FILE}"
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Unencrypted file not found.")
      return
  fi

  log "INFO" "Decrypting for comparison..."
  if ! sops -d "${ENCRYPTED_FILE}" > "${TMP_DECRYPTED_FILE}"; then
    log "ERRO" "SOPS decryption failed."
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("SOPS decryption failed.")
    return
  fi

  if diff -q "${UNENCRYPTED_FILE}" "${TMP_DECRYPTED_FILE}"; then
    log "INFO" "No changes detected in AdGuardHome.yaml. No backup needed."
    # No changes, so we don't set CHANGES_DETECTED to true
  else
    CHANGES_DETECTED=true
    log "INFO" "Changes detected. Proceeding with backup."

    log "INFO" "Encrypting ${UNENCRYPTED_FILE} to ${ENCRYPTED_FILE}..."
    if ! sops --encrypt "${UNENCRYPTED_FILE}" > "${ENCRYPTED_FILE}"; then
        log "ERRO" "SOPS encryption failed."
        UPDATE_SUCCESS="false"
        UPDATE_MESSAGES+=("SOPS encryption failed.")
        return
    fi
    UPDATE_MESSAGES+=("Successfully encrypted new configuration.")

    log "INFO" "Adding changes to git..."
    if ! git -C "${PROJECT_ROOT}" add "${ENCRYPTED_FILE}"; then
        log "ERRO" "Git add failed."
        UPDATE_SUCCESS="false"
        UPDATE_MESSAGES+=("Git add failed.")
        return
    fi

    log "INFO" "Committing changes to git..."
    if ! git -C "${PROJECT_ROOT}" commit -m "ci(adguardhome): backup AdGuardHome.yaml"; then
        log "ERRO" "Git commit failed."
        UPDATE_SUCCESS="false"
        UPDATE_MESSAGES+=("Git commit failed.")
        return
    fi
    UPDATE_MESSAGES+=("Committed changes to git.")

    log "INFO" "Pulling latest changes from origin..."
    if ! git -C "${PROJECT_ROOT}" pull origin main; then
        log "ERRO" "Git pull failed."
        UPDATE_SUCCESS="false"
        UPDATE_MESSAGES+=("Git pull from origin failed.")
        return
    fi
    UPDATE_MESSAGES+=("Pulled latest changes from origin.")

    log "INFO" "Pushing changes to origin..."
    if ! git -C "${PROJECT_ROOT}" push origin main; then
        log "ERRO" "Git push failed."
        UPDATE_SUCCESS="false"
        UPDATE_MESSAGES+=("Git push to origin failed.")
        return
    fi
    UPDATE_MESSAGES+=("Pushed changes to origin.")

    log "INFO" "Backup and git push successful."
  fi
}

function main() {
  trap cleanup EXIT

  log "INFO" "Starting AdGuardHome backup script..."
  cd "${PROJECT_ROOT}"
  check_dependencies

  backup_config

  if [[ "${CHANGES_DETECTED}" == "true" ]] || [[ "${UPDATE_SUCCESS}" == "false" ]]; then
    send_notification
  fi

  log "INFO" "Script finished."
  if [[ "${UPDATE_SUCCESS}" == "false" ]]; then
    exit 1
  fi
}

main "$@"