#!/usr/bin/env bash
################################################################################
#
# Script Name: download-gphotos.sh
# ----------------
# Downloads images from a Google Photos album using rclone.
#
# @author Nicholas Wilde, 0xb299a622
# @date 28 Aug 2025
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

# Checks if Mailrise host is online.
function is_mailrise_online() {
  if [[ -n "${MAILRISE_HOST}" && -n "${MAILRISE_PORT}" ]]; then
    # Use nc (netcat) to check if the port is open
    if command_exists nc;
 then
      nc -z -w 5 "${MAILRISE_HOST}" "${MAILRISE_PORT}" &>/dev/null
      return $?
    elif command_exists ping;
 then
      ping -c 1 -W 5 "${MAILRISE_HOST}" &>/dev/null
      return $?
    else
      log "WARN" "Neither 'nc' nor 'ping' found. Cannot check Mailrise host availability."
      return 1
    fi
  fi
  return 1
}

# Sends a notification via Mailrise.
function send_mailrise_notification() {
  local subject="$1"
  local body="$2"
  local type="$3" # INFO, WARN, ERRO

  if is_mailrise_online;
 then
    log "INFO" "Attempting to send Mailrise notification..."
    local color_code=""
    case "$type" in
      INFO)
        color_code="#007bff";; # Blue
      WARN)
        color_code="#ffc107";; # Yellow
      ERRO)
        color_code="#dc3545";; # Red
      *)
        color_code="#6c757d";; # Grey (default)
    esac

    local json_payload
    json_payload=$(cat <<EOF
{
  "from": "${MAILRISE_FROM}",
  "to": "${MAILRISE_TO}",
  "subject": "${subject}",
  "text": "${body}",
  "html": "<html><body><p style=\"color:${color_code};\">${body}</p></body></html>"
  $(if [[ -n "${MAILRISE_API_KEY}" ]]; then echo ',"api_key": "'"${MAILRISE_API_KEY}"'"'; fi)
}
EOF
)

    if curl -s -X POST "http://${MAILRISE_HOST}:${MAILRISE_PORT}/api/v1/send" \
      -H "Content-Type: application/json" \
      -d "${json_payload}" &>/dev/null;
 then
      log "INFO" "Mailrise notification sent successfully."
    else
      log "ERRO" "Failed to send Mailrise notification."
    fi
  else
    log "WARN" "Mailrise host is not online or configuration is incomplete. Skipping notification."
  fi
}


function check_dependencies() {
  log "INFO" "Checking for required dependencies..."
  if ! command_exists rclone; then
    log "ERRO" "Required dependency 'rclone' is not installed. Please install rclone to proceed." >&2
    exit 1
  fi
  if ! command_exists curl; then
    log "ERRO" "Required dependency 'curl' is not installed. Please install curl to proceed." >&2
    exit 1
  fi
  log "INFO" "All dependencies found."
}

# Load environment variables from .env file
function load_env_variables() {
  log "INFO" "Loading environment variables from .env..."
  if [[ -f ".env" ]]; then
    # shellcheck source=/dev/null
    source ".env"
    log "INFO" "Environment variables loaded."
  else
    log "ERRO" ".env file not found. Please create one based on .env.tmpl" >&2
    exit 1
  fi

  # Check if essential variables are set
  if [[ -z "${RCLONE_GPHOTOS_CLIENT_ID}" ]]; then
    log "ERRO" "RCLONE_GPHOTOS_CLIENT_ID is not set in .env" >&2
    exit 1
  fi
  if [[ -z "${RCLONE_GPHOTOS_CLIENT_SECRET}" ]]; then
    log "ERRO" "RCLONE_GPHOTOS_CLIENT_SECRET is not set in .env" >&2
    exit 1
  fi
  if [[ -z "${RCLONE_GPHOTOS_ALBUM_NAME}" ]]; then
    log "ERRO" "RCLONE_GPHOTOS_ALBUM_NAME is not set in .env. This is the name of the Google Photos album to download." >&2
    exit 1
  fi
  if [[ -z "${RCLONE_DOWNLOAD_DESTINATION}" ]]; then
    log "ERRO" "RCLONE_DOWNLOAD_DESTINATION is not set in .env. This is the local directory to save the photos." >&2
    exit 1
  fi

  # Check if Mailrise variables are set (optional, but good for sending notifications)
  if [[ -z "${MAILRISE_HOST}" ]]; then
    log "WARN" "MAILRISE_HOST is not set in .env. Mailrise notifications will be disabled."
  fi
  if [[ -z "${MAILRISE_PORT}" ]]; then
    log "WARN" "MAILRISE_PORT is not set in .env. Mailrise notifications will be disabled."
  fi
  if [[ -z "${MAILRISE_FROM}" ]]; then
    log "WARN" "MAILRISE_FROM is not set in .env. Mailrise notifications will be disabled."
  fi
  if [[ -z "${MAILRISE_TO}" ]]; then
    log "WARN" "MAILRISE_TO is not set in .env. Mailrise notifications will be disabled."
  fi
}

