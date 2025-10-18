#!/usr/bin/env bash
################################################################################
#
# Script Name: update-reprepro.sh
# ----------------
# Downloads application tar.gz and .deb files, packages them as needed, and
# adds them to a reprepro repository.
#
# Combines the functionality of package-apps.sh and sync-check.sh.
#
# @author Nicholas Wilde, 0xb299a622
# @date 18 Oct 2025
# @version 1.0.0
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

# Default variables
BASE_DIR="/srv/reprepro"
ENABLE_NOTIFICATIONS="true"
DEBUG="true"

if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  echo "ERRO[$(date +'%Y-%m-%d %H:%M:%S')] The .env file is missing. Please create it." >&2
  exit 1
fi
source "${SCRIPT_DIR}/.env"

APPS_OUT_OF_DATE="false"
UPDATE_SUCCESS="true"
SUCCESSFUL_APPS=()
FAILED_APPS=()

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

Manages Debian packages in the reprepro repository.

This script can:
1. Download application source (tar.gz), package it into a .deb, and add it.
2. Download pre-compiled .deb packages and add them.

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
  if ! command_exists reprepro; then
    log "ERRO" "reprepro is not installed."
    exit 1
  fi
  if ! command_exists curl || ! command_exists jq || ! command_exists dpkg-deb; then
    log "ERRO" "Required dependencies (curl, jq, dpkg-deb) are not installed."
    exit 1
  fi
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    log "ERRO" "Please run as root or with sudo."
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
  local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  export json_response=$(curl "${curl_args[@]}" "${api_url}")

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ${APP_NAME} from GitHub API."
    echo "${json_response}"
    return 1
  fi

  export TAG_NAME=$(echo "${json_response}" | jq -r '.tag_name')
  export LATEST_VERSION=${TAG_NAME#v}
  export PUBLISHED_AT=$(echo "${json_response}" | jq -r '.published_at')
  export SOURCE_DATE_EPOCH=$(date -d "${PUBLISHED_AT}" +%s)
  log "INFO" "Latest ${APP_NAME} version: ${LATEST_VERSION} (tag: ${TAG_NAME})"
}

function get_current_version(){
  CURRENT_VERSION=$(reprepro --confdir "${BASE_DIR}/ubuntu/conf/" list "${UBUNTU_CODENAMES[0]}" "${APP_NAME}" 2>/dev/null | head -1 | awk '{print $NF}' | sed 's/[-+].*//' || true)
  export CURRENT_VERSION
  log "INFO" "Current ${APP_NAME} version in reprepro: ${CURRENT_VERSION}"
}

function remove_package() {
  local package_name=$1
  log "INFO" "Forcefully removing existing '${package_name}' packages from reprepro to ensure a clean state..."
  for codename in "${UBUNTU_CODENAMES[@]}"; do
    log "INFO" "Attempting to remove '${package_name}' from Ubuntu ${codename}"
    reprepro -b "${BASE_DIR}/ubuntu" remove "${codename}" "${package_name}"  2>&1 | log "DEBU" || true
  done
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    log "INFO" "Attempting to remove '${package_name}' from Debian ${codename}"
    reprepro -b "${BASE_DIR}/debian" remove "${codename}" "${package_name}"  2>&1 | log "DEBU" || true
  done

  log "INFO" "Searching for and removing old '${package_name}' .deb files from the pool..."
  find "${BASE_DIR}/debian/pool/" -name "${package_name}_*.deb" -delete
  find "${BASE_DIR}/ubuntu/pool/" -name "${package_name}_*.deb" -delete
  log "INFO" "Pool cleanup complete."
}

