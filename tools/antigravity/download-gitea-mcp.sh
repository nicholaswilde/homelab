#!/usr/bin/env bash
################################################################################
#
# download-gitea-mcp.sh
# ----------------
# Download the latest gitea-mcp binary from gitea.com
#
# @author Nicholas Wilde, 0xb299a622
# @date 03 Jan 2026
# @version 0.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# Catppuccin Mocha Colors
BLUE="\033[38;2;137;180;250m"
readonly BLUE
RED="\033[38;2;243;139;168m"
readonly RED
YELLOW="\033[38;2;249;226;175m"
readonly YELLOW
PURPLE="\033[38;2;203;166;247m"
readonly PURPLE
RESET="\033[0m"
readonly RESET
DEBUG="false"

# Constants
REPO="gitea/gitea-mcp"
readonly REPO
API_URL="https://gitea.com/api/v1/repos/${REPO}/releases/latest"
readonly API_URL

# Logging function
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi

  case "$type" in
    INFO)
      color="$BLUE";;
    WARN)
      color="$YELLOW";;
    ERRO)
      color="$RED";;
    DEBU)
      color="$PURPLE";;
    *)
      type="LOGS";;
  esac

  local timestamp
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')

  if [[ -t 0 ]]; then
    echo -e "${color}${type}${RESET}[${timestamp}] ${message}" >&2
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[${timestamp}] ${line}" >&2
    done
  fi
}

# Checks if a command exists.
function commandExists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! commandExists curl || ! commandExists jq || ! commandExists tar ; then
    log "ERRO" "Required dependencies (curl, jq, tar) are not installed." >&2
    exit 1
  fi
}

function get_latest_release() {
  log "INFO" "Fetching latest release information..."
  local release_info
  release_info=$(curl -s "${API_URL}")
  if [[ -z "${release_info}" ]]; then
    log "ERRO" "Failed to fetch release information from ${API_URL}"
    exit 1
  fi
  echo "${release_info}"
}

function download_binary() {
  local release_info="$1"
  local os
  os=$(uname -s)
  local arch
  arch=$(uname -m)

  log "INFO" "Detecting OS and Architecture: ${os} ${arch}"

  case "${os}" in
    Linux)
      os_name="Linux"
      ;;
    Darwin)
      os_name="Darwin"
      ;;
    *)
      log "ERRO" "Unsupported OS: ${os}"
      exit 1
      ;;
  esac

  case "${arch}" in
    x86_64)
      arch_name="x86_64"
      ;;
    aarch64|arm64)
      arch_name="arm64"
      ;;
    *)
      log "ERRO" "Unsupported Architecture: ${arch}"
      exit 1
      ;;
  esac

  local asset_name="gitea-mcp_${os_name}_${arch_name}.tar.gz"
  log "INFO" "Looking for asset: ${asset_name}"

  local download_url
  download_url=$(echo "${release_info}" | jq -r ".assets[] | select(.name == \"${asset_name}\") | .browser_download_url")

  if [[ -z "${download_url}" || "${download_url}" == "null" ]]; then
    log "ERRO" "Could not find download URL for ${asset_name}"
    exit 1
  fi

  log "INFO" "Downloading ${asset_name} from ${download_url}..."
  curl -L -o "${asset_name}" "${download_url}"

  log "INFO" "Extracting ${asset_name}..."
  tar -xzf "${asset_name}" gitea-mcp

  log "INFO" "Cleaning up..."
  rm "${asset_name}"

  log "INFO" "gitea-mcp successfully downloaded and extracted."
}

function main() {
  check_dependencies
  local release_info
  release_info=$(get_latest_release)
  download_binary "${release_info}"
}

main "$@"
