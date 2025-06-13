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

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
blue=$(tput setaf 4)
default=$(tput setaf 9)
white=$(tput setaf 7)
yellow=$(tput setaf 3)

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
  RELEASE=$(curl -fsSL https://api.github.com/repos/gethomepage/homepage/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    print_text "Updating Homepage to v${RELEASE} (Patience)"
    sudo systemctl stop homepage
    sudo curl -fsSL "https://github.com/gethomepage/homepage/archive/refs/tags/v${RELEASE}.tar.gz" -o $(basename "https://github.com/gethomepage/homepage/archive/refs/tags/v${RELEASE}.tar.gz")
    sudo tar -xzf "v${RELEASE}.tar.gz"
    sudo rm -rf "v${RELEASE}.tar.gz"
    sudo cp -r "homepage-${RELEASE}/*" "/opt/homepage/"
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
  check_curl
  update_script
}

main "@"
