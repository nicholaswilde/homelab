#!/usr/bin/env bash
################################################################################
#
# Script Name: update-raspi.sh
# ----------------
# Downloads and packages applications for Raspberry Pi 1 / Zero (ARMv6).
# Adds them to the /srv/reprepro/raspi repository.
#
# @author Nicholas Wilde, 0xb299a622
# @date 05 Dec 2025
# @version 1.0.0
#
################################################################################

# Options
# set -e
# set -o pipefail

# Constants
if [[ -t 1 ]]; then
  readonly BLUE=$(tput setaf 4)
  readonly RED=$(tput setaf 1)
  readonly YELLOW=$(tput setaf 3)
  readonly PURPLE=$(tput setaf 5)
  readonly RESET=$(tput sgr0)
else
  readonly BLUE=""
  readonly RED=""
  readonly YELLOW=""
  readonly PURPLE=""
  readonly RESET=""
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DIST_FILE="${SCRIPT_DIR}/raspi/conf/distributions"
REPO_DIR="/srv/reprepro/raspi"

# Default variables
DEBUG="false"

if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  echo "ERRO[$(date +'%Y-%m-%d %H:%M:%S')] The .env file is missing. Please create it." >&2
  exit 1
fi
source "${SCRIPT_DIR}/.env"

# App Configuration
# Format: "GitHubRepo:Type:BinaryName:Regex:ExtractStrategy"
# Type: deb, bin, tar
# ExtractStrategy (for tar): strip (components=1), flat (root), path (specific)
readonly APPS=(
  # "getsops/sops:bin:sops:sops-v.*\.linux\.armv6$:none" # Needs build from source
  "sharkdp/fd:tar:fd:arm-unknown-linux-gnueabihf\.tar\.gz$:strip"
  "chmln/sd:tar:sd:arm-unknown-linux-gnueabihf\.tar\.gz$:strip"
  "aristocratos/btop:tar:btop:arm-linux-musleabi\.tbz$:path"
  "go-task/task:tar:task:linux_arm\.tar\.gz$:flat"
  "muesli/duf:deb:duf:linux_armv6\.deb$:none"
  "cli/cli:deb:gh:linux_armv6\.deb$:none"
  "sharkdp/bat:tar:bat:arm-unknown-linux-gnueabihf\.tar\.gz$:strip"
  "eza-community/eza:tar:eza:arm-unknown-linux-gnueabihf\.tar\.gz$:strip"
  "charmbracelet/glow:tar:glow:Linux_arm\.tar\.gz$:strip"
  "junegunn/fzf:tar:fzf:linux_armv6\.tar\.gz$:flat"
)

# Logging function
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi

  case "$type" in
    INFO) color="$BLUE";;
    WARN) color="$YELLOW";;
    ERRO) color="$RED";;
    DEBU) color="$PURPLE";;
    *)    type="LOGS";;
  esac

  echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}" >&2
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    log "ERRO" "Please run as root or with sudo."
    exit 1
  fi
}

function check_dependencies() {
  local deps=(curl jq reprepro dpkg-deb tar)
  for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log "ERRO" "Required dependency '$cmd' is not installed."
      exit 1
    fi
  done
}

function make_temp_dir(){
  export TEMP_PATH=$(mktemp -d)
  if [ ! -d "${TEMP_PATH}" ]; then
    log "ERRO" "Could not create temp dir"
    exit 1
  fi
  log "DEBU" "Temp path: ${TEMP_PATH}"
}

function cleanup() {
  if [ -d "${TEMP_PATH}" ]; then
    log "DEBU" "Cleaning up temporary directory: ${TEMP_PATH}"
    rm -rf "${TEMP_PATH}"
  fi
}

function get_codenames() {
  if [ ! -f "${DIST_FILE}" ]; then
    log "ERRO" "Distribution config not found at ${DIST_FILE}"
    exit 1
  fi
  CODENAMES=($(grep -oP '(?<=Codename: ).*' "${DIST_FILE}"))
}

