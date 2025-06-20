#!/usr/bin/env bash
################################################################################
#
# apache-guacamole
# ----------------
# Update apache-guacamole
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
readonly APP

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
  APP=apache-guacamole
  if ! command_exists apache-guacamole; then
    raise_error "No apache-guacamole Installation Found!"
  fi
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(armhf\)\(64\)\?.*/\1\2hf/' -e 's/aarch64$/arm64/')"
  # RELEASE=$(curl -fsSL https://github.com/go-gitea/apache-guacamole/releases/latest | grep "title>Release" | cut -d " " -f 4 | sed 's/^v//')
  RELEASE=$(curl -fsSL https://api.github.com/repos/go-gitea/apache-guacamole/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d '"' -f 4 | sed 's/^v//')
  print_text "Updating ${APP} to ${RELEASE}"
  curl -fsSL "https://github.com/go-gitea/apache-guacamole/releases/download/v$RELEASE/gitea-$RELEASE-linux-${ARCH}" -o $(basename "https://github.com/go-gitea/apache-guacamole/releases/download/v$RELEASE/gitea-$RELEASE-linux-${ARCH}")
  sudo systemctl stop apache-guacamole
  sudo rm -rf /usr/local/bin/apache-guacamole
  sudo mv gitea* /usr/local/bin/apache-guacamole
  sudo chmod +x /usr/local/bin/apache-guacamole
  sudo systemctl start apache-guacamole
  print_text "Updated apache-guacamole Successfully"
}

function main(){
  check_curl
  update_script
}

main "@"
