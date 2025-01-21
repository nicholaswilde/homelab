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

# Set the URL for the GitHub releases API

dists=(debian ubuntu)
debian_codenames=(bullseye bookworm)
ubuntu_codenames=(noble oracular)
usernames=(getsops go-task)
apps=(sops task)

function get_params(){
  username="${usernames[i]}"
  export username
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
  current_version=$(reprepro --confdir /srv/reprepro/ubuntu/conf/ list noble sops | grep 'amd64'|awk '{print $NF}')
  export current_version
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

function main(){
  i=0
  for app in "${apps[@]}"; do
    export app
    export i
    get_params
    get_api_url
    get_latest_version
    get_current_version
    # check_version
    printf '%s\n' "${current_version}"
    # printf '%s\n' "${latest_version2}"
    ((i+=1))
  done
}

main "$@"
