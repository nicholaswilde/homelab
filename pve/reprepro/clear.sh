#!/usr/bin/env bash
################################################################################
#
# clear
# ----------------
# Remove all packages from all distributions
#
# @author Nicholas Wilde, 0xb299a622
# @date 11 Oct 2025
# @version 0.1.0
#
################################################################################

# set -e
# set -o pipefail

readonly RESET=$(tput sgr0)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)

DEBUG="false"

BASE_DIR="/srv/reprepro"

# Logging function
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  case "$type" in
    INFO)
      color="$BLUE";;
    WARN)
      color="$YELLOW";;
    ERRO)
      color="$RED";;
  esac

  echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    log "ERRO" "Please run as root or with sudo."
    exit 1
  fi
}

function set_vars(){
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  DEBIAN_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/debian/conf/distributions"))
  UBUNTU_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/ubuntu/conf/distributions"))
  [ -f "${SCRIPT_DIR}/.env" ] && source "${SCRIPT_DIR}/.env"
}

function clear_apps(){
  # Define the output target based on the DEBUG variable
  if [ "${DEBUG}" = "true" ]; then
    OUTPUT_TARGET="/dev/stdout" # Send output to the screen
  else
    OUTPUT_TARGET="/dev/null"   # Send output to the void
  fi
  log "INFO" "--------------------------------------------------"
  log "INFO" "Clearing Debian Repositories"
  log "INFO" "--------------------------------------------------"
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    log "INFO" "Checking Debian $codename..."
    for package in $(reprepro -b "${BASE_DIR}/debian/" list "$codename" | awk -F': ' '{print $2}' | awk '{print $1}' | sort -u); do
      log "INFO" "Removing $package from Debian $codename"
      reprepro -b "${BASE_DIR}/debian/" remove "$codename" "$package" &> "${OUTPUT_TARGET}" || true
    done
  done

  log "INFO" "--------------------------------------------------"
  log "INFO" "Clearing Ubuntu Repositories"
  log "INFO" "--------------------------------------------------"

  for codename in "${UBUNTU_CODENAMES[@]}"; do
    log "INFO" "Checking Ubuntu $codename..."
    for package in $(reprepro -b "${BASE_DIR}/ubuntu/" list "$codename" | awk -F': ' '{print $2}' | awk '{print $1}' | sort -u); do
      log "INFO" "Removing $package from Ubuntu $codename"
      reprepro -b "${BASE_DIR}/ubuntu/" remove "$codename" "$package" &> "${OUTPUT_TARGET}" || true
    done
  done
}

function main(){
  set_vars
  check_root
  clear_apps
}

main "$@"
