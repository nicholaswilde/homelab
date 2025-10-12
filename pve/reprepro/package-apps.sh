#!/usr/bin/env bash
################################################################################
#
# Script Name: package-apps.sh
# ----------------
# Downloads application tar.gz files, packages them as .deb files, and adds to
# reprepro.
#
# @author Nicholas Wilde, 0xb299a622
# @date 11 Oct 2025
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
readonly DEBIAN_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/debian/conf/distributions"))
readonly UBUNTU_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/ubuntu/conf/distributions"))

BASE_DIR="/srv/reprepro"
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  echo "ERRO[$(date +'%Y-%m-%d %H:%M:%S')] The .env file is missing. Please create it." >&2
  exit 1
fi
source "${SCRIPT_DIR}/.env"

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

function usage() {
  cat <<EOF
Usage: $0 [options]

Downloads application tar.gz files, packages them as .deb files, and adds to reprepro.

Options:
  -d, --debug         Enable debug mode, which prints more info.
  -r, --remove <pkg>  Remove a package from the repository.
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
  if ! command_exists curl || ! command_exists jq || ! command_exists dpkg-deb; then
    log "ERRO" "Required dependencies (curl, jq, dpkg-deb) are not installed."
    exit 1
  fi
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    log "ERRO" "Please run as root or with sudo."
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
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
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

function get_current_version(){
  CURRENT_VERSION=$(reprepro --confdir /srv/reprepro/ubuntu/conf/ list jammy "${APP_NAME}" 2>/dev/null | grep 'amd64'| awk '{print $NF}' || true)
  export CURRENT_VERSION
  log "INFO" "Current ${APP_NAME} version in reprepro: ${CURRENT_VERSION}"
}

function remove_package() {
  local package_name=$1
  log "INFO" "Forcefully removing existing '${package_name}' packages from reprepro to ensure a clean state..."
  for codename in "${UBUNTU_CODENAMES[@]}"; do
    log "INFO" "Attempting to remove '${package_name}' from Ubuntu ${codename}"
    reprepro -b "${BASE_DIR}/ubuntu" remove "${codename}" "${package_name}" &> "${OUTPUT_TARGET}" || true
  done
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    log "INFO" "Attempting to remove '${package_name}' from Debian ${codename}"
    reprepro -b "${BASE_DIR}/debian" remove "${codename}" "${package_name}" &> "${OUTPUT_TARGET}" || true
  done

  log "INFO" "Searching for and removing old '${package_name}' .deb files from the pool..."
  find "${BASE_DIR}/debian/pool/" -name "${package_name}_*.deb" -delete
  find "${BASE_DIR}/ubuntu/pool/" -name "${package_name}_*.deb" -delete
  log "INFO" "Pool cleanup complete."
}

function package_and_add() {
  local arch_github=$1
  local arch_debian=$2
  local tarball_name=$3
  
  log "INFO" "Processing architecture: ${arch_github}"

  local download_url=$(echo "${json_response}" | jq -r --arg pkg_name "$tarball_name" '.assets[] | select(.name==$pkg_name) | .browser_download_url')
  if [ -z "${download_url}" ]; then
    log "ERRO" "Failed to get download url for ${package_name}"
    return 1
  fi
    
  local tarball_path="${TEMP_PATH}/${tarball_name}"

  log "INFO" "Downloading ${tarball_name}..."
  if ! wget -q "${download_url}" -O "${tarball_path}"; then
    log "ERRO" "Failed to download ${tarball_name}"
    return 1
  fi

  local package_dir="${TEMP_PATH}/${APP_NAME}_${LATEST_VERSION}_${arch_debian}"
  mkdir -p "${package_dir}/usr/local/bin"
  mkdir -p "${package_dir}/DEBIAN"

  log "INFO" "Extracting ${APP_NAME} binary..."
  if ! tar -xzf "${tarball_path}" -C "${package_dir}/usr/local/bin/" "${APP_NAME}"; then
    log "ERRO" "Failed to extract ${tarball_name}"
    return 1
  fi

  log "INFO" "Creating control file..."
  cat << EOF > "${package_dir}/DEBIAN/control"
Package: ${APP_NAME}
Version: ${LATEST_VERSION}
Section: utils
Priority: optional
Architecture: ${arch_debian}
Maintainer: Nicholas Wilde <noreply@email.com>
Description: ${DESCRIPTION}
EOF

  log "INFO" "Building .deb package..."
  local deb_file="${APP_NAME}_${LATEST_VERSION}_${arch_debian}.deb"
  if ! dpkg-deb --build "${package_dir}" "${TEMP_PATH}/${deb_file}" &> "${OUTPUT_TARGET}"; then
    log "ERRO" "Failed to build .deb package for ${APP_NAME} ${LATEST_VERSION} ${arch_debian}"
    return 1
  fi
  log "INFO" "Adding ${deb_file} to reprepro..."
  for codename in "${UBUNTU_CODENAMES[@]}"; do
    reprepro -b "${BASE_DIR}/ubuntu" includedeb "${codename}" "${TEMP_PATH}/${deb_file}" &> "${OUTPUT_TARGET}" || true
  done
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    reprepro -b "${BASE_DIR}/debian" includedeb "${codename}" "${TEMP_PATH}/${deb_file}" &> "${OUTPUT_TARGET}" || true
  done
}

function update_app() {
  local app_name="$1"
  local github_repo="$2"
  export APP_NAME="${app_name}"
  export GITHUB_REPO="${github_repo}"

  log "INFO" "--------------------------------------------------"
  log "INFO" "Processing application: ${APP_NAME}"
  log "INFO" "--------------------------------------------------"

  if ! get_latest_version; then
    return
  fi
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date: ${CURRENT_VERSION}"
    return
  fi

  log "INFO" "New version available: ${LATEST_VERSION}"

  # remove_package "${APP_NAME}"

  export DESCRIPTION=$(curl -s "https://api.github.com/repos/${GITHUB_REPO}" | jq -r '.description' | sed -e 's/:\w\+://g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

  local linux_tarballs
  linux_tarballs=$(echo "${json_response}" | jq -r '.assets[] | select(.name | endswith(".tar.gz") and (contains("musl") | not) and (contains("openbsd") | not) and (contains("darwin") | not) and (contains("freebsd")| not) and (contains("android") | not)) | .name')

  for tarball in ${linux_tarballs}; do
    local github_arch
    github_arch=$(echo "${tarball}" | grep -oP '(?<=_)[^_]+(?=\.tar\.gz)')
    
    local debian_arch=""
    case "${github_arch}" in
      "amd64")
        debian_arch="amd64";;
      "arm64")
        debian_arch="arm64";;
      "armv7")
        debian_arch="armhf";;
      "386")
        debian_arch="i386";;
      "armhf")
        debian_arch="armhf";;
      "arm")
        debian_arch="arm";;
      *)
        log "WARN" "Unsupported architecture found: ${github_arch}. Skipping."
        continue;;
    esac

    if ! package_and_add "${github_arch}" "${debian_arch}" "${tarball}"; then
      log "ERRO" "Skipping ${APP_NAME} ${github_arch} due to packaging error."
      continue
    fi
  done
}

# Main function to orchestrate the script execution
function main() {
  trap cleanup EXIT
  local package_to_remove=""

  # Parse command-line arguments
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -d|--debug)
        DEBUG="true"
        shift # past argument
        ;;
      -r|--remove)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          package_to_remove="$2"
          shift 2 # past argument and value
        else
          log "ERRO" "Error: Argument for $1 is missing" >&2
          usage
          exit 1
        fi
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log "ERRO" "Unknown parameter passed: $1"
        usage
        exit 1
        ;;
    esac
  done

  # Define the output target based on the DEBUG variable
  if [ "${DEBUG}" = "true" ]; then
    OUTPUT_TARGET="/dev/stdout" # Send output to the screen
  else
    OUTPUT_TARGET="/dev/null"   # Send output to the void
  fi

  log "INFO" "Starting application packaging script..."
  check_root

  if [ -n "${package_to_remove}" ]; then
    remove_package "${package_to_remove}"
    log "INFO" "Script finished."
    exit 0
  fi

  check_dependencies
  make_temp_dir

  for github_repo in "${PACKAGE_APPS_GITHUB_REPOS[@]}"; do
    local app_name
    app_name=$(basename "${github_repo}")
    update_app "${app_name}" "${github_repo}"
  done

  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"