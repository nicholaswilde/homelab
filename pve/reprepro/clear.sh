#!/usr/bin/env bash
################################################################################
#
# clear
# ----------------
# Remove all packages from all distributions
#
# @author Nicholas Wilde, 0xb299a622
# @date 11 Oct 2025
# @version 0.1.0
#
################################################################################

set -e
set -o pipefail

readonly BLUE=$(tput setaf 4)
readonly WHITE=$(tput setaf 7)
readonly BOLD=$(tput bold)
readonly NORMAL=$(tput sgr0)
readonly RED=$(tput setaf 1)

function raise_error(){
  printf "${RED}%s\n" "${1}"
  exit 1
}

function check_root(){
  if [ "$UID" -ne 0 ]; then
    raise_error "Please run as root or with sudo."
  fi
}

function print_text(){
  echo "${BLUE}==> ${WHITE}${BOLD}${1}${NORMAL}"
}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DEBIAN_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/debian/conf/distributions"))
UBUNTU_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${SCRIPT_DIR}/ubuntu/conf/distributions"))

function clear_apps(){
  print_text "--- Clearing Debian Repositories ---"
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    print_text "Checking Debian $codename..."
    for package in $(reprepro -b /srv/reprepro/debian/ list "$codename" | awk -F': ' '{print $2}' | awk '{print $1}' | sort -u); do
      print_text "Removing $package from Debian $codename"
      reprepro -b /srv/reprepro/debian/ remove "$codename" "$package" || true
    done
  done

  print_text "--- Clearing Ubuntu Repositories ---"
  for codename in "${UBUNTU_CODENAMES[@]}"; do
    print_text "Checking Ubuntu $codename..."
    for package in $(reprepro -b /srv/reprepro/ubuntu/ list "$codename" | awk -F': ' '{print $2}' | awk '{print $1}' | sort -u); do
      print_text "Removing $package from Ubuntu $codename"
      reprepro -b /srv/reprepro/ubuntu/ remove "$codename" "$package" || true
    done
  done
}

function main(){
  check_root
  clear_apps
}

main "$@"
