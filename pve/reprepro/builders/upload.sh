#!/usr/bin/env bash
################################################################################
#
# Script Name: upload.sh
# ----------------
# Uploads built .deb files to a remote reprepro server and triggers the import.
#
# @author Nicholas Wilde, 0xb299a622
# @date 14 Dec 2025
# @version 1.0.0
#
################################################################################

set -e

# Configuration
# Default remote host, can be overridden by argument 1
REMOTE_HOST="${1:-root@reprepro.l.nicholaswilde.io}"
# Path to the homelab repository on the remote server
REMOTE_REPO_PATH="/root/git/nicholaswilde/homelab/pve/reprepro"
# Local directory containing the .deb files
LOCAL_DIST_DIR="./dist"
# Remote temporary directory for upload
REMOTE_TEMP_DIR="/tmp/reprepro-upload"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

if [ ! -d "$LOCAL_DIST_DIR" ]; then
    echo "Error: Local dist directory '$LOCAL_DIST_DIR' does not exist."
    echo "Run 'task build-all' first."
    exit 1
fi

log "Targeting remote host: $REMOTE_HOST"

log "Creating remote temp directory: $REMOTE_TEMP_DIR"
ssh "$REMOTE_HOST" "mkdir -p $REMOTE_TEMP_DIR"

log "Uploading .deb files from $LOCAL_DIST_DIR..."
scp "$LOCAL_DIST_DIR"/*.deb "$REMOTE_HOST":"$REMOTE_TEMP_DIR/"

log "Triggering remote import script..."
ssh "$REMOTE_HOST" "$REMOTE_REPO_PATH/add-debs.sh $REMOTE_TEMP_DIR"
ssh "$REMOTE_HOST" "$REMOTE_REPO_PATH/add-raspi-debs.sh $REMOTE_TEMP_DIR"

log "Cleaning up remote temp directory..."
ssh "$REMOTE_HOST" "rm -rf $REMOTE_TEMP_DIR"

success "Upload and import complete!"
