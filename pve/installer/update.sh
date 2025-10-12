#!/usr/bin/env bash
################################################################################
#
# installer
# ----------------
# Update installer
#
# @author Nicholas Wilde, 0xb299a622
# @date 09 Jun 2025
# @version 0.1.0
#
################################################################################

# set -e
# set -o pipefail

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
blue=$(tput setaf 4)
default=$(tput setaf 9)
white=$(tput setaf 7)
yellow=$(tput setaf 3)

readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly PURPLE=$(tput setaf 5)
readonly RESET=$(tput sgr0)

readonly bold
readonly normal
readonly red
readonly blue
readonly default
readonly white
readonly yellow

DEBUG="false"

# Define the output target based on the DEBUG variable
if [ "${DEBUG}" = "true" ]; then
  OUTPUT_TARGET="/dev/stdout" # Send output to the screen
else
  OUTPUT_TARGET="/dev/null"   # Send output to the void
fi

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
    DEBU)
      color="$PURPLE";;
  esac

  echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
}

function print_text(){
  echo "${blue}==> ${white}${bold}${1}${normal}"
}

function show_warning(){
  printf "${yellow}%s\n" "${1}${normal}"
}

function raise_error(){
  printf "${red}%s\n" "${1}${normal}"
  exit 1
}

# Check if variable is set
# Returns false if empty
function is_set(){
  [ -n "${1}" ]
}

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_url(){
  local url="${1}"
  local status=$(curl -sSL -o /dev/null -w "${http_code}" "${url}")
  if [[ "${status}" -ge 200 && "${status}" -lt 400 ]]; then
    return 0
  else
    return 1
  fi
}

function check_curl(){
  if ! command_exists curl; then
    raise_error "curl is not installed"
  fi
}

function get_latest_version() {
  local USERNAME="jpillora"
  local api_url="https://api.github.com/repos/${USERNAME}/${APP}/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  json_response=$(curl "${curl_args[@]}" "${api_url}")
  export json_response

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ${APP} from GitHub API."
    echo "${json_response}"
    # Don't exit, just return so we can continue with other apps
    return 1
  fi

  TAG_NAME=$(echo "${json_response}" | jq -r '.tag_name')
  LATEST_VERSION=${TAG_NAME#v}
  PUBLISHED_AT=$(echo "${json_response}" | jq -r '.published_at')
  SOURCE_DATE_EPOCH=$(date -d "${PUBLISHED_AT}" +%s)
  export TAG_NAME
  export LATEST_VERSION
  export SOURCE_DATE_EPOCH
  log "INFO" "Latest ${APP} version: ${LATEST_VERSION} (tag: ${TAG_NAME})"
}

function get_current_version(){
  export CURRENT_VERSION=$(installer --version 2>&1)
  log "INFO" "Current ${APP} version: ${CURRENT_VERSION}"
}

function update_script() {
  APP=installer
  log "INFO" "Starting the updating of ${APP} script..."
  if ! command_exists installer; then
    log "ERRO" "No installer Installation Found!"
    exit 1
  fi

  get_latest_version
  get_current_version

  if [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]]; then
    log "INFO" "${APP} is already up-to-date: ${CURRENT_VERSION}"
    exit 0
  fi
  
  log "INFO" "Stopping service"
  if ! sudo systemctl stop installer.service &> "${OUTPUT_TARGET}"; then
    log "ERRO" "Could not stop service"
    sudo systemctl restart installer.service
    exit 1
  fi
  log "INFO" "Removing existing installer"  
  sudo rm -rf /usr/local/bin/installer &> "${OUTPUT_TARGET}"

  if [[ -f "/usr/local/bin/installer" ]]; then
    log "ERRO" "Could not remove existing installer"
    exit 1
  fi

  log "INFO" "Updating installer"
  curl -s https://i.jpillora.com/installer! | bash &> "${OUTPUT_TARGET}"


  if ! sudo systemctl start installer.service; then
    log "ERRO" "Could not start service"
    exit 1
  fi

  get_current_version

  if [[ "${LATEST_VERSION}" != "${CURRENT_VERSION}" ]]; then
    log "ERRO" "${APP} update unsuccessful"
    exit 1
  else
    log "INFO" "${APP} update successful"
  fi
}

function main(){
  check_curl
  update_script
}

main "@"
