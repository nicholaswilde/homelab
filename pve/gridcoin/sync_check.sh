#!/usr/bin/env bash
################################################################################
#
# sync_check
# ----------------
# Check if Gridcoin wallet is in sync
#
# @author Nicholas Wilde, 0xb299a622
# @date 22 Apr 2025
# @version 0.1.1
#
################################################################################

set -e
set -o pipefail

# Functions
# Check if command exists
function command_exists(){
  command -v "${1}" &> /dev/null
}

function check_jq(){
  if ! command_exists jq; then
    echo "jq is not installed"
    exit 1
  fi
}

function check_apprise(){
  if ! command_exists apprise; then
    echo "apprise is not installed"
    exit 1
  fi
}

function check_gridcoinresearchd(){
  if ! command_exists gridcoinresearchd; then
    echo "gridcoinresearchd is not installed"
    exit 1
  fi
}


function check_notification_sent(){
  if [ -f /tmp/sync_notification_sent ]; then
    echo "notification has already been sent"
    exit 0
  fi
}

function get_status_json(){
  # Get the status JSON output (replace with your actual command)
  status_json=$(gridcoinresearchd getinfo)
  export status_json
}

function get_sync_status(){
  # Extract the value of "in_sync" using jq
  in_sync=$(echo "$status_json" | jq '.in_sync')
  export in_sync
}

function check_status(){
  # Check if "in_sync" is true
  if [ "$in_sync" = true ]; then
    # Send email notification using apprise
    message="Wallet is in sync"
    apprise -t "sync_check" -b "${message}" "${EMAIL_ADDRESS}"
    touch /tmp/sync_notification_sent
  else
    blocks=$(echo "$status_json" | jq '.blocks')
    message="Wallet is not in sync, ${blocks} blocks"
  fi
  echo "${message}"
  logger -t "sync_check" "${message}"
}

function main(){
  check_jq
  check_apprise
  check_gridcoinresearchd
  check_notification_sent
  get_status_json
  get_sync_status
  check_status
}

main "$@"
