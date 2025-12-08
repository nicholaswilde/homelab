#!/usr/bin/env bash
################################################################################
#
# Script Name: package-apprise.sh
# ----------------
# Clones, builds, and packages the latest release of Apprise as a .deb file.
# Produced package is Architecture: all (Pure Python).
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

# --- Dynamic Codename Detection ---
readonly DEBIAN_DIST_FILE="${SCRIPT_DIR}/debian/conf/distributions"
readonly UBUNTU_DIST_FILE="${SCRIPT_DIR}/ubuntu/conf/distributions"

if [[ ! -f "${DEBIAN_DIST_FILE}" ]] || [[ ! -f "${UBUNTU_DIST_FILE}" ]]; then
  echo "ERRO: Distribution config files not found."
  exit 1
fi

ALL_DEBIAN_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${DEBIAN_DIST_FILE}"))
ALL_UBUNTU_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${UBUNTU_DIST_FILE}"))

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

Clones, builds, and packages the latest release of Apprise as a .deb file.

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
  local missing_deps=()
  local deps=(
    "curl" "jq" "git" "dpkg-deb" "tar" "python3" "reprepro"
  )
  for dep in "${deps[@]}"; do
    if ! command_exists "${dep}"; then
      missing_deps+=("${dep}")
    fi
  done

  # Check for python3-setuptools specifically usually provided by python3-setuptools package
  if ! python3 -c "import setuptools" >/dev/null 2>&1; then
      missing_deps+=("python3-setuptools")
  fi

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
  local api_url="https://api.github.com/repos/caronc/apprise/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  export json_response=$(curl "${curl_args[@]}" "${api_url}")

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for apprise from GitHub API."
    echo "${json_response}"
    exit 1
  fi

  export TAG_NAME=$(echo "${json_response}" | jq -r '.tag_name')
  export APPRISE_VERSION=${TAG_NAME#v}
  log "INFO" "Latest apprise version: ${TAG_NAME}"
}

function get_current_version() {
  local app_name="apprise"
  local repo_dir="${BASE_DIR}/ubuntu" # Check Ubuntu first
  local codename="${ALL_UBUNTU_CODENAMES[0]}"
  
  # Check version in the first defined codename
  CURRENT_VERSION=$(reprepro -b "${repo_dir}" list "${codename}" "${app_name}" 2>/dev/null | head -1 | awk '{print $NF}' | sed 's/[-+].*//' || echo "0.0.0")
  log "INFO" "Current apprise version in reprepro: ${CURRENT_VERSION}"
}

function get_description() {
  export DESCRIPTION
  DESCRIPTION=$(curl -s "https://api.github.com/repos/caronc/apprise" | jq -r '.description' | sed -e 's/:\w\+://g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
}

function build_and_package() {
  local debian_arch="all"
  local full_version="${APPRISE_VERSION}"

  local package_dir="${TEMP_PATH}/apprise_${full_version}_${debian_arch}"
  mkdir -p "${package_dir}"

  log "INFO" "Building Apprise (Pure Python) for ${debian_arch}..."
  
  # Install into the package directory using setup.py
  # We use --install-layout=deb to ensure correct paths (dist-packages)
  if ! python3 setup.py install --root="${package_dir}" --install-layout=deb --no-compile --prefix=/usr 2>&1 | log "DEBU"; then
      log "ERRO" "Python setup.py install failed."
      return 1
  fi

  log "INFO" "Creating control file..."
  mkdir -p "${package_dir}/DEBIAN"
  
  # Dependencies based on requirements.txt (simplified for system packages)
  # requests, requests-oauthlib, six, PyYAML, click, markdown
  local depends="python3, python3-requests, python3-requests-oauthlib, python3-six, python3-yaml, python3-click, python3-markdown"

  cat << EOF > "${package_dir}/DEBIAN/control"
Package: apprise
Version: ${full_version}
Section: utils
Priority: optional
Architecture: ${debian_arch}
Maintainer: Nicholas Wilde <noreply@email.com>
Depends: ${depends}
Description: ${DESCRIPTION}
EOF

  log "INFO" "Building .deb package..."
  local deb_file="apprise_${full_version}_${debian_arch}.deb"
  
  local build_output=$(dpkg-deb --root-owner-group --build "${package_dir}" "${TEMP_PATH}/${deb_file}" 2>&1)
  local exit_status=$?
  echo "${build_output}" | log "DEBU"
  if [[ ${exit_status} -ne 0 ]]; then
      log "ERRO" "Failed to build .deb package for apprise"
      return 1
  fi

  log "INFO" "Copying ${deb_file} to ${SCRIPT_DIR}"
  cp "${TEMP_PATH}/${deb_file}" "${SCRIPT_DIR}/"

  log "INFO" "Apprise package created: ${SCRIPT_DIR}/${deb_file}"
  
  # --- Import into Reprepro ---
  # Apprise is Architecture: all, so we add it to all distributions.
  
  # Debian
  for codename in "${ALL_DEBIAN_CODENAMES[@]}"; do
    log "INFO" "Importing for debian ${codename}..."
    sudo reprepro -b "${BASE_DIR}/debian" includedeb "${codename}" "${TEMP_PATH}/${deb_file}" 2>&1 | log "DEBU" || log "WARN" "Failed to add to Debian ${codename}"
  done

  # Ubuntu
  for codename in "${ALL_UBUNTU_CODENAMES[@]}"; do
    log "INFO" "Importing for ubuntu ${codename}..."
    sudo reprepro -b "${BASE_DIR}/ubuntu" includedeb "${codename}" "${TEMP_PATH}/${deb_file}" 2>&1 | log "DEBU" || log "WARN" "Failed to add to Ubuntu ${codename}"
  done

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

  log "INFO" "Starting package apprise script..."
  check_dependencies
  make_temp_dir

  get_latest_version
  get_current_version

  if [[ "${APPRISE_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "apprise is already up-to-date: ${CURRENT_VERSION}"
    exit 0
  fi
  
  log "INFO" "New version available: ${APPRISE_VERSION}"
  get_description

  local tarball_url
  tarball_url=$(echo "${json_response}" | jq -r '.tarball_url')
  if [ -z "${tarball_url}" ] || [ "${tarball_url}" == "null" ]; then
    log "ERRO" "Could not find tarball URL in GitHub API response."
    echo "${json_response}"
    exit 1
  fi

  log "INFO" "Downloading and extracting apprise version ${TAG_NAME} from ${tarball_url}"
  mkdir -p "${TEMP_PATH}/apprise"
  curl -sL "${tarball_url}" | tar -xz --strip-components=1 -C "${TEMP_PATH}/apprise" 2>&1 | log "INFO"

  cd "${TEMP_PATH}/apprise"

  build_and_package || exit 1
  
  log "INFO" "Script finished."
}

main "$@"
