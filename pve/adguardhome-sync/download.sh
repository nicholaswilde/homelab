#!/bin/bash
################################################################################
#
# download_adguardhome_sync
# ----------------
# Download the latest version of adguardhome-sync
#
# @author Nicholas Wilde, 0x08b7d7a3
# @date 27 Jul 2024
# @version 0.1.0
#
################################################################################

set -e
set -o pipefail

# Replace these with the actual repository owner and name
owner="bakito"
repo="adguardhome-sync"

# Functions
# Check if command exists
function command_exists(){
  command -v "${1}" &> /dev/null
}

function check_jq(){
  if ! command_exists jq; then
    echo "jq is not installed"
    exit 1
  fi
}

# Get the latest release tag
function get_latest_tag(){
  latest_tag=$(curl -s https://api.github.com/repos/$owner/$repo/releases/latest | jq -r '.tag_name')
  export latest_tag
}

# Get the download URL of the asset
# Replace 'your-asset-name' with the actual name of the asset you want to download
function get_asset_url(){
  asset_url=$(curl -s https://api.github.com/repos/$owner/$repo/releases/latest \
    | jq -r '.assets[] | select(.name | contains("linux_amd64.tar.gz")).browser_download_url')
  export asset_url
}

function download_asset(){
  wget ${asset_url}
  downloaded_filename=$(basename ${asset_url})
  export downloaded_filename
}

function extract_asset(){
  mkdir tmp
  tar -xvf ${downloaded_filename} -C ./tmp
  ls ./tmp
  # Print the filename
  echo "Downloaded filename: $downloaded_filename" 
}

function main(){
  check_jq
  get_latest_tag
  get_asset_url
  download_asset
  extract_asset
}

main "@"
