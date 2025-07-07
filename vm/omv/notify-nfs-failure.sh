#!/usr/bin/env bash

################################################################################
#
# notify-nfs-failure
# ----------------
# A simple utility to send a notification to mailrise on an NFS service failure.
#
# @author Nicholas Wilde, 0xb299a622
# @date 06 Jul 22025
# @version 0.1.0
#
################################################################################

set -e
set -o pipefail

# Variables
SMTP_SERVER="smtp://smtp.l.nicholaswilde.io:8025"
TO_ADDRESS="all@mailrise.xyz"

readonly SMTP_SERVER
readonly NFS_SERVICE
readonly TO_ADDRESS

function set_vars(){
  HOSTNAME=$(hostname)
  UNIT_NAME="%n" # systemd variable for the unit name that failed
}

function send_notification(){
  # NFS service is down, send notification
  MESSAGE="NFS service on $HOSTNAME is DOWN! Check OpenMediaVault immediately."
  TITLE="🚨 OMV NFS DOWN! 🚨"
  TAGS="warning,nfs,omv,down"
  PRIORITY="urgent" # Priority 5 for urgent (highest)

  curl -fsSL \
      --url 'smtp://smtp.l.nicholaswilde.io:8025' \
      --mail-from 'nfs@omv.com' \
      --mail-rcpt ${TO_ADDRESS} \
      --upload-file - <<EOF
From: OMV NFS <nfs@omv.com>
To: ${TO_ADDRESS}
Subject: ${TITLE}

${MESSAGE} (Unit: ${UNIT_NAME})
EOF
  # Log to syslog for historical record on the OMV server
  logger -t "notify-nfs-failure" "NFS service on $HOSTNAME is DOWN. Sent notification."
}

function main(){
  set_vars
  send_notification
}

main "@"
