#!/usr/bin/env bash

################################################################################
#
# update
# ----------------
# Update qbittorrent
#
# @author Nicholas Wilde, 0xb299a622
# @date 07 May 2025
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
  APP=qbittorrent-nox
  if ! command_exists /opt/qbittorrent/qbittorrent-nox; then
    raise_error "No qbittorrent-nox Installation Found!"
  fi
  FULLRELEASE=$(curl -fsSL https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  RELEASE=$(echo $FULLRELEASE | cut -c 9-13)
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    print_text "Stopping Service"
    systemctl stop qbittorrent-nox
    print_text "Stopped Service"

    print_text "Updating ${APP} to v${RELEASE}"
    rm -f /opt/qbittorrent/qbittorrent-nox
    curl -fsSL "https://github.com/userdocs/qbittorrent-nox-static/releases/download/${FULLRELEASE}/x86_64-qbittorrent-nox" -o /opt/qbittorrent/qbittorrent-nox
    chmod +x /opt/qbittorrent/qbittorrent-nox
    echo "${RELEASE}" >/opt/${APP}_version.txt
    print_text "Updated $APP to v${RELEASE}"

    print_text "Starting Service"
    systemctl start qbittorrent-nox
    print_text "Started Service"
    print_text "Updated Successfully"
  else
    print_text "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit 0
}

function main(){
  check_curl
  update_script
}

main "@"
