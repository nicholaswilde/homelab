#!/usr/bin/env bash
################################################################################
#
# Script Name: add-raspi-debs.sh
# ----------------
# Adds only ARMv6 .deb files (marked with +armv6) to the raspi reprepro repository.
#
# @author Nicholas Wilde, 0xb299a622
# @date 14 Dec 2025
# @version 1.0.0
#
################################################################################

# Options
set -e
set -o pipefail

# Constants
if [[ -t 1 ]]; then
  readonly BLUE=$(tput setaf 4)
  readonly RED=$(tput setaf 1)
  readonly YELLOW=$(tput setaf 3)
  readonly PURPLE=$(tput setaf 5)
  readonly RESET=$(tput sgr0)
else
  readonly BLUE=""
  readonly RED=""
  readonly YELLOW=""
  readonly PURPLE=""
  readonly RESET=""
fi

readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Load Configuration
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  echo "ERRO[$(date +'%Y-%m-%d %H:%M:%S')] The .env file is missing. Please create it." >&2
  exit 1
fi
source "${SCRIPT_DIR}/.env"

# Default variables
DEBUG="false"
INPUT_DIR=""

# --- Logging function ---
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi

  case "$type" in
    INFO) color="$BLUE";;
    WARN) color="$YELLOW";;
    ERRO) color="$RED";;
    DEBU) color="$PURPLE";;
    *)    type="LOGS";;
  esac

  echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
}

function usage() {
  cat <<EOF
Usage: $0 [options] <directory>

Adds ARMv6 .deb files in <directory> to the raspi reprepro repository.

Options:
  -d, --debug         Enable debug mode.
  -h, --help          Display this help message.
EOF
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    log "ERRO" "Please run as root or with sudo."
    exit 1
  fi
}

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! command_exists reprepro; then
    log "ERRO" "reprepro is not installed."
    exit 1
  fi
}

function main() {
  # Parse arguments
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -d|--debug) DEBUG="true"; shift;;
      -h|--help) usage; exit 0;;
      -*) log "ERRO" "Unknown option: $1"; usage; exit 1;;
      *) 
        if [[ -z "${INPUT_DIR}" ]]; then
          INPUT_DIR="$1"
        else
          log "ERRO" "Multiple directories provided. Only one is supported."; usage; exit 1
        fi
        shift;;
    esac
  done

  if [[ -z "${INPUT_DIR}" ]]; then
    log "ERRO" "No directory specified."
    usage
    exit 1
  fi

  if [[ ! -d "${INPUT_DIR}" ]]; then
    log "ERRO" "Directory not found: ${INPUT_DIR}"
    exit 1
  fi

  check_root
  check_dependencies

  log "INFO" "Starting Raspi package import from: ${INPUT_DIR}"

  # 1. Dynamically get distributions
  log "DEBU" "Reading distribution configurations..."
  
  local raspi_dist_file="${SCRIPT_DIR}/raspi/conf/distributions"
  if [[ ! -f "${raspi_dist_file}" ]]; then
    log "ERRO" "Raspi distributions config not found at ${raspi_dist_file}"
    exit 1
  fi
  local raspi_codenames=($(grep -oP '(?<=Codename: ).*' "${raspi_dist_file}"))

  log "INFO" "Raspi Codenames: ${raspi_codenames[*]}"

  # 2. Process files
  shopt -s nullglob
  local deb_files=("${INPUT_DIR}"/*+armv6*.deb)
  
  if [ ${#deb_files[@]} -eq 0 ]; then
    log "WARN" "No ARMv6 .deb files found in ${INPUT_DIR}."
    exit 0
  fi

  for deb_file in "${deb_files[@]}"; do
    local filename=$(basename "${deb_file}")
    log "INFO" "Processing: ${filename}"

    # 3. Add to Reprepro
    for codename in "${raspi_codenames[@]}"; do
      log "INFO" "  -> Adding to Raspi ${codename}..."
      reprepro -b "${BASE_DIR}/raspi" includedeb "${codename}" "${deb_file}" 2>&1 | log "DEBU" || log "WARN" "Failed to add to Raspi ${codename} (check debug logs)"
    done

  done

  log "INFO" "All ARMv6 files processed."
}

main "$@"