function get_latest_version() {
  local repo="$1"
  # Reset variables
  JSON_RESPONSE=""
  TAG_NAME=""
  LATEST_VERSION=""
  DESCRIPTION=""

  local api_url="https://api.github.com/repos/${repo}/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  JSON_RESPONSE=$(curl "${curl_args[@]}" "${api_url}")

  if ! echo "${JSON_RESPONSE}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ${repo}"
    return 1
  fi

  TAG_NAME=$(echo "${JSON_RESPONSE}" | jq -r '.tag_name')
  LATEST_VERSION=${TAG_NAME#v}
  DESCRIPTION=$(curl -s "https://api.github.com/repos/${repo}" | jq -r '.description' | sed -e 's/:\w\+://g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
}

function get_current_version() {
  local app_name="$1"
  local codename="${CODENAMES[0]}"
  # Check version in the first defined codename (assuming sync)
  CURRENT_VERSION=$(reprepro -b "${REPO_DIR}" list "${codename}" "${app_name}" 2>/dev/null | head -1 | awk '{print $NF}' | sed 's/[-+].*//' || echo "0.0.0")
}

function extract_and_package() {
  local app_name="$1"
  local version="$2"
  local tarball_path="$3"
  local strategy="$4"
  local bin_name="$5"
  local package_dir="$6"
  local desc="$7"

  log "INFO" "  -> Extracting (${strategy})..."
  local bin_dest="${package_dir}/usr/local/bin"
  mkdir -p "${bin_dest}"

  case "${strategy}" in
    strip)
      # Expects Folder/Binary
      tar -xf "${tarball_path}" -C "${bin_dest}" --strip-components=1 --wildcards "*/${bin_name}"
      ;;
    flat)
      # Expects Binary at root
      tar -xf "${tarball_path}" -C "${bin_dest}" "${bin_name}"
      ;;
    path)
      # Special case for btop: btop/bin/btop
      if [[ "${app_name}" == "btop" ]]; then
        tar -xf "${tarball_path}" -C "${bin_dest}" --strip-components=3 --wildcards "*/bin/btop"
      else
        log "ERRO" "Path strategy not implemented for ${app_name}"
        return 1
      fi
      ;;
    *)
      log "ERRO" "Unknown strategy: ${strategy}"
      return 1
      ;;
  esac
  
  # Ensure binary exists and executable
  if [ ! -f "${bin_dest}/${bin_name}" ]; then
     log "ERRO" "Binary not found after extraction: ${bin_dest}/${bin_name}"
     return 1
  fi
  chmod +x "${bin_dest}/${bin_name}"

  # Rename if binary name differs from app name (optional, usually same)
  if [[ "${bin_name}" != "${app_name}" ]]; then
    mv "${bin_dest}/${bin_name}" "${bin_dest}/${app_name}"
  fi

  log "INFO" "  -> Creating control file..."
  mkdir -p "${package_dir}/DEBIAN"
  cat << EOF > "${package_dir}/DEBIAN/control"
Package: ${app_name}
Version: ${version}+armv6
Section: utils
Priority: optional
Architecture: armhf
Maintainer: Nicholas Wilde <noreply@email.com>
Description: ${desc}
EOF

  log "INFO" "  -> Building .deb..."
  dpkg-deb --build "${package_dir}" "${TEMP_PATH}/${app_name}_${version}+armv6_armhf.deb" >/dev/null
  echo "${TEMP_PATH}/${app_name}_${version}+armv6_armhf.deb"
}

