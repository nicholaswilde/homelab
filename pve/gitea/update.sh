#!/usr/bin/env bash
################################################################################
#
# update
# ----------------
# Update gitea
#
# @author Nicholas Wilde, 0xb299a622
# @date 23 Apr 2025
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

function update_script() {
   if ! command_exists gitea; then
      raise_error "No gitea Installation Found!"
   fi
   RELEASE=$(curl -fsSL https://github.com/go-gitea/gitea/releases/latest | grep "title>Release" | cut -d " " -f 4 | sed 's/^v//')
   msg_info "Updating $APP to ${RELEASE}"
   curl -fsSL "https://github.com/go-gitea/gitea/releases/download/v$RELEASE/gitea-$RELEASE-linux-amd64" -o $(basename "https://github.com/go-gitea/gitea/releases/download/v$RELEASE/gitea-$RELEASE-linux-amd64")
   sudo systemctl stop gitea
   sudo rm -rf /usr/local/bin/gitea
   sudo mv gitea* /usr/local/bin/gitea
   sudo chmod +x /usr/local/bin/gitea
   sudo systemctl start gitea
   print_text "Updated gitea Successfully"
   exit 0
}

update_script "@"