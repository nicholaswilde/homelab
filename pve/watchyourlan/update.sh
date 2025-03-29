#!/usr/bin/env bash

################################################################################
#
# update
# ----------------
# Update WatchYourLAN
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
    APP="WatchYourLAN"
    if [[ ! -f /lib/systemd/system/watchyourlan.service ]]; then
        raise_error "No ${APP} Installation Found!"
    fi
    print_text "Updating $APP"
    systemctl stop watchyourlan.service
    cp -R /data/config.yaml config.yaml
    RELEASE=$(curl -s https://api.github.com/repos/aceberg/WatchYourLAN/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d '"' -f 4)
    wget -q https://github.com/aceberg/WatchYourLAN/releases/download/$RELEASE/watchyourlan_${RELEASE}_linux_arm64.deb
    dpkg -i watchyourlan_${RELEASE}_linux_arm64.deb
    cp -R config.yaml /data/config.yaml
    sed -i 's|/etc/watchyourlan/config.yaml|/data/config.yaml|' /lib/systemd/system/watchyourlan.service
    rm watchyourlan_${RELEASE}_linux_arm64.deb config.yaml
    systemctl enable -q --now watchyourlan.service
    print_text "Updated $APP"
}

update_script