function process_bin_package() {
  local app_name="$1"
  local version="$2"
  local bin_path="$3"
  local package_dir="$4"
  local desc="$5"

  log "INFO" "  -> preparing binary..."
  local bin_dest="${package_dir}/usr/local/bin"
  mkdir -p "${bin_dest}"
  
  cp "${bin_path}" "${bin_dest}/${app_name}"
  chmod +x "${bin_dest}/${app_name}"

  log "INFO" "  -> Creating control file..."
  mkdir -p "${package_dir}/DEBIAN"
  cat << EOF > "${package_dir}/DEBIAN/control"
Package: ${app_name}
Version: ${version}+armv6
Section: utils
Priority: optional
Architecture: armhf
Maintainer: Nicholas Wilde <noreply@email.com>
Description: ${desc}
EOF

  log "INFO" "  -> Building .deb..."
  dpkg-deb --build "${package_dir}" "${TEMP_PATH}/${app_name}_${version}+armv6_armhf.deb" >/dev/null
  echo "${TEMP_PATH}/${app_name}_${version}+armv6_armhf.deb"
}

function add_to_reprepro() {
  local deb_file="$1"
  local codenames=("${!2}")

  for dist in "${codenames[@]}"; do
    log "INFO" "  -> Adding to ${dist}..."
    reprepro -b "${REPO_DIR}" includedeb "${dist}" "${deb_file}" >/dev/null
  done
}

function process_app() {
  local config="$1"
  IFS=':' read -r repo type bin_name regex strategy <<< "${config}"
  local app_name="${bin_name}"
  
  # For CLI app 'gh', the package is named 'gh', bin is 'gh', repo is cli/cli
  if [[ "${repo}" == "cli/cli" ]]; then app_name="gh"; fi
  if [[ "${repo}" == "muesli/duf" ]]; then app_name="duf"; fi

  log "INFO" "Processing ${app_name} (${repo})..."

  if ! get_latest_version "${repo}"; then
    return 1
  fi
  get_current_version "${app_name}"

  log "DEBU" "  Latest: ${LATEST_VERSION}, Current: ${CURRENT_VERSION}"

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "  Up to date."
    return 0
  fi

  log "INFO" "  Update found: ${LATEST_VERSION}"

  # Find Asset
  local download_url
  download_url=$(echo "${JSON_RESPONSE}" | jq -r --arg regex "${regex}" '.assets[] | select(.name | test($regex)) | .browser_download_url' | head -1)

  if [ -z "${download_url}" ]; then
    log "WARN" "  No matching asset found for regex: ${regex}"
    return 1
  fi

  local filename
  filename=$(basename "${download_url}")
  local filepath="${TEMP_PATH}/${filename}"

  log "INFO" "  Downloading ${filename}..."
  curl -sL "${download_url}" -o "${filepath}"

  local final_deb=""

  if [[ "${type}" == "deb" ]]; then
    final_deb="${filepath}"
  elif [[ "${type}" == "bin" ]]; then
    local pkg_dir="${TEMP_PATH}/${app_name}_pkg"
    rm -rf "${pkg_dir}"
    final_deb=$(process_bin_package "${app_name}" "${LATEST_VERSION}" "${filepath}" "${pkg_dir}" "${DESCRIPTION}")
  elif [[ "${type}" == "tar" ]]; then
    local pkg_dir="${TEMP_PATH}/${app_name}_pkg"
    rm -rf "${pkg_dir}"
    final_deb=$(extract_and_package "${app_name}" "${LATEST_VERSION}" "${filepath}" "${strategy}" "${bin_name}" "${pkg_dir}" "${DESCRIPTION}")
  fi

  if [ -f "${final_deb}" ]; then
    add_to_reprepro "${final_deb}" CODENAMES[@]
  else
    log "ERRO" "  Failed to generate/find .deb file."
  fi
}

function main() {
  trap cleanup EXIT
  
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -d|--debug) DEBUG="true"; shift;;
      -h|--help) echo "Usage: $0 [-d]"; exit 0;;
      *) log "ERRO" "Unknown option: $1"; exit 1;;
    esac
  done

  check_root
  check_dependencies
  get_codenames
  make_temp_dir

  log "INFO" "Target Codenames: ${CODENAMES[*]}"

  for app_config in "${APPS[@]}"; do
    process_app "${app_config}"
  done

  log "INFO" "Done."
}

main "$@"
