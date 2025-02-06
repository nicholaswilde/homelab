#!/bin/bash

# Define the installation directory
INSTALL_DIR="/opt/ventoy/"

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    echo "Please run as root or with sudo."
    exit 1
  fi
}

function check_xmllint(){
  if ! command_exists "xmllint"; then
    echo "xmllint is not installed"
    exit 1
  fi
}

# Create the installation directory if it doesn't exist
function check_dir(){
  [ -d "$INSTALL_DIR" ] || mkdir -p "$INSTALL_DIR"
}

# Download the Ventoy tarball
function download_app(){
  DOWNLOAD_URL=$(curl -s "https://sourceforge.net/projects/ventoy/rss?path=/" | xmllint --xpath 'string(//item[contains(link, "linux")]/link)' -)
  wget -O ventoy.tar.gz "$DOWNLOAD_URL"
  # Check if the download was successful
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download Ventoy."
    exit 1
  fi
}

# Extract the tarball to the installation directory
function extract_app(){
  tar -xzf ventoy.tar.gz -C "$INSTALL_DIR"
}

# VENTOY_DIR=$(find "$INSTALL_DIR" -maxdepth 1 -type d -name "ventoy-*")
# 
# # Create a symbolic link for easier access (optional, but recommended)
# if [ -n "$VENTOY_DIR" ]; then
#   ln -s "$VENTOY_DIR" "$INSTALL_DIR/ventoy"
#   echo "Ventoy installed to $INSTALL_DIR/ventoy"
# else
#   echo "Error: Could not find extracted Ventoy directory."
#   exit 1
# fi
# 
# 
# echo "Installation complete."
# 
# exit 0

function cleanup(){
  rm ventoy.tar.gz
}

function main(){
  check_root  
  check_xmllint
  check_dir
  # download_app

  # cleanup
}

main "@"
