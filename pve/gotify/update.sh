#!/usr/bin/env bash
################################################################################
#
# gotify
# ----------------
# Update gotify
#
# @author Nicholas Wilde, 0xb299a622
# @date 10 Jun 2025
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
  APP=gotify
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(armhf\)\(64\)\?.*/\1\2hf/' -e 's/aarch64$/arm64/')"
  if ! command_exists "/opt/gotify/gotify-linux-${ARCH}"; then
    raise_error "No gotify Installation Found!"
  fi
  print_text "Stopping ${APP}"
  sudo systemctl stop gotify
  # RELEASE=$(curl -fsSL https://github.com/go-gitea/gotify/releases/latest | grep "title>Release" | cut -d " " -f 4 | sed 's/^v//')
  RELEASE=$(curl -fsSL https://api.github.com/repos/gotify/server/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d '"' -f 4 | sed 's/^v//')
  print_text "Updating ${APP} to ${RELEASE}"
  cd /opt/gotify
  test -f gotify-linux-${ARCH} && sudo rm -rf gotify-linux-${ARCH}
  curl -fsSL "https://github.com/gotify/server/releases/download/v$RELEASE/gitea-linux-${ARCH}.zip" -o $(basename "https://github.com/gotify/server/releases/download/v$RELEASE/gotify-linux-${ARCH}.zip")
  unzip -o gotify-linux-${ARCH}.zip
  sudo rm -rf gotify-linux-${ARCH}.zip
  sudo chmod +x gotify-linux-${ARCH}
  sudo systemctl start gotify
  print_text "Updated gotify Successfully"
}

function main(){
  check_curl
  update_script
}

main "@"