function extract_binary() {
  local extract_type="$1"
  local tarball_path="$2"
  local package_dir="$3"
  local folder_name="$4"
  local bin_name="$5"
  local arch_github="$7"

  log "INFO" "Extracting ${APP_NAME} binary using strategy: ${extract_type}"

  local extract_dest="${package_dir}/usr/local/bin/"

  case "${extract_type}" in
    "all")
      tar -xf "${tarball_path}" -C "${extract_dest}" 2>&1 | log "DEBU" || { log "ERRO" "Failed to extract ${tarball_path}"; return 1; }
      ;;
    "file_strip")
      tar -xf "${tarball_path}" -C "${extract_dest}" --strip-components=1 "${folder_name}/${bin_name}" 2>&1 | log "DEBU" || { log "ERRO" "Failed to extract ${tarball_path}"; return 1; }
      ;;
    "file")
      tar -xf "${tarball_path}" -C "${extract_dest}" "${bin_name}"  2>&1 | log "DEBU" || { log "ERRO" "Failed to extract ${tarball_path}"; return 1; }
      ;;
    "file_path")
      local full_bin_path="${bin_name//\$\{ARCH\}/${arch_github}}"
      local dir_path
      dir_path=$(dirname "${full_bin_path}")
      local strip_components=0
      if [ "${dir_path}" != "." ]; then
        strip_components=$(echo "${dir_path}" | awk -F'/' '{print NF}')
      fi

      tar -xf "${tarball_path}" -C "${extract_dest}" --strip-components="${strip_components}" "${full_bin_path}" 2>&1 | log "DEBU" || { log "ERRO" "Failed to extract ${full_bin_path} from ${tarball_path}"; return 1; }
      
      local extracted_bin_name
      extracted_bin_name=$(basename "${full_bin_path}")
      if [ "${extracted_bin_name}" != "${APP_NAME}" ]; then
        log "INFO" "Renaming extracted binary from ${extracted_bin_name} to ${APP_NAME}"
        mv "${extract_dest}/${extracted_bin_name}" "${extract_dest}/${APP_NAME}" || { log "ERRO" "Failed to rename binary."; return 1; }
      fi
      ;;
    *)
      log "ERRO" "Unknown extraction type: ${extract_type}"
      return 1;;
  esac
  return 0
}

function package_and_add() {
  local arch_github=$1
  local arch_debian=$2
  local tarball_name=$3
  local extract_type=$4
  local bin_name=$5
  local folder_name="${tarball_name%.tar.gz}"
  folder_name="${folder_name%.tar.bz2}"
  folder_name="${folder_name%.tbz}"

  log "INFO" "Processing architecture: ${arch_github} as ${arch_debian}"

  local download_url
  download_url=$(echo "${json_response}" | jq -r --arg pkg_name "$tarball_name" '.assets[] | select(.name==$pkg_name) | .browser_download_url')
  if [ -z "${download_url}" ]; then
    log "ERRO" "Failed to get download url for ${tarball_name}"
    return 1
  fi

  local tarball_path="${TEMP_PATH}/${tarball_name}"

  log "INFO" "Downloading ${tarball_name}..."
  wget -q "${download_url}" -O "${tarball_path}" 2>&1 | log "DEBU" || { log "ERRO" "Failed to download ${tarball_name}"; return 1; }

  local package_dir="${TEMP_PATH}/${APP_NAME}_${LATEST_VERSION}_${arch_debian}"
  mkdir -p "${package_dir}/usr/local/bin"
  mkdir -p "${package_dir}/DEBIAN"

  extract_binary "${extract_type}" "${tarball_path}" "${package_dir}" "${folder_name}" "${bin_name}" "${arch_github}" || return 1

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
  dpkg-deb --build "${package_dir}" "${TEMP_PATH}/${deb_file}" 2>&1 | log "DEBU" || { log "ERRO" "Failed to build .deb package for ${APP_NAME} ${LATEST_VERSION} ${arch_debian}"; return 1; }

  log "INFO" "Adding ${deb_file} to reprepro..."
  for codename in "${UBUNTU_CODENAMES[@]}"; do
    reprepro -b "${BASE_DIR}/ubuntu" includedeb "${codename}" "${TEMP_PATH}/${deb_file}" 2>&1 | log "DEBU" || true
  done
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    reprepro -b "${BASE_DIR}/debian" includedeb "${codename}" "${TEMP_PATH}/${deb_file}"  2>&1 | log "DEBU" || true
  done
}

function download_and_add_deb() {
  local package_name=$1
  
  log "INFO" "Processing package: ${package_name}"

  local download_url
  download_url=$(echo "${json_response}" | jq -r --arg pkg_name "$package_name" '.assets[] | select(.name==$pkg_name) | .browser_download_url')

  if [ -z "${download_url}" ]; then
    log "ERRO" "Failed to get download url for ${package_name}"
    return 1
  fi

  local package_path="${TEMP_PATH}/${package_name}"

  log "INFO" "Downloading ${package_name}..."
  wget -q "${download_url}" -O "${package_path}" || { log "ERRO" "Failed to download ${package_name}"; return 1; }

  log "INFO" "Adding ${package_name} to reprepro..."
  for codename in "${UBUNTU_CODENAMES[@]}"; do
    reprepro -b "${BASE_DIR}/ubuntu" includedeb "${codename}" "${package_path}" 2>&1 | log "DEBU" || true
  done
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    reprepro -b "${BASE_DIR}/debian" includedeb "${codename}" "${package_path}" 2>&1 | log "DEBU" || true
  done
}

