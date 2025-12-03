#!/usr/bin/env bash
################################################################################
#
# Script Name: package-sops.sh
# ----------------
# Clones, builds, and packages the latest release of sops as a .deb file.
#
# @author Nicholas Wilde, 0xb299a622
# @date 17 Oct 2025
# @version 0.2.0
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
  local api_url="https://api.github.com/repos/getsops/sops/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  export json_response=$(curl "${curl_args[@]}" "${api_url}")

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for sops from GitHub API."
    echo "${json_response}"
    exit 1
  fi

  export TAG_NAME=$(echo "${json_response}" | jq -r '.tag_name')
  export LATEST_VERSION=${TAG_NAME#v}
  log "INFO" "Latest sops version: ${LATEST_VERSION} (tag: ${TAG_NAME})"
}

function get_description() {
  export DESCRIPTION
  DESCRIPTION=$(curl -s "https://api.github.com/repos/getsops/sops" | jq -r '.description' | sed -e 's/:\w\+://g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
}

function check_dependencies() {
  log "INFO" "Checking for dependencies..."
  if command -v go &> /dev/null; then
    export GO_CMD=$(command -v go)
  else
    log "WARN" "Go not found in PATH. Searching common locations..."
    local go_executable=""
    if [ -x "/usr/local/go/bin/go" ]; then
      go_executable="/usr/local/go/bin/go"
    elif [ -n "$SUDO_USER" ]; then
      local user_home
      user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
      if [ -x "${user_home}/go/bin/go" ]; then
        go_executable="${user_home}/go/bin/go"
      fi
    fi

    if [ -n "${go_executable}" ]; then
      log "INFO" "Found go at ${go_executable}."
      export GO_CMD="${go_executable}"
      export PATH="$(dirname "${go_executable}"):${PATH}"
    else
      log "ERRO" "Go is not installed or couldn't be found. Please install Go."
      exit 1
    fi
  fi
  if ! command -v dpkg-deb &> /dev/null; then
    log "ERRO" "dpkg-deb is not installed. Please install it."
    exit 1
  fi
  if ! command -v jq &> /dev/null; then
    log "ERRO" "jq is not installed. Please install jq."
    exit 1
  fi
  log "INFO" "All dependencies are installed."
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    log "ERRO" "Please run as root or with sudo."
    exit 1
  fi
}

# Define a function to encapsulate build and package logic
function build_and_package() {
  local debian_arch="$1" # e.g., amd64, arm64, armhf
  local go_arch="$2"     # e.g., amd64, arm64, arm
  local go_arm="$3"      # e.g., 7, 6 (empty for non-arm)
  local version_suffix="$4" # e.g., "+armv6"

  local full_version="${LATEST_VERSION}${version_suffix}"
  local build_cmd=("env" "GOOS=linux")

  if [[ -n "${go_arch}" ]]; then
    build_cmd+=("GOARCH=${go_arch}")
  fi
  if [[ -n "${go_arm}" ]]; then
    build_cmd+=("GOARM=${go_arm}")
  fi
  build_cmd+=("${GO_CMD}" "build" "-o" "sops" "./cmd/sops")

  log "INFO" "Building sops for ${debian_arch} (GOARCH=${go_arch}, GOARM=${go_arm})..."
  "${build_cmd[@]}" 2>&1 | log "INFO"

  if [ ! -f "sops" ]; then
    log "ERRO" "Build failed for ${debian_arch}"
    return 1
  fi

  local package_dir="${TEMP_PATH}/sops_${full_version}_${debian_arch}"
  mkdir -p "${package_dir}/usr/local/bin"
  mkdir -p "${package_dir}/DEBIAN"

  mv sops "${package_dir}/usr/local/bin/"

  log "INFO" "Creating control file for ${debian_arch}..."
  cat << EOF > "${package_dir}/DEBIAN/control"
Package: sops
Version: ${full_version}
Section: utils
Priority: optional
Architecture: ${debian_arch}
Maintainer: Nicholas Wilde <noreply@email.com>
Description: ${DESCRIPTION}
EOF

  log "INFO" "Building .deb package for ${debian_arch}..."
  local deb_file="sops_${full_version}_${debian_arch}.deb"
  if ! dpkg-deb --build "${package_dir}" "${TEMP_PATH}/${deb_file}"; then
      log "ERRO" "Failed to build .deb package for sops ${full_version} ${debian_arch}"
      return 1
  fi

  log "INFO" "Copying ${deb_file} to ${SCRIPT_DIR}"
  cp "${TEMP_PATH}/${deb_file}" "${SCRIPT_DIR}/"

  log "INFO" "Sops package created: ${SCRIPT_DIR}/${deb_file##*/}"
  return 0
}

function main() {
    trap cleanup EXIT
    check_root
    check_dependencies
    make_temp_dir
    log "INFO" "Starting package sops script..."

    get_latest_version
    get_description

    local tarball_url
    tarball_url=$(echo "${json_response}" | jq -r '.tarball_url')
    if [ -z "${tarball_url}" ] || [ "${tarball_url}" == "null" ]; then
      log "ERRO" "Could not find tarball URL in GitHub API response."
      echo "${json_response}"
      exit 1
    fi

    log "INFO" "Downloading and extracting sops version ${TAG_NAME} from ${tarball_url}"
    mkdir -p "${TEMP_PATH}/sops"
    curl -sL "${tarball_url}" | tar -xz --strip-components=1 -C "${TEMP_PATH}/sops" 2>&1 | log "INFO"

    cd "${TEMP_PATH}/sops"

    build_and_package "amd64" "amd64" "" "" || true
    build_and_package "arm64" "arm64" "" "" || true
    build_and_package "armhf" "arm" "7" "" || true
    build_and_package "armhf" "arm" "6" "+armv6" || true
}

main "$@"
