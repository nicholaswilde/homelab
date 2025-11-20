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

    declare -A archs
    archs[armel]="6"
    archs[armhf]="7"

    for arch_debian in "${!archs[@]}"; do
      local go_arm="${archs[$arch_debian]}"
      log "INFO" "Building sops for ${arch_debian} (GOARM=${go_arm})..."

      GOARM=${go_arm} GOOS=linux GOARCH=arm ${GO_CMD} build ./cmd/sops 2>&1 | log "INFO"
      if [ ! -f "sops" ]; then
        log "ERRO" "Build failed for ${arch_debian}"
        continue
      fi

      local package_dir="${TEMP_PATH}/sops_${LATEST_VERSION}_${arch_debian}"
      mkdir -p "${package_dir}/usr/local/bin"
      mkdir -p "${package_dir}/DEBIAN"

      mv sops "${package_dir}/usr/local/bin/"

      log "INFO" "Creating control file for ${arch_debian}..."
      cat << EOF > "${package_dir}/DEBIAN/control"
Package: sops
Version: ${LATEST_VERSION}
Section: utils
Priority: optional
Architecture: ${arch_debian}
Maintainer: Nicholas Wilde <noreply@email.com>
Description: ${DESCRIPTION}
EOF

      log "INFO" "Building .deb package for ${arch_debian}..."
      local deb_file="sops_${LATEST_VERSION}_${arch_debian}.deb"
      if ! dpkg-deb --build "${package_dir}" "${TEMP_PATH}/${deb_file}"; then
          log "ERRO" "Failed to build .deb package for sops ${LATEST_VERSION} ${arch_debian}"
          continue
      fi

      log "INFO" "Copying ${deb_file} to ${SCRIPT_DIR}"
      cp "${TEMP_PATH}/${deb_file}" "${SCRIPT_DIR}/"

      log "INFO" "Sops package created: ${SCRIPT_DIR}/${deb_file##*/}"
    done
}

main "$@"
