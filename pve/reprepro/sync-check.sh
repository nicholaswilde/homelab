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
  # ! is_set "${VENTOY_INTALL_DIR}" && VENTOY_INSTALL_DIR="${DEFAULT_VENTOY_INSTALL_DIR}"
  # ! is_set "${FILENAME}" && FILENAME="${DEFAULT_FILENAME}"
}

function check_reprepro(){
  if ! command_exists "reprepro"; then
    raise_error "reprepro is not installed"
  fi
}

function get_api_url(){
  api_url="https://api.github.com/repos/${username}/${app}/releases/latest"
  export api_url
}

# Get the latest release version from the API
function get_latest_version(){
  latest_version=$(curl -s "$api_url" | grep '"tag_name":' | cut -d '"' -f 4)
  # Remove the "v" prefix from the version string
  latest_version2=${latest_version#v}
  export latest_version
  export latest_version2
}

function get_current_version(){
  # Get the current installed version (if any)
  # current_version=$("${app}" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  print_text "Get current version"
  APP_NAME="${1}"
  CURRENT_VERSION=$(reprepro --confdir /srv/reprepro/ubuntu/conf/ list oracular "${APP_NAME}" | grep 'amd64'| awk '{print $NF}')
  export CURRENT_VERSION
  print_text "${CURRENT_VERSION}"
}

function get_archs(){
  archs=()
  archs=(amd64 arm64)
  export archs
}

function get_filename(){
  export filename
}

function check_version(){
  # Compare versions
  if [[ "${latest_version2}" != "${current_version}" ]]; then
    printf 'New version available: %s\n' "${latest_version2}"
    get_archs
    for arch in "${archs[@]}"; do
      export arch
      printf '%s\n' "${arch}"
      # Download the .deb package
      # package_url="https://github.com/go-task/task/releases/download/${latest_version}/task_linux_arm64.deb"
      # wget "${package_url}"
# 
      # message="Downloaded task_linux_arm64.deb"
    done
    # (Optional) Install the package
    # sudo dpkg -i task_linux_arm64.deb

  else
    message="Already up-to-date: ${current_version}"
  fi
  echo "${message}"
  logger -t "sync_check" "${message}"
}

function update_app(){
  APP_NAME="${1}"
  OWNER="${2}"
  get_current_version "${APP_NAME}"  
}

function main(){
  check_reprepro
  update_app "task" "go-task"
  # update_app "sops" "go-task"
}

main "$@"