function update_app_from_source() {
  local app_name="$1"
  local github_repo="$2"
  local extract_type="$3"
  local bin_name="$4"
  local arch_regexp="$5"
  export APP_NAME="${app_name}"
  export GITHUB_REPO="${github_repo}"

  log "INFO" "--------------------------------------------------"
  log "INFO" "Processing source package: ${APP_NAME}"
  log "INFO" "--------------------------------------------------"

  get_latest_version || { FAILED_APPS+=("${app_name}"); return 1; }
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date: ${CURRENT_VERSION}"
    return 0
  fi

  APPS_OUT_OF_DATE="true"
  log "INFO" "New version available for ${APP_NAME}: ${LATEST_VERSION}"

  export DESCRIPTION=$(curl -s "https://api.github.com/repos/${GITHUB_REPO}" | jq -r '.description' | sed -e 's/:\w\+://g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

  local linux_tarballs
  linux_tarballs=$(echo "${json_response}" | jq -r '.assets[] | select(.name | (endswith(".tar.gz") or endswith(".tar.bz2") or endswith(".tbz")) and (contains("openbsd") | not) and (contains("darwin") | not) and (contains("freebsd")| not) and (contains("android") | not) and (contains("windows") | not)) | .name')

  local app_update_failed="false"
  for tarball in ${linux_tarballs}; do
    local github_arch
    github_arch=$(echo "${tarball}" | grep -oP "${arch_regexp}")

    local debian_arch=""
    case "${github_arch}" in
      "amd64"|"x86_64") debian_arch="amd64";;
      "arm64"|"aarch64") debian_arch="arm64";;
      "armv7"|"armhf"|"arm") debian_arch="armhf";;
      "386") debian_arch="i386";;
      *)
        log "WARN" "Unsupported architecture for ${APP_NAME}: ${github_arch}. Skipping."
        continue;;
    esac

    package_and_add "${github_arch}" "${debian_arch}" "${tarball}" "${extract_type}" "${bin_name}" || { app_update_failed="true"; continue; }
  done

  get_current_version
  if [[ "${LATEST_VERSION}" != "${CURRENT_VERSION}" || "${app_update_failed}" == "true" ]]; then
    log "ERRO" "Failed to update ${APP_NAME} to ${LATEST_VERSION}."
    FAILED_APPS+=("${app_name}")
    return 1
  else
    log "INFO" "Successfully updated ${APP_NAME} to ${LATEST_VERSION}."
    SUCCESSFUL_APPS+=("${app_name}")
    return 0
  fi
}

function update_app_from_deb() {
  local github_repo="$1"
  export GITHUB_REPO="${github_repo}"
  export APP_NAME
  APP_NAME=$(basename "${GITHUB_REPO}")

  log "INFO" "--------------------------------------------------"
  log "INFO" "Processing deb package: ${APP_NAME}"
  log "INFO" "--------------------------------------------------"

  get_latest_version || { FAILED_APPS+=("${app_name}"); return 1; }
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${APP_NAME} is already up-to-date: ${CURRENT_VERSION}"
    return 0
  fi

  APPS_OUT_OF_DATE="true"
  log "INFO" "New version available for ${APP_NAME}: ${LATEST_VERSION}"

  local linux_debs
  linux_debs=$(echo "${json_response}" | jq -r '.assets[] | select(.name | endswith(".deb") and (contains("musl") | not)) | .name')

  local app_update_failed="false"
  for deb in ${linux_debs}; do
    download_and_add_deb "${deb}" || { app_update_failed="true"; continue; }
  done

  get_current_version
  if [[ "${LATEST_VERSION}" != "${CURRENT_VERSION}" || "${app_update_failed}" == "true" ]]; then
    log "ERRO" "Failed to update ${APP_NAME} to ${LATEST_VERSION}."
    FAILED_APPS+=("${APP_NAME}")
    return 1
  else
    log "INFO" "Successfully updated ${APP_NAME} to ${LATEST_VERSION}."
    SUCCESSFUL_APPS+=("${APP_NAME}")
    return 0
  fi
}

