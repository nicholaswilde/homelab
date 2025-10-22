#!/usr/bin/env bash
################################################################################
#
# Script Name: build-neovim.sh
# ----------------
# Builds and packages the latest release of Neovim for multiple architectures
# using Docker.
#
# @author Nicholas Wilde, 0xb299a622
# @date 22 Oct 2025
# @version 1.0.0
#
################################################################################

set -e

# Constants
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
readonly DIST_DIR="${SCRIPT_DIR}/dist"

# Logging function
log() {
  local type="$1"
  local message="$2"
  echo "[$type] $(date +'%Y-%m-%d %H:%M:%S') ${message}"
}

main() {
  cd "${SCRIPT_DIR}"

  log "INFO" "Starting Neovim build process..."

  log "INFO" "Creating distribution directory: ${DIST_DIR}"
  mkdir -p "${DIST_DIR}"

  log "INFO" "Building for amd64..."
  docker compose run --rm neovim-builder-amd64

  log "INFO" "Building for arm64..."
  docker compose run --rm neovim-builder-arm64

  log "INFO" "Building for armhf..."
  docker compose run --rm neovim-builder-armhf

  log "INFO" "Build process finished."
  log "INFO" "Debian packages are located in: ${DIST_DIR}"
}

main "$@"
