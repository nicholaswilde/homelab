#!/usr/bin/env bash
################################################################################
#
# Script Name: download.sh
# ----------------
# Downloads all task and sops installation files to a new /tmp directory.
#
# @author Nicholas Wilde, 0xb299a622
# @date 13 Oct 2025
# @version 0.2.0
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
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DEBUG="false"

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
    DEBU)
      color="$PURPLE";;
  esac

  echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
}

if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  log "ERRO" "The .env file is missing. Please create it by running \`task init\`."
  exit 1
fi
source "${SCRIPT_DIR}/.env"

function usage() {
  cat <<EOF
Usage: $0 [options]

Downloads application .deb files.

Options:
  -d, --debug         Enable debug mode, which prints more info.
  -h, --help          Display this help message.
EOF
}

# Cleanup function to remove temporary directory
function cleanup() {
  if [ -d "${TEMP_PATH}" ]; then
    log "INFO" "Cleaning up temporary directory: ${TEMP_PATH}"
    rm -rf "${TEMP_PATH}"
  fi
}

# Checks if a command exists.
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! command_exists curl || ! command_exists jq; then
    log "ERRO" "Required dependencies (curl, jq) are not installed."
    exit 1
  fi
}

function make_temp_dir(){
  TEMP_PATH=$(mktemp -d)
  if [ ! -d "${TEMP_PATH}" ]; then
    log "ERRO" "Could not create temp dir"
    exit 1
  fi
  export TEMP_PATH
  log "INFO" "Temp path: ${TEMP_PATH}"
}

function get_latest_version() {
  local api_url="https://api.github.com/repos/${USERNAME}/${APP_NAME}/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  json_response=$(curl "${curl_args[@]}" "${api_url}")
  export json_response

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ${APP_NAME} from GitHub API."
    echo "${json_response}"
    # Don't exit, just return so we can continue with other apps
    return 1
  fi

  TAG_NAME=$(echo "${json_response}" | jq -r '.tag_name')
  LATEST_VERSION=${TAG_NAME#v}
  PUBLISHED_AT=$(echo "${json_response}" | jq -r '.published_at')
  SOURCE_DATE_EPOCH=$(date -d "${PUBLISHED_AT}" +%s)
  export TAG_NAME
  export LATEST_VERSION
  export SOURCE_DATE_EPOCH
  log "INFO" "Latest ${APP_NAME} version: ${LATEST_VERSION} (tag: ${TAG_NAME})"
}

function download_release() {
  local package_name=$1
  
  log "INFO" "Processing package: ${package_name}"

  local download_url
  download_url=$(echo "${json_response}" | jq -r --arg pkg_name "$package_name" '.assets[] | select(.name==$pkg_name) | .browser_download_url')

  if [ -z "${download_url}" ]; then
    log "ERRO" "Failed to get download url for ${package_name}"
    return 1
  fi

  local package_path="${TEMP_PATH}/${package_name}"

  log "INFO" "Downloading ${package_name}..."
  if ! wget -q "${download_url}" -O "${package_path}"; then
    log "ERRO" "Failed to download ${package_name}"
    return 1
  fi
}

function download_app() {
  local github_repo="$1"
  local app_name
  app_name=$(basename "${github_repo}")
  local username
  username=$(dirname "${github_repo}")
  export APP_NAME="${app_name}"
  export USERNAME="${username}"

  log "INFO" "--------------------------------------------------"
  log "INFO" "Processing application: ${APP_NAME}"
  log "INFO" "--------------------------------------------------"

  if ! get_latest_version; then
    return
  fi

  local linux_debs
  linux_debs=$(echo "${json_response}" | jq -r '.assets[] | select(.name | endswith(".deb") and (contains("musl") | not)) | .name')

  for deb in ${linux_debs}; do
    if ! download_release "${deb}"; then
      log "ERRO" "Skipping ${APP_NAME} ${deb} due to download error."
      continue
    fi
  done
}

# Main function to orchestrate the script execution
function main() {
  trap cleanup EXIT

  # Parse command-line arguments
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -d|--debug)
        DEBUG="true"
        shift;; 
      -h|--help)
        usage
        exit 0;; 
      *)
        log "ERRO" "Unknown parameter passed: $1"
        usage
        exit 1;; 
    esac
  done

  # Define the output target based on the DEBUG variable
  if [ "${DEBUG}" = "true" ]; then
    OUTPUT_TARGET="/dev/stdout" # Send output to the screen
  else
    OUTPUT_TARGET="/dev/null"   # Send output to the void
  fi

  log "INFO" "Starting download script..."

  check_dependencies
  make_temp_dir

  for github_repo in "${SYNC_APPS_GITHUB_REPOS[@]}"; do
    download_app "${github_repo}"
  done

  log "INFO" "Downloads are in ${TEMP_PATH}"
  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"