# Configure rclone for Google Photos (if not already configured)
# This function assumes a remote named 'gphotos' is intended.
# It will attempt to use environment variables for client ID/secret.
# Note: Initial setup of the token usually requires interactive 'rclone config'.
# This script assumes 'gphotos' remote is already configured or will be configured interactively.
function configure_rclone_gphotos() {
  log "INFO" "Checking rclone configuration for 'gphotos' remote..."
  if ! rclone listremotes | grep -q "^gphotos:"; then
    log "WARN" "Rclone remote 'gphotos' not found. Please configure it interactively using 'rclone config' or ensure the necessary environment variables for a non-interactive setup are present (e.g., RCLONE_CONFIG_GPHOTOS_TOKEN)."
    log "INFO" "Attempting to use client ID and secret from .env for a potential non-interactive setup, but a token is usually required."
    # This part is tricky. Rclone needs a token for Google Photos.
    # The client ID and secret are for obtaining that token.
    # For a fully non-interactive script, the token itself would need to be in .env.
    # For now, I'll just set the client ID and secret as env vars for rclone,
    # but warn the user that a token might still be needed.
    export RCLONE_CONFIG_GPHOTOS_TYPE="drive" # Google Photos is a type of Google Drive remote
    export RCLONE_CONFIG_GPHOTOS_CLIENT_ID="${RCLONE_GPHOTOS_CLIENT_ID}"
    export RCLONE_CONFIG_GPHOTOS_CLIENT_SECRET="${RCLONE_GPHOTOS_CLIENT_SECRET}"
    log "INFO" "RCLONE_CONFIG_GPHOTOS_CLIENT_ID and RCLONE_CONFIG_GPHOTOS_CLIENT_SECRET set as environment variables."
    log "WARN" "If 'gphotos' remote is not configured with a token, rclone sync might fail. Consider running 'rclone config' interactively first."
  else
    log "INFO" "Rclone remote 'gphotos' found."
  fi
}


# Create Google Photos album if it doesn't exist
function create_gphotos_album_if_not_exists() {
  log "INFO" "Checking if Google Photos album '${RCLONE_GPHOTOS_ALBUM_NAME}' exists..."
  if ! rclone lsd "gphotos:album/${RCLONE_GPHOTOS_ALBUM_NAME}" &>/dev/null; then
    log "INFO" "Album '${RCLONE_GPHOTOS_ALBUM_NAME}' not found. Creating it now..."
    if rclone mkdir "gphotos:album/${RCLONE_GPHOTOS_ALBUM_NAME}"; then
      log "INFO" "Successfully created Google Photos album '${RCLONE_GPHOTOS_ALBUM_NAME}'."
    else
      log "ERRO" "Failed to create Google Photos album '${RCLONE_GPHOTOS_ALBUM_NAME}'. Check rclone configuration and permissions." >&2
      exit 1
    fi
  else
    log "INFO" "Google Photos album '${RCLONE_GPHOTOS_ALBUM_NAME}' already exists."
  fi
}

# Download images from Google Photos album
function download_images() {
  log "INFO" "Starting image download from Google Photos album '${RCLONE_GPHOTOS_ALBUM_NAME}' to '${RCLONE_DOWNLOAD_DESTINATION}'..."

  # Create destination directory if it doesn't exist
  mkdir -p "${RCLONE_DOWNLOAD_DESTINATION}"
  log "INFO" "Ensured destination directory '${RCLONE_DOWNLOAD_DESTINATION}' exists."

  # Use rclone sync to download images
  # The 'gphotos:' remote should be configured to access Google Photos.
  # The album name is specified as a path within the remote.
  if rclone sync "gphotos:album/${RCLONE_GPHOTOS_ALBUM_NAME}" "${RCLONE_DOWNLOAD_DESTINATION}" --fast-list --progress; then
    log "INFO" "Successfully downloaded images from album '${RCLONE_GPHOTOS_ALBUM_NAME}'."
  else
    log "ERRO" "Failed to download images from album '${RCLONE_GPHOTOS_ALBUM_NAME}'. Check rclone configuration and logs." >&2
    exit 1
  fi
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting Google Photos download script..."

  # Trap errors for notification
  trap 'send_mailrise_notification "Google Photos Download Failed" "The Google Photos download script encountered an error." "ERRO"' ERR

  check_dependencies
  load_env_variables
  configure_rclone_gphotos
  create_gphotos_album_if_not_exists
  download_images
  log "INFO" "Google Photos download script finished."

  send_mailrise_notification "Google Photos Download Complete" "Images from album '${RCLONE_GPHOTOS_ALBUM_NAME}' have been successfully downloaded to '${RCLONE_DOWNLOAD_DESTINATION}'." "INFO"
}

# Call main to start the script
main "@"