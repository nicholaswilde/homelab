#!/usr/bin/env bash
################################################################################
#
# Script Name: clear.sh
# ----------------
# Remove all packages from all distributions
#
# @author Nicholas Wilde, 0xb299a622
# @date 11 Oct 2025
# @version 0.2.0
#
################################################################################

# Options
# set -e
# set -o pipefail

# These are constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly PURPLE=$(tput setaf 5)
readonly RESET=$(tput sgr0)
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
readonly DEBIAN_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/debian/conf/distributions"))
readonly UBUNTU_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/ubuntu/conf/distributions"))

# Default variables
BASE_DIR="/srv/reprepro"
DEBUG="false"

if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  echo "ERRO[$(date +'%Y-%m-%d %H:%M:%S')] The .env file is missing. Please create it." >&2
  exit 1
fi
source "${SCRIPT_DIR}/.env"

# Logging function
function log() {
  local type="$1"
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
  if [[ -t 0 ]]; then
    local message="$2"
    echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${line}"
    done
  fi
}

function usage() {
  cat <<EOF
Usage: $0 [options]

Removes all packages from all distributions in the reprepro repository.

Options:
  -d, --debug         Enable debug mode, which prints more info.
  -h, --help          Display this help message.
EOF
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    log "ERRO" "Please run as root or with sudo."
    exit 1
  fi
}

function clear_apps(){
  log "INFO" "--------------------------------------------------"
  log "INFO" "Clearing Debian Repositories"
  log "INFO" "--------------------------------------------------"
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    log "INFO" "Checking Debian $codename..."
    for package in $(reprepro -b "${BASE_DIR}/debian/" list "$codename" | awk -F': ' '{print $2}' | awk '{print $1}' | sort -u); do
      log "INFO" "Removing $package from Debian $codename"
      reprepro -b "${BASE_DIR}/debian/" remove "$codename" "$package" 2>&1 | log "DEBU" || true
    done
  done

  log "INFO" "--------------------------------------------------"
  log "INFO" "Clearing Ubuntu Repositories"
  log "INFO" "--------------------------------------------------"

  for codename in "${UBUNTU_CODENAMES[@]}"; do
    log "INFO" "Checking Ubuntu $codename..."
    for package in $(reprepro -b "${BASE_DIR}/ubuntu/" list "$codename" | awk -F': ' '{print $2}' | awk '{print $1}' | sort -u); do
      log "INFO" "Removing $package from Ubuntu $codename"
      reprepro -b "${BASE_DIR}/ubuntu/" remove "$codename" "$package" 2>&1 | log "DEBU" || true
    done
  done
}

function main(){
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -d|--debug) DEBUG="true"; shift;;
      -h|--help) usage; exit 0;;
      *) log "ERRO" "Unknown parameter passed: $1"; usage; exit 1;;
    esac
  done

  log "INFO" "Starting clear script..."
  check_root
  clear_apps
  log "INFO" "Script finished."
}

main "$@"