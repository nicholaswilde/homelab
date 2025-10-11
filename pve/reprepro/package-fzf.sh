#!/usr/bin/env bash
################################################################################
#
# Script Name: package-fzf.sh
# ----------------
# Downloads fzf tar.gz files, packages them as .deb files, and adds to reprepro.
#
# @author Nicholas Wilde, 0xb299a622
# @date 11 Oct 2025
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
readonly RESET=$(tput sgr0)
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
readonly DEBIAN_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/debian/conf/distributions"))
readonly UBUNTU_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/ubuntu/conf/distributions"))
readonly GITHUB_REPO="junegunn/fzf"

DEBUG="false"

# Define the output target based on the DEBUG variable
if [ "${DEBUG}" = "true" ]; then
  OUTPUT_TARGET="/dev/stdout" # Send output to the screen
else
  OUTPUT_TARGET="/dev/null"   # Send output to the void
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

function get_latest_fzf_version() {
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  json_response=$(curl "${curl_args[@]}" "${api_url}")
  export json_response

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version from GitHub API."
    echo "${json_response}"
    exit 1
  fi

  LATEST_VERSION=$(echo "${json_response}" | jq -r '.tag_name' | sed 's/^v//')
  PUBLISHED_AT=$(echo "${json_response}" | jq -r '.published_at')
  SOURCE_DATE_EPOCH=$(date -d "${PUBLISHED_AT}" +%s)
  export LATEST_VERSION
  export SOURCE_DATE_EPOCH
  log "INFO" "Latest fzf version: ${LATEST_VERSION}"
}

function get_current_version(){
  APP_NAME="fzf"
  CURRENT_VERSION=$(reprepro --confdir /srv/reprepro/ubuntu/conf/ list jammy "${APP_NAME}" 2>/dev/null | grep 'amd64'| awk '{print $NF}' || true)
  export CURRENT_VERSION
  log "INFO" "Current fzf version in reprepro: ${CURRENT_VERSION}"
}

function remove_package() {
  local package_name=$1
  log "INFO" "Forcefully removing existing '${package_name}' packages from reprepro to ensure a clean state..."
  for codename in "${UBUNTU_CODENAMES[@]}"; do
    log "INFO" "Attempting to remove '${package_name}' from Ubuntu ${codename}"
    reprepro -b /srv/reprepro/ubuntu remove "${codename}" "${package_name}" &> "${OUTPUT_TARGET}" || true
  done
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    log "INFO" "Attempting to remove '${package_name}' from Debian ${codename}"
    reprepro -b /srv/reprepro/debian remove "${codename}" "${package_name}" &> "${OUTPUT_TARGET}" || true
  done

  log "INFO" "Searching for and removing old '${package_name}' .deb files from the pool..."
  find /srv/reprepro/debian/pool/ -name "${package_name}_*.deb" -delete
  find /srv/reprepro/ubuntu/pool/ -name "${package_name}_*.deb" -delete
  log "INFO" "Pool cleanup complete."
}

function package_and_add() {
  local arch_github=$1
  local arch_debian=$2

  log "INFO" "Processing architecture: ${arch_github}"

  local download_url="https://github.com/${GITHUB_REPO}/releases/download/v${LATEST_VERSION}/fzf-${LATEST_VERSION}-linux_${arch_github}.tar.gz"
  local tarball_name="fzf-${LATEST_VERSION}-linux_${arch_github}.tar.gz"
  local tarball_path="${TEMP_PATH}/${tarball_name}"

  log "INFO" "Downloading ${tarball_name}..."
  if ! wget -q "${download_url}" -O "${tarball_path}"; then
    log "ERRO" "Failed to download ${tarball_name}"
    return 1
  fi

  local package_dir="${TEMP_PATH}/fzf_${LATEST_VERSION}_${arch_debian}"
  mkdir -p "${package_dir}/usr/local/bin"
  mkdir -p "${package_dir}/DEBIAN"

  log "INFO" "Extracting fzf binary..."
  tar -xzf "${tarball_path}" -C "${package_dir}/usr/local/bin/" fzf

  log "INFO" "Creating control file..."
  cat << EOF > "${package_dir}/DEBIAN/control"
Package: fzf
Version: ${LATEST_VERSION}
Section: utils
Priority: optional
Architecture: ${arch_debian}
Maintainer: Nicholas Wilde <noreply@email.com>
Description: A command-line fuzzy finder
EOF

  # Define the output target based on the DEBUG variable
  if [ "${DEBUG}" = "true" ]; then
    OUTPUT_TARGET="/dev/stdout" # Send output to the screen
  else
    OUTPUT_TARGET="/dev/null"   # Send output to the void
  fi
  log "INFO" "Building .deb package..."
  local deb_file="fzf_${LATEST_VERSION}_${arch_debian}.deb"
  dpkg-deb --build "${package_dir}" "${TEMP_PATH}/${deb_file}" &> "${OUTPUT_TARGET}"
  echo $?
  log "INFO" "Adding ${deb_file} to reprepro..."
  for codename in "${UBUNTU_CODENAMES[@]}"; do
    reprepro -b /srv/reprepro/ubuntu includedeb "${codename}" "${TEMP_PATH}/${deb_file}" &> "${OUTPUT_TARGET}" || true
  done
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    reprepro -b /srv/reprepro/debian includedeb "${codename}" "${TEMP_PATH}/${deb_file}" &> "${OUTPUT_TARGET}" || true
  done
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting fzf packaging script..."
  check_root
  check_dependencies
  make_temp_dir
  get_latest_fzf_version
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "fzf is already up-to-date: ${CURRENT_VERSION}"
    exit 0
  fi

  log "INFO" "New version available: ${LATEST_VERSION}"

  remove_package "fzf"

  local linux_tarballs
  linux_tarballs=$(echo "${json_response}" | jq -r '.assets[] | select(.name | test("linux.*.tar.gz$")) | .name')

  for tarball in ${linux_tarballs}; do
    local github_arch
    github_arch=$(echo "${tarball}" | sed -n "s/fzf-${LATEST_VERSION}-linux_\(.*\)\.tar\.gz/\1/p")

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
      *)
        log "WARN" "Unsupported architecture found: ${github_arch}. Skipping."
        continue;;
    esac

    package_and_add "${github_arch}" "${debian_arch}"
  done


  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"
