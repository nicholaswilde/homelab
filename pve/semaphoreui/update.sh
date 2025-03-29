#!/usr/bin/env bash

################################################################################
#
# update
# ----------------
# Update Semaphore
#
# @author Nicholas Wilde, 0x08b7d7a3
# @date 29 Mar 2025
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

readonly bold
readonly normal
readonly red
readonly blue
readonly default
readonly white

function print_text(){
  echo "${blue}==> ${white}${bold}${1}${normal}"
}

function raise_error(){
  printf "${red}%s\n" "${1}"
  exit 1
}

function update_script() {
  APP="Semaphore"
  if [[ ! -f /etc/systemd/system/semaphore.service ]]; then
    raise_error "No ${APP} Installation Found!"
  fi
  RELEASE=$(curl -s https://api.github.com/repos/semaphoreui/semaphore/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    print_text "Stopping Service"
    systemctl stop semaphore
    print_text "Stopped Service"

    print_text "Updating ${APP} to v${RELEASE}"
    cd /opt
    wget -q https://github.com/semaphoreui/semaphore/releases/download/v${RELEASE}/semaphore_${RELEASE}_linux_arm64.deb
    $STD dpkg -i semaphore_${RELEASE}_linux_arm64.deb
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    print_text "Updated ${APP} to v${RELEASE}"

    print_text "Starting Service"
    systemctl start semaphore
    print_text "Started Service"

    print_text "Cleaning up"
    rm -rf /opt/semaphore_${RELEASE}_linux_arm64.deb
    print_text "Cleaned"
    print_text "Updated Successfully"
  else
    print_text "No update required. ${APP} is already at v${RELEASE}."
  fi
}

update_script