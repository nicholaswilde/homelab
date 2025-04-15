#!/usr/bin/env bash
################################################################################
#
# sync-check
# ----------------
# Check if deb files are in sync
#
# @author Nicholas Wilde, 0x08b7d7a3
# @date 19 Jan 2025
# @version 0.1.0
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

dists=(debian ubuntu)
debian_codenames=(bullseye bookworm)
ubuntu_codenames=(noble oracular)
usernames=(getsops go-task)
apps=(sops task)

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
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  [ -f "${SCRIPT_DIR}/.env" ] && source "${SCRIPT_DIR}/.env"
  API_URL="https://api.github.com/repos/${2}/${1}/releases/latest"
  
  PACKAGE_URL_AMD64=$(curl -s "${API_URL}" | jq -r '.assets[] | select(.name | contains("amd64.deb")) | .browser_download_url')
  PACKAGE_URL_ARM64=$(curl -s "${API_URL}" | jq -r '.assets[] | select(.name | contains("arm64.deb")) | .browser_download_url')
  BASENAME_AMD64=$(basename "${PACKAGE_URL_AMD64}")
  BASENAME_ARM64=$(basename "${PACKAGE_URL_ARM64}")
  FILEPATH_AMD64="${TEMP_PATH}/${BASENAME_AMD64}"
  FILEPATH_ARM64="${TEMP_PATH}/${BASENAME_ARM64}"
  export API_URL
  export PACKAGE_URL_AMD64
  export PACKAGE_URL_ARM64 
  export BASENAME_ARM64
  export BASENAME_AMD64
  export FILEPATH_AMD64
  export FILEPATH_ARM64
}


# Get the latest release version from the API
function get_latest_version(){
  LATEST_VERSION=$(curl -s "$API_URL" | grep '"tag_name":' | cut -d '"' -f 4)
  # Remove the "v" prefix from the version string
  LATEST_VERSION2=${LATEST_VERSION#v}
  print_text "Latest version: ${LATEST_VERSION2}"
  export LATEST_VERSION
  export LATEST_VERSION2
}

function get_current_version(){
  APP_NAME="${1}"
  CURRENT_VERSION=$(reprepro --confdir /srv/reprepro/ubuntu/conf/ list oracular "${APP_NAME}" | grep 'amd64'| awk '{print $NF}')
  export CURRENT_VERSION
  print_text "Current version: ${CURRENT_VERSION}"
}

function add_package(){
  PACKAGE_URL="${1}"
  FILEPATH="${2}"
  wget "${PACKAGE_URL}" -q -O "${FILEPATH}"
  reprepro --confdir /srv/reprepro/ubuntu/conf/ includedeb oracular "${FILEPATH}"
  reprepro --confdir /srv/reprepro/ubuntu/conf/ includedeb noble "${FILEPATH}"
  reprepro -b /srv/reprepro/debian/ includedeb bookworm "${FILEPATH}"
  reprepro -b /srv/reprepro/debian/ includedeb bullseye "${FILEPATH}"
}

function check_version(){
  # Compare versions
  if [[ "${LATEST_VERSION2}" != "${CURRENT_VERSION}" ]]; then
    print_text "New version available: ${LATEST_VERSION2}"
    add_package "${PACKAGE_URL_AMD64}" "${FILEPATH_AMD64}"
    add_package "${PACKAGE_URL_ARM64}" "${FILEPATH_ARM64}" 
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
  update_app "task" "go-task"
  update_app "sops" "getsops"
}

main "$@"
