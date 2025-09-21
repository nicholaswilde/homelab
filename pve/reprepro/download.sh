#!/usr/bin/env bash
################################################################################
#
# Script Name: download.sh
# ----------------
# Downloads all task and sops installation files to a new /tmp directory.
#
# @author Nicholas Wilde, 0xb299a622
# @date 21 Sep 2025
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
  # --- check for dependencies ---
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

function download_release() {
  local app_name=$1
  local user_name=$2
  local arch=$3

  local api_url="https://api.github.com/repos/${user_name}/${app_name}/releases/latest"
  local package_url
  package_url=$(curl -s "${api_url}" | jq -r ".assets[] | select(.name | contains(\"${arch}.deb\")) | .browser_download_url")

  if [ -z "${package_url}" ]; then
    log "WARN" "No ${arch} package found for ${app_name}"
    return
  fi

  local file_name
  file_name=$(basename "${package_url}")
  local file_path="${TEMP_PATH}/${file_name}"

  log "INFO" "Downloading ${file_name} to ${file_path}"
  wget -q "${package_url}" -O "${file_path}"
}


# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting script..."
  check_dependencies
  make_temp_dir

  apps=(sops task)
  users=(getsops go-task)
  arches=(amd64 arm64 armhf)

  for i in "${!apps[@]}"; do
    for arch in "${arches[@]}"; do
      download_release "${apps[$i]}" "${users[$i]}" "${arch}"
    done
  done

  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"
