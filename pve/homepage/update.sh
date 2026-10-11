#!/usr/bin/env bash
################################################################################
#
# homepage
# ----------------
# Update homepage
#
# @author Nicholas Wilde, 0xb299a622
# @date 09 Jun 2025
# @version 0.1.0
#
################################################################################

# set -e
# set -o pipefail

if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
  bold=$(tput bold)
  normal=$(tput sgr0)
  red=$(tput setaf 1)
  blue=$(tput setaf 4)
  default=$(tput setaf 9)
  white=$(tput setaf 7)
  yellow=$(tput setaf 3)
else
  bold=""
  normal=""
  red=""
  blue=""
  default=""
  white=""
  yellow=""
fi

readonly bold
readonly normal
readonly red
readonly blue
readonly default
readonly white
readonly yellow

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

function update_script() {
  APP=homepage
  if [[ ! -d /opt/homepage ]]; then
    raise_error "No ${APP} Installation Found!"
  fi
  if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
    if ! command_exists npm; then
      print_text "Installing npm ..."
      sudo apt install -y npm
      print_text "Installed npm ..."
    fi
  fi
  if ! command_exists pnpm; then
    sudo npm install -g pnpm
  fi
  # ensure that jq is installed
  if ! command_exists jq; then
    print_text "Installing jq..."
    sudo apt update -qq &>/dev/null
    sudo apt install -y jq &>/dev/null || {
      raise_error "Failed to install jq"
    }
  fi
  LOCAL_IP=$(hostname -I | awk '{print $1}')
  if [[ -n "${TARGET_VERSION}" ]]; then
    RELEASE="${TARGET_VERSION#v}"
    print_text "Target Homepage version specified: v${RELEASE}"
  else
    RELEASE=$(curl -fsSL https://api.github.com/repos/gethomepage/homepage/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  fi
  local current_ver
  current_ver=$(cat /opt/${APP}_version.txt 2>/dev/null || echo "0")
  if [[ "${RELEASE}" != "${current_ver}" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    print_text "Updating Homepage to v${RELEASE} (Patience)"
    sudo systemctl stop homepage
    local archive_name="v${RELEASE}.tar.gz"
    sudo curl -fsSL "https://github.com/gethomepage/homepage/archive/refs/tags/v${RELEASE}.tar.gz" -o "${archive_name}"
    sudo tar -xzf "${archive_name}"
    sudo rm -rf "${archive_name}"
    sudo cp -r "homepage-${RELEASE}"/. "/opt/homepage/"
    sudo rm -rf "homepage-${RELEASE}"
    cd /opt/homepage
    sudo pnpm install
    sudo npx --yes update-browserslist-db@latest
    export NEXT_PUBLIC_VERSION="v$RELEASE"
    export NEXT_PUBLIC_REVISION="source"
    export NEXT_PUBLIC_BUILDTIME=$(curl -fsSL https://api.github.com/repos/gethomepage/homepage/releases/latest | jq -r '.published_at')
    export NEXT_TELEMETRY_DISABLED=1
    pnpm build
    if [[ ! -f /opt/homepage/.env ]]; then
      echo "HOMEPAGE_ALLOWED_HOSTS=localhost:3000,${LOCAL_IP}:3000" | sudo tee /opt/homepage/.env
    fi
    sudo systemctl start homepage
    echo "${RELEASE}" | sudo tee /opt/${APP}_version.txt
    print_text "Updated Homepage to v${RELEASE}"
  else
    print_text "No update required. ${APP} is already at v${RELEASE}"
  fi
}

function main(){
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--version) TARGET_VERSION="$2"; shift 2;;
      -s|--service) SERVICE_MODE="true"; shift;;
      *) shift;;
    esac
  done

  check_curl
  update_script
}

main "$@"
