#!/usr/bin/env bash
# Usage: ./check_version.sh <package_name> <github_repo> <dist>
PKG=$1
REPO=$2
DIST=${3:-bookworm}

# Load Configuration
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_FILE="${SCRIPT_DIR}/../../.env"
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
fi

DEFAULT_BASE_URL="http://192.168.1.58/debian"
if [[ -n "${REMOTE_IP}" ]]; then
  DEFAULT_BASE_URL="http://${REMOTE_IP}/debian"
fi

BASE_URL="${4:-$DEFAULT_BASE_URL}"

# 1. Get Local Version from remote apt repo
# We check amd64 as a reference for the latest version in the repo
LOCAL_VERSION=$(curl -s "${BASE_URL}/dists/${DIST}/main/binary-amd64/Packages" | \
    grep -A 10 "^Package: ${PKG}$" | grep "^Version: " | awk '{print $2}' | head -n 1)
LOCAL_VERSION=${LOCAL_VERSION:-"0.0.0"}

# 2. Get Remote Version from GitHub
REMOTE_TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name')
REMOTE_VERSION=${REMOTE_TAG#v}

# 3. Compare
if dpkg --compare-versions "$REMOTE_VERSION" gt "$LOCAL_VERSION"; then
    echo "$REMOTE_TAG" # Return tag for build process
    exit 0
else
    exit 1 # Up to date
fi
