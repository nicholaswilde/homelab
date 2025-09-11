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
  APP=installer
  if ! command_exists installer; then
    raise_error "No installer Installation Found!"
  fi
  print_text "Updating ${APP}"
  sudo systemctl stop installer.service
  sudo rm -rf /usr/local/bin/installer
  curl -s https://i.jpillora.com/installer! | bash
  sudo systemctl start installer.service
  print_text "Updated installer Successfully"
}

function main(){
  check_curl
  update_script
}

main "@"
