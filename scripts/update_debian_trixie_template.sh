#!/usr/bin/env bash
################################################################################
#
# Script Name: update_debian_trixie_template.sh
# ----------------
# Downloads the latest released Debian Trixie qcow2 file and creates a
# Proxmox LXC template compressed to a tar.zst file.
# Supports amd64 and arm64 architectures.
#
# @author Nicholas Wilde
# @date 04 Apr 2026
# @version 0.2.0
#
################################################################################

# Options
set -e
set -o pipefail

# These are constants
# Catppuccin Mocha Colors
readonly BLUE="\033[38;2;137;180;250m"
readonly RED="\033[38;2;243;139;168m"
readonly YELLOW="\033[38;2;249;226;175m"
readonly PURPLE="\033[38;2;203;166;247m"
readonly RESET="\033[0m"

BASE_URL="https://cloud.debian.org/images/cloud/trixie"
TEMPLATE_BASE_NAME="debian-13-trixie-rootfs"
OUTPUT_DIR="pve/installer"
DEBUG="false"

# Source .env file if it exists
if [ -f "$(dirname "$0")/.env" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/.env"
fi

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

  if [[ -n "${message}" ]]; then
    echo -e "${color}${type}${RESET}[${timestamp}] ${message}"
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[${timestamp}] ${line}"
    done
  fi

  # LogWard Integration
  if [[ -n "${LOGWARD_API_KEY}" ]]; then
    local LOGWARD_API_URL="${LOGWARD_API_URL:-https://logward.l.nicholaswilde.io/api/v1/ingest/single}"
    local LOGWARD_SERVICE_NAME="${LOGWARD_SERVICE_NAME:-$(basename "$0")}"
    local json_payload
    json_payload=$(cat <<EOF
{
  "service": "${LOGWARD_SERVICE_NAME}",
  "level": "${type}",
  "message": "${message:-$(cat)}",
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF
)
    curl -s -X POST "${LOGWARD_API_URL}" \
      -H "X-API-Key: ${LOGWARD_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "${json_payload}" >/dev/null 2>&1 &
  fi
}

# Checks if a command exists.
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  local deps=("curl" "virt-tar-out" "zstd" "grep" "sed" "uname")
  local missing=()
  for dep in "${deps[@]}"; do
    if ! command_exists "$dep"; then
      missing+=("$dep")
    fi
  done

  if [ ${#missing[@]} -ne 0 ]; then
    log "ERRO" "Required dependencies (${missing[*]}) are not installed." >&2
    exit 1
  fi
}

function detect_arch() {
  local arch
  arch=$(uname -m)
  case "${arch}" in
    x86_64)
      echo "amd64"
      ;;
    aarch64)
      echo "arm64"
      ;;
    *)
      log "ERRO" "Unsupported host architecture: ${arch}. Please specify amd64 or arm64 as an argument."
      exit 1
      ;;
  esac
}

function get_latest_version() {
  log "INFO" "Finding latest released version from ${BASE_URL}..."
  
  # Scrape HTML for directory names matching YYYYMMDD-XXXX
  local latest_folder
  latest_folder=$(curl -s "${BASE_URL}/" | \
    grep -oE '[0-9]{8}-[0-9]+' | \
    sort -V | \
    tail -1)

  if [ -z "${latest_folder}" ]; then
    log "ERRO" "Failed to find the latest released folder."
    return 1
  fi

  LATEST_VERSION="${latest_folder}"
  log "INFO" "Latest version found: ${LATEST_VERSION}"
}

function get_current_version() {
  log "INFO" "Checking current local version for ${ARCH}..."
  
  # Look for existing files in the output directory for the specified architecture
  local current_file
  current_file=$(find "${OUTPUT_DIR}" -name "${TEMPLATE_BASE_NAME}-${ARCH}-*.tar.zst" | sort -V | tail -1)
  
  if [ -z "${current_file}" ]; then
    log "WARN" "No current version found for ${ARCH} in ${OUTPUT_DIR}."
    CURRENT_VERSION="0"
    return
  fi

  # Extract version from filename: debian-13-trixie-rootfs-amd64-20260402-2435.tar.zst
  CURRENT_VERSION=$(basename "${current_file}" | sed "s/${TEMPLATE_BASE_NAME}-${ARCH}-//" | sed 's/\.tar\.zst//')
  log "INFO" "Current version for ${ARCH}: ${CURRENT_VERSION}"
}

function main() {
  local version_only="false"
  local positional_args=()

  # Parse arguments
  for arg in "$@"; do
    case "${arg}" in
      --latest)
        version_only="true"
        ;;
      amd64|arm64)
        ARCH="${arg}"
        ;;
      *)
        log "ERRO" "Invalid argument: ${arg}. Use amd64, arm64, or --latest."
        exit 1
        ;;
    esac
  done

  # Determine architecture if not already set
  if [ -z "${ARCH}" ]; then
    ARCH=$(detect_arch)
  fi

  if [ "${version_only}" == "true" ]; then
    get_latest_version > /dev/null
    echo "${LATEST_VERSION}"
    exit 0
  fi

  check_dependencies
  log "INFO" "Starting Debian Trixie LXC template update script for ${ARCH}..."

  get_latest_version
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "Template for ${ARCH} is already up-to-date: ${CURRENT_VERSION}"
    log "INFO" "Script finished."
    exit 0
  fi

  log "INFO" "New version available for ${ARCH}: ${LATEST_VERSION}"
  
  local qcow2_file="debian-13-generic-${ARCH}-${LATEST_VERSION}.qcow2"
  local download_url="${BASE_URL}/${LATEST_VERSION}/${qcow2_file}"
  local output_file="${OUTPUT_DIR}/${TEMPLATE_BASE_NAME}-${ARCH}-${LATEST_VERSION}.tar.zst"

  log "INFO" "Downloading ${qcow2_file}..."
  if ! curl -fSL -o "/tmp/${qcow2_file}" "${download_url}"; then
    log "ERRO" "Failed to download ${qcow2_file}."
    exit 1
  fi

  log "INFO" "Extracting rootfs and compressing to ${output_file}..."
  # Use virt-tar-out to extract and pipe to zstd
  # Note: virt-tar-out might require root or specific permissions
  if ! (virt-tar-out -a "/tmp/${qcow2_file}" / - | zstd -19 > "${output_file}"); then
    log "ERRO" "Failed to create LXC template from qcow2."
    rm -f "/tmp/${qcow2_file}"
    exit 1
  fi

  log "INFO" "Cleaning up temporary files..."
  rm -f "/tmp/${qcow2_file}"

  log "INFO" "Successfully created ${output_file}."
  
  # Remove old versions for this architecture
  log "INFO" "Removing old versions for ${ARCH}..."
  find "${OUTPUT_DIR}" -name "${TEMPLATE_BASE_NAME}-${ARCH}-*.tar.zst" ! -name "${TEMPLATE_BASE_NAME}-${ARCH}-${LATEST_VERSION}.tar.zst" -delete

  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"
