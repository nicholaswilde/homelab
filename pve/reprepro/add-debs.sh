#!/usr/bin/env bash
################################################################################
#
# Script Name: add-debs.sh
# ----------------
# Adds all .deb files in a specified directory to the reprepro repository.
# Automatically handles standard and Raspberry Pi 1 (ARMv6) distributions.
#
# @author Nicholas Wilde, 0xb299a622
# @date 01 Dec 2025
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

Adds all .deb files in <directory> to the reprepro repository.

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

  log "INFO" "Starting bulk package import from: ${INPUT_DIR}"

  # 1. Dynamically get distributions
  log "DEBU" "Reading distribution configurations..."
  
  # Debian
  local debian_dist_file="${SCRIPT_DIR}/debian/conf/distributions"
  if [[ ! -f "${debian_dist_file}" ]]; then
    log "ERRO" "Debian distributions config not found at ${debian_dist_file}"
    exit 1
  fi
  local all_debian_codenames=($(grep -oP '(?<=Codename: ).*' "${debian_dist_file}"))
  
  # Ubuntu
  local ubuntu_dist_file="${SCRIPT_DIR}/ubuntu/conf/distributions"
  if [[ ! -f "${ubuntu_dist_file}" ]]; then
    log "ERRO" "Ubuntu distributions config not found at ${ubuntu_dist_file}"
    exit 1
  fi
  local all_ubuntu_codenames=($(grep -oP '(?<=Codename: ).*' "${ubuntu_dist_file}"))

  # Filter Standard vs Raspi
  local standard_debian_codenames=()
  local raspi_codenames=()

  for codename in "${all_debian_codenames[@]}"; do
    if [[ "${codename}" == "raspi" ]]; then
      raspi_codenames+=("${codename}")
    else
      standard_debian_codenames+=("${codename}")
    fi
  done

  log "INFO" "Standard Debian Codenames: ${standard_debian_codenames[*]}"
  log "INFO" "Ubuntu Codenames: ${all_ubuntu_codenames[*]}"
  log "INFO" "Raspberry Pi Codenames: ${raspi_codenames[*]}"

  # 2. Process files
  shopt -s nullglob
  local deb_files=("${INPUT_DIR}"/*.deb)
  
  if [ ${#deb_files[@]} -eq 0 ]; then
    log "WARN" "No .deb files found in ${INPUT_DIR}."
    exit 0
  fi

  for deb_file in "${deb_files[@]}"; do
    local filename=$(basename "${deb_file}")
    log "INFO" "Processing: ${filename}"

    local target_debian=()
    local target_ubuntu=()

    # 3. Determine targets based on filename
    if [[ "${filename}" == *"+armv6"* ]]; then
      log "INFO" "  -> Detected ARMv6 package. Targeting 'raspi' only."
      target_debian=("${raspi_codenames[@]}")
      # Ubuntu typically doesn't support armv6 in modern repos, skipping.
    else
      log "INFO" "  -> Standard package. Targeting standard Debian & Ubuntu repos."
      target_debian=("${standard_debian_codenames[@]}")
      target_ubuntu=("${all_ubuntu_codenames[@]}")
    fi

    # 4. Add to Reprepro
    # Debian
    for codename in "${target_debian[@]}"; do
      log "INFO" "  -> Adding to Debian ${codename}..."
      reprepro -b "${BASE_DIR}/debian" includedeb "${codename}" "${deb_file}" 2>&1 | log "DEBU" || log "WARN" "Failed to add to Debian ${codename} (check debug logs)"
    done

    # Ubuntu
    for codename in "${target_ubuntu[@]}"; do
      log "INFO" "  -> Adding to Ubuntu ${codename}..."
      reprepro -b "${BASE_DIR}/ubuntu" includedeb "${codename}" "${deb_file}" 2>&1 | log "DEBU" || log "WARN" "Failed to add to Ubuntu ${codename} (check debug logs)"
    done

  done

  log "INFO" "All files processed."
}

main "$@"
