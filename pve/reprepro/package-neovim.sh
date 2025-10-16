#!/usr/bin/env bash
################################################################################
#
# Script Name: package-neovim.sh
# ----------------
# Clones, builds, and packages the latest release of Neovim as a .deb file.
#
# @author Nicholas Wilde, 0xb299a622
# @date 16 Oct 2025
# @version 0.1.0
#
################################################################################

# set -e
# set -o pipefail

# Constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly RESET=$(tput sgr0)
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Logging function
function log() {
  local type="$1"
  # local message="$2"
  local color="$RESET"

  case "$type" in
    INFO)
      color="$BLUE";;
    WARN)
      color="$YELLOW";;
    ERRO)
      color="$RED";;
    # Add a default case for other types
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

# Cleanup function to remove temporary directory
function cleanup() {
  if [ -d "${TEMP_PATH}" ]; then
    log "INFO" "Cleaning up temporary directory: ${TEMP_PATH}"
    rm -rf "${TEMP_PATH}"
  fi
}

function make_temp_dir(){
  export TEMP_PATH=$(mktemp -d)
  if [ ! -d "${TEMP_PATH}" ]; then
    log "ERRO" "Could not create temp dir"
    exit 1
  fi
  log "INFO" "Temp path: ${TEMP_PATH}"
}

function get_latest_version() {
  local api_url="https://api.github.com/repos/neovim/neovim/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  export json_response=$(curl "${curl_args[@]}" "${api_url}")

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for neovim from GitHub API."
    echo "${json_response}"
    exit 1
  fi

  export TAG_NAME=$(echo "${json_response}" | jq -r '.tag_name')
  log "INFO" "Latest neovim version: ${TAG_NAME}"
}

function main() {
    # trap cleanup EXIT
    make_temp_dir
    log "INFO" "Starting package neovim script..."
    log "INFO" "Architecture: $(dpkg --print-architecture)"
    log "INFO" "Cloning neovim repository..."
    git clone https://github.com/neovim/neovim.git "${TEMP_PATH}/neovim" 2>&1 | log "INFO"

    cd "${TEMP_PATH}/neovim"

    get_latest_version

    log "INFO" "Checking out latest release: ${TAG_NAME}"
    git checkout "${TAG_NAME}"

    log "INFO" "Building neovim..."
    make CMAKE_BUILD_TYPE=RelWithDebInfo 2>&1 | log "INFO"

    log "INFO" "Packaging neovim..."
    cd build
    cpack -G DEB 2>&1 | log "INFO"

    local deb_file=$(find . -name "*.deb")

    log "INFO" "Neovim package created."
    log "INFO" "Debian package: ${TEMP_PATH}/neovim/build/${deb_file}"

}

main "$@"
