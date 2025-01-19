#!/bin/bash
################################################################################
#
# sync_check
# ----------------
# Check if Gridcoin wallet is in sync
#
# @author Nicholas Wilde, 0x08b7d7a3
# @date 27 Jul 2024
# @version 0.1.0
#
################################################################################

# set -e
# set -o pipefail

# Set the URL for the GitHub releases API
API_URL="https://api.github.com/repos/go-task/task/releases/latest"
archs=(amd64 arm64)
codenames=(bullseye bookworm)

# Get the latest release version from the API
function get_latest_version(){
  LATEST_VERSION=$(curl -s "$API_URL" | grep '"tag_name":' | cut -d '"' -f 4)
  # Remove the "v" prefix from the version string
  LATEST_VERSION=${LATEST_VERSION#v}
  export LATEST_VERSION
}

function get_current_version(){
  # Get the current installed version (if any)
  CURRENT_VERSION=$(task --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  export CURRENT_VERSION
}

function check_version(){
  # Compare versions
  if [[ "$LATEST_VERSION" != "$CURRENT_VERSION" ]]; then
    echo "New version available: $LATEST_VERSION"

    # Download the .deb package
    PACKAGE_URL="https://github.com/go-task/task/releases/download/${LATEST_VERSION}/task_linux_arm64.deb"
    wget "${PACKAGE_URL}"

    message="Downloaded task_linux_arm64.deb"

    # (Optional) Install the package
    # sudo dpkg -i task_linux_arm64.deb

  else
    message="Already up-to-date: ${CURRENT_VERSION}"
  fi
  echo "${message}"
  logger -t "sync_check" "${message}"
}

function main(){
  get_latest_version
  get_current_version
  check_version
}

main "$@"
