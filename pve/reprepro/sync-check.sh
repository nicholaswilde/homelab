#!/usr/bin/env bash
################################################################################
#
# sync-check
# ----------------
# Check if deb files are in sync
#
# @author Nicholas Wilde, 0xb299a622
# @date 19 Jan 2025
# @version 0.1.1
#
################################################################################

# set -e
# set -o pipefail

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
blue=$(tput setaf 4)
default=$(tput setaf 9)
white=$(tput setaf 7)

readonly bold
readonly normal
readonly red
readonly blue
readonly default
readonly white

# Set the URL for the GitHub releases API
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
debian_codenames=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/debian/conf/distributions"))
ubuntu_codenames=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/ubuntu/conf/distributions"))

dists=(debian ubuntu)
debian_codenames=(bullseye bookworm trixie)
ubuntu_codenames=(noble oracular jammy)
usernames=(getsops go-task sharkdp sharkdp)
apps=(sops task fd bat)

function print_text(){
  echo "${blue}==> ${white}${bold}${1}${normal}"
}

function raise_error(){
  printf "${red}%s\n" "${1}"
  exit 1
}

# Check if variable is set
# Returns false if empty
function is_set(){
  [ -n "${1}" ]
}

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_reprepro(){
  if ! command_exists "reprepro"; then
    raise_error "reprepro is not installed"
  fi
}

function check_jq(){
  if ! command_exists "jq"; then
    raise_error "jq is not installed"
  fi
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    raise_error "Please run as root or with sudo."
  fi
}

function make_temp_dir(){
  TEMP_PATH=$(mktemp -d)
  [ -d "${TEMP_PATH}" ] || raise_error "Could not create temp dir"
  export TEMP_PATH
  print_text "Temp path: ${TEMP_PATH}"
}

