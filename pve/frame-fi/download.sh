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

function check_dependencies() {
  log "INFO" "Checking for required dependencies..."
  if ! command_exists rclone; then
    log "ERRO" "Required dependency 'rclone' is not installed. Please install rclone to proceed." >&2
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
  check_dependencies
  load_env_variables
  configure_rclone_gphotos
  create_gphotos_album_if_not_exists
  download_images
  log "INFO" "Google Photos download script finished."
}

# Call main to start the script
main "@"