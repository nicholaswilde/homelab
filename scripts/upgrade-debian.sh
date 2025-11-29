#!/usr/bin/env bash
################################################################################
#
# upgrade-debian.sh
# ----------------
# Upgrades Debian distribution to the next release.
#
# @author Nicholas Wilde, 0xb299a622
# @date 28 Nov 2025
# @version 0.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# Constants
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

# Logging function
function log() {
  local type="$1"
  local color="$RESET"

  if [[ "${type}" == "DEBU" ]] && [[ "${DEBUG}" != "true" ]]; then
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

# Checks if a command exists.
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  if ! command_exists apt || ! command_exists sed || ! command_exists find; then
    log "ERRO" "Required dependencies (apt, sed, find) are not installed." >&2
    exit 1
  fi
}

function pre_flight_checks() {
  if [[ "$EUID" -ne 0 ]]; then
    log "ERRO" "Please run as root"
    exit 1
  fi

  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
  else
    log "ERRO" "/etc/os-release not found."
    exit 1
  fi
  
  log "INFO" "Detected current OS: Debian ${VERSION_CODENAME}"

  if [[ "${VERSION_CODENAME}" == "bullseye" ]]; then
    TARGET_CODENAME="bookworm"
    log "INFO" "Plan: Upgrade Bullseye -> Bookworm (Step 1 of 2)"
  elif [[ "${VERSION_CODENAME}" == "bookworm" ]]; then
    TARGET_CODENAME="trixie"
    log "INFO" "Plan: Upgrade Bookworm -> Trixie (Final Step)"
  else
    log "ERRO" "Current version '${VERSION_CODENAME}' is not supported by this script."
    exit 1
  fi
  
  # Export for other functions to use
  export VERSION_CODENAME
  export TARGET_CODENAME
}

function create_snapshot() {
  if command_exists timeshift; then
    log "INFO" "Creating Timeshift snapshot..."
    # Create snapshot with description and 'Daily' tag (D)
    if timeshift --create --comments "Upgrade: ${VERSION_CODENAME} -> ${TARGET_CODENAME}" --tags D; then
        log "INFO" "Snapshot created successfully."
    else
        log "WARN" "Snapshot creation failed."
    fi
  else
    log "WARN" "Timeshift not installed or not found in PATH. Skipping system snapshot."
  fi
}

function update_current() {
  log "INFO" "Updating current packages..."
  export DEBIAN_FRONTEND=noninteractive

  apt update
  apt upgrade -y
  apt full-upgrade -y
  apt autoremove -y
}

function modify_sources() {
  log "INFO" "Switching repositories from ${VERSION_CODENAME} to ${TARGET_CODENAME}..."

  # Standard sources
  if [[ -f /etc/apt/sources.list ]]; then
    sed -i "s/${VERSION_CODENAME}/${TARGET_CODENAME}/g" /etc/apt/sources.list
  fi

  # Deb822 sources
  if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    sed -i "s/${VERSION_CODENAME}/${TARGET_CODENAME}/g" /etc/apt/sources.list.d/debian.sources
  fi

  # Third-party sources
  find /etc/apt/sources.list.d/ -name "*.list" -exec sed -i "s/${VERSION_CODENAME}/${TARGET_CODENAME}/g" {} +

  # Non-free-firmware fix for Bookworm+
  if [[ "${TARGET_CODENAME}" == "bookworm" ]]; then
    sed -i 's/non-free /non-free non-free-firmware /g' /etc/apt/sources.list
    sed -i 's/non-free$/non-free non-free-firmware/g' /etc/apt/sources.list
  fi
}

function perform_upgrade() {
  log "INFO" "Starting Full Distribution Upgrade to ${TARGET_CODENAME}..."

  apt update

  # Two-stage upgrade to handle dependency shifts safely
  # We use || true in case there are nothing to upgrade in the first step to avoid script exit on set -e
  apt upgrade --without-new-pkgs -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
  apt full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
}

function cleanup() {
  log "INFO" "Cleaning up..."
  apt autoremove -y
  apt clean
}

function check_reboot() {
  if [[ -f /var/run/reboot-required ]]; then
    log "WARN" "REBOOT IS REQUIRED"
    
    if [[ -f /var/run/reboot-required.pkgs ]]; then
      log "INFO" "The following updates triggered the reboot request:"
      sed 's/^/  - /' < /var/run/reboot-required.pkgs
    fi
    
    echo ""
    read -p "Would you like to reboot now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log "INFO" "Rebooting..."
      reboot
    fi
  else
    log "INFO" "No reboot required. Upgrade complete."
    
    if [[ "${TARGET_CODENAME}" == "bookworm" ]]; then
      log "INFO" "NOTE: You have reached Bookworm."
      log "INFO" "To reach Trixie, run this script one more time."
    fi
  fi
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting upgrade script..."
  check_dependencies
  pre_flight_checks
  create_snapshot
  update_current
  modify_sources
  perform_upgrade
  cleanup
  check_reboot
  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"