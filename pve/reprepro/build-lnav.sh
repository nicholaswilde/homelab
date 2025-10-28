#!/usr/bin/env bash
################################################################################
#
# build-lnav.sh
# ----------------
# Builds a .deb file of the latest release of lnav.
#
# @author Nicholas Wilde, 0xb299a622
# @date 28 Oct 2025
# @version 0.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# --- Constants ---
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly RESET=$(tput sgr0)

readonly GITHUB_API_URL="https://api.github.com/repos/tstack/lnav/releases/latest"
readonly REPREPRO_BASE_PATH="/srv/reprepro"
readonly REPREPRO_INCOMING_DIR="/tmp/incoming"
readonly BUILD_DIR="/tmp/build"
readonly PKG_NAME="lnav"

readonly DEBIAN_CODENAMES=("bookworm" "bullseye" "trixie")
readonly UBUNTU_CODENAMES=("jammy" "noble" "oracular")

# --- Logging function ---
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  case "$type" in
    INFO)
      color="$BLUE"
      ;;
    WARN)
      color="$YELLOW"
      ;;
    ERRO)
      color="$RED"
      ;;
  esac

  echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
}

# --- Dependency check ---
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  log "INFO" "Checking dependencies..."
  local missing_deps=0
  for cmd in curl jq automake autoconf checkinstall reprepro dpkg; do
    if ! command_exists "$cmd"; then
      log "ERRO" "Dependency missing: $cmd"
      missing_deps=$((missing_deps + 1))
    fi
  done

  if [ "$missing_deps" -gt 0 ]; then
    log "ERRO" "Please install missing dependencies."
    exit 1
  fi
}

# --- Helper functions ---
function get_latest_version() {
  curl -s "$GITHUB_API_URL" | jq -r '.tag_name' | sed 's/v//'
}

function get_reprepro_version() {
  local dist_name
  if [ ${#DEBIAN_CODENAMES[@]} -gt 0 ]; then
    dist_name=${DEBIAN_CODENAMES[0]}
  else
    dist_name=${UBUNTU_CODENAMES[0]}
  fi
  
  reprepro -b "$REPREPRO_BASE_PATH/debian" list "$dist_name" "$PKG_NAME" 2>/dev/null | awk '{print $2}' | sed 's/.*:\([0-9.]*\).*/\1/' || echo "0.0.0"
}

function compare_versions() {
  dpkg --compare-versions "$1" gt "$2"
}

# --- Main build logic ---
function main() {
  check_dependencies

  log "INFO" "Fetching latest version information..."
  local latest_version
  latest_version=$(get_latest_version)
  local current_version
  current_version=$(get_reprepro_version)

  log "INFO" "Latest lnav version: $latest_version"
  log "INFO" "Current reprepro lnav version: $current_version"

  if ! compare_versions "$latest_version" "$current_version"; then
    log "INFO" "lnav is up to date. No build needed."
    exit 0
  fi

  log "INFO" "New lnav version available. Starting build process..."

  # --- Cleanup and Setup ---
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR" "$REPREPRO_INCOMING_DIR"

  # --- Install build dependencies ---
  log "INFO" "Installing build dependencies..."
  sudo apt-get update
  sudo apt-get install -y automake autoconf libunistring-dev libpcre2-dev libsqlite3-dev

  # --- Download and Extract ---
  local tarball_url
  tarball_url=$(curl -s "$GITHUB_API_URL" | jq -r '.tarball_url')
  local src_dir_name="tstack-lnav-$(curl -s $GITHUB_API_URL | jq -r '.target_commitish' | cut -c1-7)"
  
  log "INFO" "Downloading source from $tarball_url"
  curl -L "$tarball_url" | tar -xz -C "$BUILD_DIR"
  
  local build_path="$BUILD_DIR/$src_dir_name"
  cd "$build_path"

  # --- Build ---
  log "INFO" "Building lnav..."
  ./autogen.sh
  ./configure
  make

  # --- Package ---
  log "INFO" "Packaging with checkinstall..."
  local arch
  arch=$(dpkg --print-architecture)
  local description
  description=$(curl -s "$GITHUB_API_URL" | jq -r '.name')
  
  # Dependencies identified from `apt-cache depends lnav` on a Debian system
  local requires="libc6,libcurl4,libpcre2-8-0,libsqlite3-0,libtinfo6,zlib1g"

  sudo checkinstall -y \
    --pkgname="$PKG_NAME" \
    --pkgversion="$latest_version" \
    --pkgrelease="1" \
    --pkgarch="$arch" \
    --pkgsource="$tarball_url" \
    --maintainer="nicholaswilde@gmail.com" \
    --provides="$PKG_NAME" \
    --requires="$requires" \
    --pakdir="$REPREPRO_INCOMING_DIR" \
    --deldoc \
    --deldesc \
    --delspec \
    make install

  # --- Import into reprepro ---
  local deb_file
  deb_file=$(find "$REPREPRO_INCOMING_DIR" -name "*.deb")
  if [ -z "$deb_file" ]; then
    log "ERRO" "No .deb file found after build."
    exit 1
  fi

  log "INFO" "Importing $deb_file into reprepro..."
  for codename in "${DEBIAN_CODENAMES[@]}"; do
    log "INFO" "Importing for debian $codename"
    sudo reprepro -b "$REPREPRO_BASE_PATH/debian" includedeb "$codename" "$deb_file"
  done

  for codename in "${UBUNTU_CODENAMES[@]}"; do
    log "INFO" "Importing for ubuntu $codename"
    sudo reprepro -b "$REPREPRO_BASE_PATH/ubuntu" includedeb "$codename" "$deb_file"
  done

  # --- Cleanup ---
  log "INFO" "Cleaning up build artifacts..."
  rm -rf "$BUILD_DIR" "$REPREPRO_INCOMING_DIR"

  log "INFO" "Build and import process completed successfully."
}

# --- Run main ---
main "$@"