function send_notification(){
  if [[ "${ENABLE_NOTIFICATIONS}" == "false" ]]; then
    log "WARN" "Notifications are disabled. Skipping."
    return 0
  fi
  if [[ -z "${MAILRISE_URL}" || -z "${MAILRISE_FROM}" || -z "${MAILRISE_RCPT}" ]]; then
    log "WARN" "Notification variables not set. Skipping notification."
    return 1
  fi
  if [[ "${APPS_OUT_OF_DATE}" == "false" ]]; then
    log "INFO" "No applications were out of date. No email notification sent."
    return 0
  fi

  local EMAIL_SUBJECT=""
  local EMAIL_BODY=""
  if [[ "${UPDATE_SUCCESS}" == "true" ]]; then
    EMAIL_SUBJECT="Homelab Apps Update: Success"
    EMAIL_BODY="All out-of-date applications were successfully updated."
  else
    EMAIL_SUBJECT="Homelab Apps Update: Failure"
    EMAIL_BODY="Some out-of-date applications failed to update. Please check logs."
  fi

  if [ ${#SUCCESSFUL_APPS[@]} -gt 0 ]; then
    EMAIL_BODY+=$'\n\nSuccessfully updated:\n'
    for app in "${SUCCESSFUL_APPS[@]}"; do
      EMAIL_BODY+="- ${app}"$'\n'
    done
  fi

  if [ ${#FAILED_APPS[@]} -gt 0 ]; then
    EMAIL_BODY+=$'\n\nFailed to update:\n'
    for app in "${FAILED_APPS[@]}"; do
      EMAIL_BODY+="- ${app}"$'\n'
    done
  fi

  log "INFO" "Sending email notification..."
  curl -s \
    --url "${MAILRISE_URL}" \
    --mail-from "${MAILRISE_FROM}" \
    --mail-rcpt "${MAILRISE_RCPT}" \
    --upload-file - <<EOF
From: Reprepro <${MAILRISE_FROM}>
To: Nicholas Wilde <${MAILRISE_RCPT}>
Subject: ${EMAIL_SUBJECT}

${EMAIL_BODY}
EOF
  log "INFO" "Email notification sent."
}

# Main function to orchestrate the script execution
function main() {
  trap cleanup EXIT
  local package_to_remove=""

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -d|--debug) DEBUG="true"; shift;;
      -r|--remove)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          package_to_remove="$2"; shift 2;
        else
          log "ERRO" "Error: Argument for $1 is missing"; usage; exit 1;
        fi;;
      -h|--help) usage; exit 0;;
      *) log "ERRO" "Unknown parameter passed: $1"; usage; exit 1;;
    esac
  done

  log "INFO" "Starting reprepro update script..."
  check_root

  if [ -n "${package_to_remove}" ]; then
    remove_package "${package_to_remove}"
    log "INFO" "Script finished."
    exit 0
  fi

  check_dependencies
  make_temp_dir

  # Process apps to be packaged from source
  if [ -z "${PACKAGE_APPS-}" ]; then
    log "WARN" "PACKAGE_APPS is not defined in .env. Skipping source packaging."
  else
    for app_config in "${PACKAGE_APPS[@]}"; do
      IFS=':' read -r github_repo extract_type bin_name arch_regexp <<< "${app_config}"
      local app_name
      app_name=$(basename "${github_repo}")

      if [ -z "${extract_type}" ]; then extract_type="file"; fi
      if [ -z "${bin_name}" ]; then bin_name="${app_name}"; fi
      if [ -z "${arch_regexp}" ]; then arch_regexp='(?<=_)[^_]+(?=\.tar\.gz)'; fi
      
      update_app_from_source "${app_name}" "${github_repo}" "${extract_type}" "${bin_name}" "${arch_regexp}" || UPDATE_SUCCESS="false"
    done
  fi

  # Process pre-compiled deb apps
  if [ -z "${SYNC_APPS_GITHUB_REPOS-}" ]; then
    log "WARN" "SYNC_APPS_GITHUB_REPOS is not defined in .env. Skipping deb sync."
  else
    for github_repo in "${SYNC_APPS_GITHUB_REPOS[@]}"; do
      update_app_from_deb "${github_repo}" || UPDATE_SUCCESS="false"
    done
  fi
  
  send_notification
  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"