function set_vars(){
  unset PACKAGE_URL_AMD64 PACKAGE_URL_ARM64 PACKAGE_URL_ARM PACKAGE_URL_ARMHF
  unset BASENAME_AMD64 BASENAME_ARM64 BASENAME_ARM BASENAME_ARMHF
  unset FILEPATH_AMD64 FILEPATH_ARM64 FILEPATH_ARM FILEPATH_ARMHF
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  [ -f "${SCRIPT_DIR}/.env" ] && source "${SCRIPT_DIR}/.env"
  API_URL="https://api.github.com/repos/${2}/${1}/releases/latest"

  local curl_args=("-s")
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=("-H" "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  JSON_RESPONSE=$(curl "${curl_args[@]}" "${API_URL}")
  export JSON_RESPONSE

  # Check if the response contains an "assets" array. If not, something is wrong (e.g. rate limit)
  if ! echo "${JSON_RESPONSE}" | jq -e '.assets | type == "array"' >/dev/null 2>&1; then
      echo "${red}ERRO${default}[$(date +'%Y-%m-%d %H:%M:%S')] API response for ${API_URL} did not contain a valid 'assets' array."
      # Try to print the message from the API response if it exists
      API_MESSAGE=$(echo "${JSON_RESPONSE}" | jq -r '.message // ""')
      [ -n "${API_MESSAGE}" ] && echo "${red}ERRO${default}[$(date +'%Y-%m-%d %H:%M:%S')] API Message: ${API_MESSAGE}"

      # Set package URLs to empty to prevent further processing
      PACKAGE_URL_AMD64=""
      PACKAGE_URL_ARM64=""
      PACKAGE_URL_ARM=""
      PACKAGE_URL_ARMHF=""
  else
    PACKAGE_URL_AMD64=$(echo "${JSON_RESPONSE}" | jq -r '.assets[] | select(.name | contains("amd64") and endswith(".deb") and (contains("musl") | not)) | .browser_download_url')
    PACKAGE_URL_ARM64=$(echo "${JSON_RESPONSE}" | jq -r '.assets[] | select(.name | contains("arm64") and endswith(".deb") and (contains("musl") | not)) | .browser_download_url')
    PACKAGE_URL_ARM=$(echo "${JSON_RESPONSE}" | jq -r '.assets[] | select(.name | endswith("arm.deb") and (contains("musl") | not)) | .browser_download_url')
    PACKAGE_URL_ARMHF=$(echo "${JSON_RESPONSE}" | jq -r '.assets[] | select(.name | contains("armhf") and endswith(".deb") and (contains("musl") | not)) | .browser_download_url')
  fi

  BASENAME_AMD64=$(basename "${PACKAGE_URL_AMD64}" | tr -d '\r\n')
  BASENAME_ARM64=$(basename "${PACKAGE_URL_ARM64}" | tr -d '\r\n')
  BASENAME_ARM=$(basename "${PACKAGE_URL_ARM}" | tr -d '\r\n')
  BASENAME_ARMHF=$(basename "${PACKAGE_URL_ARMHF}" | tr -d '\r\n')
  FILEPATH_AMD64="${TEMP_PATH}/${BASENAME_AMD64}"
  FILEPATH_ARM64="${TEMP_PATH}/${BASENAME_ARM64}"
  FILEPATH_ARM="${TEMP_PATH}/${BASENAME_ARM}"
  FILEPATH_ARMHF="${TEMP_PATH}/${BASENAME_ARMHF}"
  export API_URL
  export PACKAGE_URL_AMD64
  export PACKAGE_URL_ARM64
  export PACKAGE_URL_ARM
  export PACKAGE_URL_ARMHF
  export BASENAME_ARM64
  export BASENAME_AMD64
  export BASENAME_ARM
  export BASENAME_ARMHF
  export FILEPATH_AMD64
  export FILEPATH_ARM64
  export FILEPATH_ARM
  export FILEPATH_ARMHF
}


# Get the latest release version from the API
function get_latest_version(){
  LATEST_VERSION=$(echo "${JSON_RESPONSE}" | jq -r .tag_name)
  # Remove the "v" prefix from the version string
  LATEST_VERSION2=${LATEST_VERSION#v}
  print_text "Latest version: ${LATEST_VERSION2}"
  export LATEST_VERSION
  export LATEST_VERSION2
}

function get_current_version(){
  APP_NAME="${1}"
  CURRENT_VERSION=$(reprepro --confdir /srv/reprepro/ubuntu/conf/ list jammy "${APP_NAME}" | grep 'amd64'| awk '{print $NF}')
  export CURRENT_VERSION
  print_text "Current version: ${CURRENT_VERSION}"
}

function add_package(){
  PACKAGE_URL="${1}"
  FILEPATH="${2}"
  print_text "Downloading ${PACKAGE_URL}"
  if ! wget -q "${PACKAGE_URL}" -O "${FILEPATH}"; then
    raise_error "Failed to download ${PACKAGE_URL}"
    return 1
  fi
  for codename in "${ubuntu_codenames[@]}"; do
    reprepro -b /srv/reprepro/ubuntu includedeb "${codename}" "${FILEPATH}"
  done
  for codename in "${debian_codenames[@]}"; do
    reprepro -b /srv/reprepro/debian includedeb "${codename}" "${FILEPATH}"
  done
}

function check_version(){
  # Compare versions
  if [[ "${LATEST_VERSION2}" != "${CURRENT_VERSION}" ]]; then
    print_text "New version available: ${LATEST_VERSION2}"
    add_package "${PACKAGE_URL_AMD64}" "${FILEPATH_AMD64}"
    add_package "${PACKAGE_URL_ARM64}" "${FILEPATH_ARM64}"
    if [[ -n "${PACKAGE_URL_ARM}" ]]; then
      add_package "${PACKAGE_URL_ARM}" "${FILEPATH_ARM}"
    fi
    if [[ -n "${PACKAGE_URL_ARMHF}" ]]; then
      add_package "${PACKAGE_URL_ARMHF}" "${FILEPATH_ARMHF}"
    fi
    MESSAGE="Added ${APP_NAME} deb files: ${LATEST_VERSION2}"
  else
    MESSAGE="${APP_NAME} is already up-to-date: ${CURRENT_VERSION}"
  fi
  print_text "${MESSAGE}"
  logger -t "sync-check" "${MESSAGE}"
}

function update_app(){
  APP_NAME="${1}"
  USERNAME="${2}"
  export APP_NAME
  get_current_version "${APP_NAME}"
  set_vars "${APP_NAME}" "${USERNAME}"
  [ -n "${PACKAGE_URL_AMD64}" ] || return
  get_latest_version "${APP_NAME}"
  check_version
}

function main(){
  check_root
  check_reprepro
  check_jq
  make_temp_dir
  for i in "${!apps[@]}"; do
    update_app "${apps[$i]}" "${usernames[$i]}"
  done
}

main "$@"
