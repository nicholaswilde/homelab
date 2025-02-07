#!/bin/bash
################################################################################
#
# install
# ----------------
# Install Ventoy
#
# @author Nicholas Wilde, 0x08b7d7a3
# @date 07 Feb 2025
# @version 0.1.0
#
################################################################################

# Variables
INSTALL_DIR="/opt/ventoy"
FILENAME="ventoy.tar.gz"

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    printf "%s\n" "Please run as root or with sudo."
    exit 1
  fi
}

function check_xmllint(){
  if ! command_exists "xmllint"; then
    printf "%s\n" "xmllint is not installed"
    exit 1
  fi
}

# Create the installation directory if it doesn't exist
function check_dir(){
  [ -d "${INSTALL_DIR}" ] || mkdir -p "${INSTALL_DIR}"
}

function make_temp_dir(){
  TEMP_PATH=$(mktemp -d)
  export TEMP_PATH
}

# Download the Ventoy tarball
function download_app(){
  DOWNLOAD_URL=$(curl -s "https://sourceforge.net/projects/ventoy/rss?path=/" | xmllint --xpath 'string(//item[contains(link, "linux")]/link)' -)
  wget -O "${TEMP_PATH}/${FILENAME}" "${DOWNLOAD_URL}"
  # Check if the download was successful
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download Ventoy."
    exit 1
  fi
}

# Extract the tarball to the installation directory
function extract_app(){
  tar --strip-components=2 -xf "${TEMP_PATH}/${FILENAME}" -C "${INSTALL_DIR}"
}

function check_install(){
  if [ -f "${INSTALL_DIR}/VentoyWeb.sh" ]; then
    printf "%s\n" "Installation successful"
  else
    printf "%s\n" "Installation failed"
    exit 1
  fi
}

function cleanup(){
  [ -f "${TEMP_PATH}/ventoy.tar.gz" ] && rm "${TEMP_PATH}/ventoy.tar.gz"
}

function main(){
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
