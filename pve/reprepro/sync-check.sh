#!/bin/bash
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

# Check if directory exists
function dir_exists(){
  [ -d "${1}" ]
}

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function set_vars(){
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  [ -f "${SCRIPT_DIR}/.env" ] && source "${SCRIPT_DIR}/.env"
  API_URL="https://api.github.com/repos/${2}/${1}/releases/latest"
  export API_URL
  # curl -s https://api.github.com/repos/go-task/task/releases/latest | jq -r '.assets[] | select(.name | contains("amd64.deb")) | .browser_download_url'
  PACKAGE_URL="https://github.com/${2}/${1}/releases/download/${LATEST_VERSION}/task_linux_arm64.deb"
  print_text "${API_URL}"
  export PACKAGE_URL
  # ! is_set "${VENTOY_INTALL_DIR}" && VENTOY_INSTALL_DIR="${DEFAULT_VENTOY_INSTALL_DIR}"
  # ! is_set "${FILENAME}" && FILENAME="${DEFAULT_FILENAME}"
}

function check_reprepro(){
  if ! command_exists "reprepro"; then
    raise_error "reprepro is not installed"
  fi
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
  print_text "Get current version"
  APP_NAME="${1}"
  CURRENT_VERSION=$(reprepro --confdir /srv/reprepro/ubuntu/conf/ list oracular "${APP_NAME}" | grep 'amd64'| awk '{print $NF}')
  export CURRENT_VERSION
  print_text "Current version: ${CURRENT_VERSION}"
}

function check_version(){
  # Compare versions
  if [[ "${LATEST_VERSION2}" != "${CURRENT_VERSION}" ]]; then
    printf 'New version available: %s\n' "${LATEST_VERSION2}"
      # package_url="https://github.com/go-task/task/releases/download/${LATEST_VERSION}/task_linux_arm64.deb"
      # wget "${package_url}"
 
      # message="Downloaded task_linux_arm64.deb"
  else
    message="Already up-to-date: ${current_version}"
  fi
  echo "${message}"
  logger -t "sync_check" "${message}"
}

function update_app(){
  APP_NAME="${1}"
  USERNAME="${2}"
  get_current_version "${APP_NAME}"
  set_vars "${APP_NAME}" "${USERNAME}"
  get_latest_version "${APP_NAME}"
}

function main(){
  check_reprepro
  update_app "task" "go-task"
  # update_app "sops" "go-task"
}

main "$@"
