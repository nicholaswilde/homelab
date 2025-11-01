#!/usr/bin/env bash
################################################################################
#
# update
# ----------------
# Update ChangeDetection
#
# @author Nicholas Wilde, 0xb299a622
# @date 29 Mar 2025
# @version 0.2.0
#
################################################################################

# Options
set -o pipefail

# These are constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly RESET=$(tput sgr0)
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Default variables
ENABLE_NOTIFICATIONS="false"
UPDATE_SUCCESS="true"
UPDATE_MESSAGES=()

if [ -f "${SCRIPT_DIR}/.env" ]; then
  source "${SCRIPT_DIR}/.env"
fi

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
  if ! command_exists pipx || ! command_exists git || ! command_exists npm; then
    log "ERRO" "Required dependencies (pipx, git, npm) are not installed." >&2
    exit 1
  fi
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    log "ERRO" "Please run as root or with sudo."
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

  local EMAIL_SUBJECT="Homelab - Update Changedetection Summary"
  local EMAIL_BODY

  if [[ "${UPDATE_SUCCESS}" == "true" ]]; then
    EMAIL_BODY="Changedetection update completed successfully."
  else
    EMAIL_BODY="Changedetection update encountered errors."
  fi

  if [ ${#UPDATE_MESSAGES[@]} -gt 0 ]; then
    EMAIL_BODY+=$'\\n\\nUpdate details:\\n'
    for msg in "${UPDATE_MESSAGES[@]}"; do
      EMAIL_BODY+="- ${msg}"$'\n'
    done
  fi

  log "INFO" "Sending email notification..."
  curl -s \
    --url "${MAILRISE_URL}" \
    --mail-from "${MAILRISE_FROM}" \
    --mail-rcpt "${MAILRISE_RCPT}" \
    --upload-file - <<EOF
From: Changedetection Update <${MAILRISE_FROM}>
To: Nicholas Wilde <${MAILRISE_RCPT}>
Subject: ${EMAIL_SUBJECT}

${EMAIL_BODY}
EOF
  log "INFO" "Email notification sent."
}


function update_script() {

  if [[ ! -f /etc/systemd/system/changedetection.service ]]; then
    log "ERRO" "No changedetection.io Installation Found!"
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("changedetection.io installation not found.")
    return
  fi

  if ! dpkg -s libjpeg-dev >/dev/null 2>&1; then
    log "INFO" "Installing Dependencies"
    apt-get update
    if apt-get install -y libjpeg-dev; then
      log "INFO" "Installed Dependencies"
      UPDATE_MESSAGES+=("Installed libjpeg-dev dependency.")
    else
      log "ERRO" "Failed to install libjpeg-dev"
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Failed to install libjpeg-dev.")
    fi
  fi

  log "INFO" "Upgrading changedetection.io"
  if pipx upgrade changedetection.io; then
    log "INFO" "Upgraded changedetection.io"
    UPDATE_MESSAGES+=("Successfully upgraded changedetection.io.")
  else
    log "ERRO" "Failed to upgrade changedetection.io"
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("Failed to upgrade changedetection.io.")
  fi

  log "INFO" "Upgrading playwright"
  if pipx upgrade playwright; then
      log "INFO" "Upgraded playwright"
      UPDATE_MESSAGES+=("Successfully upgraded playwright.")
  else
      log "ERRO" "Failed to upgrade playwright"
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Failed to upgrade playwright.")
  fi


  if [[ -f /etc/systemd/system/browserless.service ]]; then
    log "INFO" "Updating Browserless (Patience)"
    git -C /opt/browserless/ fetch --all &>/dev/null
    if git -C /opt/browserless/ reset --hard origin/main; then
      UPDATE_MESSAGES+=("Browserless: updated from git.")
    else
      log "ERRO" "Browserless: git update failed."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Browserless: git update failed.")
    fi

    if npm update --prefix /opt/browserless; then
      UPDATE_MESSAGES+=("Browserless: npm packages updated.")
    else
      log "ERRO" "Browserless: npm update failed."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Browserless: npm update failed.")
    fi

    if /opt/browserless/node_modules/playwright-core/cli.js install --with-deps; then
      UPDATE_MESSAGES+=("Browserless: playwright dependencies installed.")
    else
      log "ERRO" "Browserless: playwright dependency installation failed."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Browserless: playwright dependency installation failed.")
    fi

    if /opt/browserless/node_modules/playwright-core/cli.js install chromium firefox webkit; then
      UPDATE_MESSAGES+=("Browserless: browsers installed.")
    else
      log "ERRO" "Browserless: browser installation failed."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Browserless: browser installation failed.")
    fi

    if npm run build --prefix /opt/browserless; then
      UPDATE_MESSAGES+=("Browserless: build successful.")
    else
      log "ERRO" "Browserless: build failed."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Browserless: build failed.")
    fi

    if npm run build:function --prefix /opt/browserless; then
      UPDATE_MESSAGES+=("Browserless: function build successful.")
    else
      log "ERRO" "Browserless: function build failed."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Browserless: function build failed.")
    fi

    if npm prune production --prefix /opt/browserless; then
      UPDATE_MESSAGES+=("Browserless: pruned production packages.")
    else
      log "ERRO" "Browserless: prune failed."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Browserless: prune failed.")
    fi

    if systemctl restart browserless; then
      log "INFO" "Updated Browserless"
      UPDATE_MESSAGES+=("Browserless: service restarted.")
    else
      log "ERRO" "Browserless: service restart failed."
      UPDATE_SUCCESS="false"
      UPDATE_MESSAGES+=("Browserless: service restart failed.")
    fi
  else
    log "WARN" "No Browserless Installation Found!"
    UPDATE_MESSAGES+=("Browserless installation not found.")
  fi

  if systemctl restart changedetection; then
    log "INFO" "Restarted changedetection service."
    UPDATE_MESSAGES+=("changedetection.io service restarted.")
  else
    log "ERRO" "Failed to restart changedetection service."
    UPDATE_SUCCESS="false"
    UPDATE_MESSAGES+=("Failed to restart changedetection.io service.")
  fi

  if [[ "${UPDATE_SUCCESS}" == "true" ]]; then
    log "INFO" "Updated Successfully"
  else
    log "ERRO" "Update failed"
  fi
}

function main() {
  log "INFO" "Starting changedetection update script..."
  check_root
  check_dependencies
  update_script
  send_notification
  log "INFO" "Script finished."
  if [[ "${UPDATE_SUCCESS}" == "false" ]]; then
    exit 1
  fi
}

main "$@"
