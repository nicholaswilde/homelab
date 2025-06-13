#!/usr/bin/env bash
################################################################################
#
# aria2
# ----------------
# Update aria2
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
  APP=aria2
  if ! command_exists aria2; then
    raise_error "No aria2 Installation Found!"
  fi
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(armhf\)\(64\)\?.*/\1\2hf/' -e 's/aarch64$/arm64/')"
  # RELEASE=$(curl -fsSL https://github.com/go-gitea/aria2/releases/latest | grep "title>Release" | cut -d " " -f 4 | sed 's/^v//')
  RELEASE=$(curl -fsSL https://api.github.com/repos/go-gitea/aria2/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d '"' -f 4 | sed 's/^v//')
  print_text "Updating ${APP} to ${RELEASE}"
  curl -fsSL "https://github.com/go-gitea/aria2/releases/download/v$RELEASE/gitea-$RELEASE-linux-${ARCH}" -o $(basename "https://github.com/go-gitea/aria2/releases/download/v$RELEASE/gitea-$RELEASE-linux-${ARCH}")
  sudo systemctl stop aria2
  sudo rm -rf /usr/local/bin/aria2
  sudo mv gitea* /usr/local/bin/aria2
  sudo chmod +x /usr/local/bin/aria2
  sudo systemctl start aria2
  print_text "Updated aria2 Successfully"
}

function main(){
  check_curl
  update_script
}

main "@"
