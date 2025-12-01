#!/usr/bin/env bash
################################################################################
#
# Script Name: package-lastpass-cli.sh
# ----------------
# Clones, builds, and packages the latest release of LastPass CLI as a .deb file.
#
# @author Nicholas Wilde, 0xb299a622
# @date 25 Oct 2025
# @version 0.1.0
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

# Default variables
DEBUG="false"

if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  echo "ERRO[$(date +'%Y-%m-%d %H:%M:%S')] The .env file is missing. Please create it." >&2
  exit 1
fi
source "${SCRIPT_DIR}/.env"

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

function usage() {
  cat <<EOF
Usage: $0 [options]

Clones, builds, and packages the latest release of LastPass CLI as a .deb file.

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
  local missing_deps=()
  local deps=(
    "curl" "jq" "git" "make" "cpack" "cmake" "pkg-config"
  )
  for dep in "${deps[@]}"; do
    if ! command_exists "${dep}"; then
      missing_deps+=("${dep}")
    fi
  done

  if [ ${#missing_deps[@]} -ne 0 ]; then
    log "ERRO" "Required dependencies are not installed: ${missing_deps[*]}"
    log "INFO" "Please install them. On Debian/Ubuntu, you can use:"
    log "INFO" "sudo apt-get install -y build-essential cmake libcurl4-openssl-dev libxml2-dev libssl-dev libxml-security-c-dev pkg-config"
    exit 1
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
  local api_url="https://api.github.com/repos/lastpass/lastpass-cli/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  export json_response=$(curl "${curl_args[@]}" "${api_url}")

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for lastpass-cli from GitHub API."
    echo "${json_response}"
    exit 1
  fi

  export TAG_NAME=$(echo "${json_response}" | jq -r '.tag_name')
  export LPASS_VERSION=$(echo "${TAG_NAME}" | sed 's/v//')
  log "INFO" "Latest lastpass-cli version: ${TAG_NAME}"
}

function main() {
  trap cleanup EXIT

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -d|--debug) DEBUG="true"; shift;;
      -h|--help) usage; exit 0;;
      *) log "ERRO" "Unknown parameter passed: $1"; usage; exit 1;;
    esac
  done

  log "INFO" "Starting package lastpass-cli script..."
  check_dependencies
  make_temp_dir
  local arch
  arch=$(dpkg --print-architecture)
  log "INFO" "Architecture: ${arch}"

  get_latest_version

  # --- Architecture Detection & Version Adjustment ---
  local version_suffix=""
  if [[ "$(uname -m)" == "armv6"* ]]; then
    log "INFO" "Detected ARMv6 architecture. Appending +armv6 to version."
    version_suffix="+armv6"
    LPASS_VERSION="${LPASS_VERSION}${version_suffix}"
  fi

  local tarball_url
  tarball_url=$(echo "${json_response}" | jq -r '.tarball_url')
  if [ -z "${tarball_url}" ] || [ "${tarball_url}" == "null" ]; then
    log "ERRO" "Could not find tarball URL in GitHub API response."
    echo "${json_response}"
    exit 1
  fi

  log "INFO" "Downloading and extracting lastpass-cli version ${TAG_NAME} from ${tarball_url}"
  mkdir -p "${TEMP_PATH}/lastpass-cli"
  curl -sL "${tarball_url}" | tar -xz --strip-components=1 -C "${TEMP_PATH}/lastpass-cli" 2>&1 | log "INFO"

  cd "${TEMP_PATH}/lastpass-cli"
  mkdir -p build
  cd build

  log "INFO" "Configuring lastpass-cli build (cmake)..."
  cmake .. 2>&1 | log "INFO"

  log "INFO" "Building lastpass-cli (make)..."
  make 2>&1 | log "INFO"

  log "INFO" "Installing lastpass-cli to staging directory..."
  make install DESTDIR=./staging 2>&1 | log "INFO"

  log "INFO" "Packaging lastpass-cli..."
  cpack -G DEB \
    -D CPACK_PACKAGE_NAME=lpass \
    -D CPACK_PACKAGE_VERSION="${LPASS_VERSION}" \
    -D CPACK_PACKAGE_DESCRIPTION="LastPass command line interface tool" \
    -D CPACK_PACKAGE_VENDOR="LastPass" \
    -D CPACK_PACKAGE_CONTACT="support@lastpass.com" \
    -D CPACK_DEBIAN_PACKAGE_DEPENDS="binutils, ca-certificates, libc6, libcurl4t64, libssl3t64, libxml2" \
    -D CPACK_INSTALLED_DIRECTORIES="${TEMP_PATH}/lastpass-cli/build/staging;/" \
    -D CPACK_PACKAGE_FILE_NAME="lpass_${LPASS_VERSION}_${arch}" \
    2>&1 | log "INFO"

  local deb_file
  deb_file=$(find . -maxdepth 1 -name "*.deb")

  if [ -z "${deb_file}" ]; then
    log "ERRO" "No .deb file found after packaging."
    exit 1
  fi

  log "INFO" "Copying ${deb_file} to ${SCRIPT_DIR}"
  cp "${deb_file}" "${SCRIPT_DIR}/"

  log "INFO" "LastPass CLI package created."
  log "INFO" "Debian package: ${SCRIPT_DIR}/${deb_file}"
  log "INFO" "Script finished."
}

main "$@"
