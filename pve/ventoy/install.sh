#!/bin/bash
################################################################################
#
# install
# ----------------
# Install Ventoy
#
# @author Nicholas Wilde, 0xb299a622
# @date 11 Feb 2025
# @version 0.2.1
#
################################################################################

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
blue=$(tput setaf 4)
default=$(tput setaf 9)
white=$(tput setaf 7)

# Variables
DEFAULT_VENTOY_INSTALL_DIR="/opt/ventoy"
DEFAULT_FILENAME="ventoy.tar.gz"

readonly bold
readonly normal
readonly red
readonly blue
readonly default
readonly white

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
  ! is_set "${VENTOY_INTALL_DIR}" && VENTOY_INSTALL_DIR="${DEFAULT_VENTOY_INSTALL_DIR}"
  ! is_set "${FILENAME}" && FILENAME="${DEFAULT_FILENAME}"
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    raise_error "Please run as root or with sudo."
  fi
}

function check_xmllint(){
  if ! command_exists "xmllint"; then
    raise_error "xmllint is not installed"
  fi
}

# Create the installation directory if it doesn't exist
function check_dir(){
  [ -d "${VENTOY_INSTALL_DIR}" ] || mkdir -p "${VENTOY_INSTALL_DIR}"
}

function make_temp_dir(){
  print_text "Make temp dir"
  TEMP_PATH=$(mktemp -d)
  export TEMP_PATH
}

# Download the Ventoy tarball
function download_app(){
  print_text "Download Ventoy"
  DOWNLOAD_URL=$(curl -s "https://sourceforge.net/projects/ventoy/rss?path=/" | xmllint --xpath 'string(//item[contains(link, "linux")]/link)' -)
  wget -O "${TEMP_PATH}/${FILENAME}" "${DOWNLOAD_URL}"
  # Check if the download was successful
  if [ $? -ne 0 ]; then
    raise_error "Error: Failed to download Ventoy."
  fi
}

# Extract the tarball to the installation directory
function extract_app(){
  print_text "Extract tarball"
  tar --strip-components=2 -xf "${TEMP_PATH}/${FILENAME}" -C "${VENTOY_INSTALL_DIR}"
}

function check_install(){
  print_text "Check installation"
  if [ -f "${VENTOY_INSTALL_DIR}/VentoyWeb.sh" ]; then
    print_text "Installation successful"
  else
    raise_error "Installation failed"
  fi
}

function cleanup(){
  [ -f "${TEMP_PATH}/ventoy.tar.gz" ] && rm "${TEMP_PATH}/ventoy.tar.gz"
}

function main(){
  set_vars
  check_root  
  check_xmllint
  check_dir
  make_temp_dir
  download_app
  extract_app
  cleanup
  check_install
  exit 0
}

main "@"
