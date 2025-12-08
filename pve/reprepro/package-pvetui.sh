#!/usr/bin/env bash
################################################################################
#
# Script Name: package-pvetui.sh
# ----------------
# Clones, builds, and packages the latest release of pvetui for ARMv6 and ARMv7 as a .deb file.
#
# @author Nicholas Wilde, 0xb299a622
# @date 07 Dec 2025
# @version 0.1.0
#
################################################################################

# Options
# set -e
# set -o pipefail

# Constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly PURPLE=$(tput setaf 5)
readonly RESET=$(tput sgr0)
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Default variables
DEBUG="false"
BASE_DIR="/srv/reprepro"

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

Clones, builds, and packages the latest release of pvetui for ARMv6 and ARMv7 as a .deb file.

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
  
  local missing_deps=()
  local deps=(
    "curl" "jq" "git" "dpkg-deb" "tar" "reprepro"
  )
  for dep in "${deps[@]}"; do
    if ! command_exists "${dep}"; then
      missing_deps+=("${dep}")
    fi
  done

  if [ ${#missing_deps[@]} -ne 0 ]; then
    log "ERRO" "Required dependencies are not installed: ${missing_deps[*]}"
    exit 1
  fi
  log "INFO" "All dependencies are installed."
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
  local api_url="https://api.github.com/repos/devnullvoid/pvetui/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  export json_response=$(curl "${curl_args[@]}" "${api_url}")

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for pvetui from GitHub API."
    echo "${json_response}"
    exit 1
  fi

  export TAG_NAME=$(echo "${json_response}" | jq -r '.tag_name')
  export APP_VERSION=${TAG_NAME#v}
  log "INFO" "Latest pvetui version: ${TAG_NAME}"
}

function get_current_version() {
  local app_name="pvetui"
  local repo_dir="/srv/reprepro/raspi"
  # Default to trixie or check distributions file
  local codename="trixie"
  
  if [ -f "${SCRIPT_DIR}/raspi/conf/distributions" ]; then
      codename=$(grep -m 1 "Codename: " "${SCRIPT_DIR}/raspi/conf/distributions" | awk '{print $2}')
  fi

  # Check version in the first defined codename
  # We look for version string, stripping epoch if present, and suffix like +armv6
  CURRENT_VERSION=$(reprepro -b "${repo_dir}" list "${codename}" "${app_name}" 2>/dev/null | head -1 | awk '{print $NF}' | sed 's/[-+].*//' || echo "0.0.0")
  log "INFO" "Current pvetui version in reprepro: ${CURRENT_VERSION}"
}

function get_description() {
  export DESCRIPTION
  DESCRIPTION=$(curl -s "https://api.github.com/repos/devnullvoid/pvetui" | jq -r '.description' | sed -e 's/:\w\+://g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
}

function build_and_package() {
  local debian_arch="$1" # e.g., armhf
  local go_arch="$2"     # e.g., arm
  local go_arm="$3"      # e.g., 6 or 7
  local version_suffix="$4" # e.g., +armv6

  local full_version="${APP_VERSION}${version_suffix}"
  local build_cmd=("env" "GOOS=linux")

  if [[ -n "${go_arch}" ]]; then
    build_cmd+=("GOARCH=${go_arch}")
  fi
  if [[ -n "${go_arm}" ]]; then
    build_cmd+=("GOARM=${go_arm}")
  fi
  
  build_cmd+=("${GO_CMD}" "build" "-ldflags" "-s -w" "-o" "pvetui" ".")

  log "INFO" "Building pvetui for ${debian_arch} (GOARCH=${go_arch}, GOARM=${go_arm})..."
  "${build_cmd[@]}" 2>&1 | log "INFO"

  if [ ! -f "pvetui" ]; then
    log "ERRO" "Build failed for ${debian_arch}"
    return 1
  fi

  local package_dir="${TEMP_PATH}/pvetui_${full_version}_${debian_arch}"
  mkdir -p "${package_dir}/usr/local/bin"
  mkdir -p "${package_dir}/DEBIAN"

  # Copy and move binary
  cp "pvetui" "${package_dir}/usr/local/bin/"

  log "INFO" "Creating control file for ${debian_arch}..."
  cat << EOF > "${package_dir}/DEBIAN/control"
Package: pvetui
Version: ${full_version}
Section: utils
Priority: optional
Architecture: ${debian_arch}
Maintainer: Nicholas Wilde <noreply@email.com>
Description: ${DESCRIPTION}
EOF

  log "INFO" "Building .deb package for ${debian_arch}..."
  local deb_file="pvetui_${full_version}_${debian_arch}.deb"
  local build_output=$(dpkg-deb --root-owner-group --build "${package_dir}" "${TEMP_PATH}/${deb_file}" 2>&1)
  local exit_status=$?
  echo "${build_output}" | log "DEBU"
  if [[ ${exit_status} -ne 0 ]]; then
      log "ERRO" "Failed to build .deb package for pvetui ${full_version} ${debian_arch}"
      return 1
  fi

  log "INFO" "Copying ${deb_file} to ${SCRIPT_DIR}"
  cp "${TEMP_PATH}/${deb_file}" "${SCRIPT_DIR}/"

  log "INFO" "Pvetui package created: ${SCRIPT_DIR}/${deb_file}"
  return 0
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

  log "INFO" "Starting package pvetui script..."
  check_dependencies
  make_temp_dir

  get_latest_version
  get_current_version

  if [[ "${APP_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "pvetui is already up-to-date: ${CURRENT_VERSION}"
    exit 0
  fi
  
  log "INFO" "New version available: ${APP_VERSION}"
  get_description

  local tarball_url
  tarball_url=$(echo "${json_response}" | jq -r '.tarball_url')
  if [ -z "${tarball_url}" ] || [ "${tarball_url}" == "null" ]; then
    log "ERRO" "Could not find tarball URL in GitHub API response."
    echo "${json_response}"
    exit 1
  fi

  log "INFO" "Downloading and extracting pvetui version ${TAG_NAME} from ${tarball_url}"
  mkdir -p "${TEMP_PATH}/pvetui"
  curl -sL "${tarball_url}" | tar -xz --strip-components=1 -C "${TEMP_PATH}/pvetui" 2>&1 | log "INFO"

  cd "${TEMP_PATH}/pvetui"

  # Build for ARMv6
  build_and_package "armhf" "arm" "6" "+armv6" || log "ERRO" "Failed to build ARMv6"
  
  # Build for ARMv7
  # Using standard armhf but with +armv7 suffix to distinguish, or standard version if it's the 'primary' armhf
  build_and_package "armhf" "arm" "7" "+armv7" || log "ERRO" "Failed to build ARMv7"
  
  log "INFO" "Script finished."
}

main "$@"
