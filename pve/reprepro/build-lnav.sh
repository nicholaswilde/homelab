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
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# --- Dynamic Codename Detection ---
readonly DEBIAN_DIST_FILE="${SCRIPT_DIR}/debian/conf/distributions"
readonly UBUNTU_DIST_FILE="${SCRIPT_DIR}/ubuntu/conf/distributions"

if [[ ! -f "${DEBIAN_DIST_FILE}" ]] || [[ ! -f "${UBUNTU_DIST_FILE}" ]]; then
  echo "ERRO: Distribution config files not found."
  exit 1
fi

ALL_DEBIAN_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${DEBIAN_DIST_FILE}"))
ALL_UBUNTU_CODENAMES=($(grep -oP '(?<=Codename: ).*' "${UBUNTU_DIST_FILE}"))

STANDARD_DEBIAN_CODENAMES=()
RASPI_CODENAMES=()

for codename in "${ALL_DEBIAN_CODENAMES[@]}"; do
  if [[ "${codename}" == "raspi" ]]; then
    RASPI_CODENAMES+=("${codename}")
  else
    STANDARD_DEBIAN_CODENAMES+=("${codename}")
  fi
done

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
  if [[ "${IS_RASPI_ARCH}" == "true" ]]; then
     # For ARMv6/v7, we only check the raspi repo if it exists
     if [ ${#RASPI_CODENAMES[@]} -gt 0 ]; then
        dist_name=${RASPI_CODENAMES[0]}
        reprepro -b "$REPREPRO_BASE_PATH/debian" list "$dist_name" "$PKG_NAME" 2>/dev/null | awk '{print $2}' | sed 's/.*:\([0-9.+]*\).*/\1/' || echo "0.0.0"
        return
     fi
     echo "0.0.0"
     return
  fi

  # Standard check
  if [ ${#STANDARD_DEBIAN_CODENAMES[@]} -gt 0 ]; then
    dist_name=${STANDARD_DEBIAN_CODENAMES[0]}
  else
    dist_name=${ALL_UBUNTU_CODENAMES[0]}
  fi
  
  reprepro -b "$REPREPRO_BASE_PATH/debian" list "$dist_name" "$PKG_NAME" 2>/dev/null | awk '{print $2}' | sed 's/.*:\([0-9.+]*\).*/\1/' || echo "0.0.0"
}

function compare_versions() {
  dpkg --compare-versions "$1" gt "$2"
}

# --- Main build logic ---
function build_and_package() {
  local arch="$1"
  local suffix="$2"
  local host_flag="$3"
  local cxx_flags="$4"

  local version="${base_latest_version}${suffix}"
  local build_subdir="$BUILD_DIR/build_${arch}${suffix}"

  log "INFO" "Starting build for ${arch}${suffix}..."
  
  # Copy source to separate build dir to allow parallel/sequential builds
  mkdir -p "$build_subdir"
  cp -r "$BUILD_DIR/$src_dir_name/"* "$build_subdir/"
  cd "$build_subdir"

  # Configure
  log "INFO" "Configuring..."
  if [[ -n "$cxx_flags" ]]; then
    export CXXFLAGS="$cxx_flags"
    export CFLAGS="$cxx_flags"
  fi
  
  local config_cmd="./configure"
  if [[ -n "$host_flag" ]]; then
    config_cmd="$config_cmd --host=$host_flag"
  fi
  
  $config_cmd
  
  # Build
  log "INFO" "Building..."
  make -j$(nproc)

  # Package
  log "INFO" "Packaging..."
  local requires="libc6,libcurl4,libpcre2-8-0,libsqlite3-0,libtinfo6,zlib1g"

  if [ -f "/usr/bin/lnav" ]; then
    log "WARN" "Removing existing /usr/bin/lnav to avoid install conflict."
    sudo rm -f "/usr/bin/lnav"
  fi

  sudo checkinstall -y \
    --pkgname="$PKG_NAME" \
    --pkgversion="$version" \
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

  # Import
  local deb_file
  deb_file=$(find "$REPREPRO_INCOMING_DIR" -name "${PKG_NAME}_${version}-1_${arch}.deb")
  
  # Checkinstall sometimes names things differently, try wildcard if exact fail
  if [ -z "$deb_file" ]; then
     deb_file=$(find "$REPREPRO_INCOMING_DIR" -name "*.deb" -printf "%T@ %p\n" | sort -n | tail -1 | awk '{print $2}')
  fi

  if [ -z "$deb_file" ]; then
    log "ERRO" "No .deb file found after build for ${arch}${suffix}."
    return 1
  fi

  log "INFO" "Importing $deb_file into reprepro..."
  
  # Determine target dists based on arch
  local target_debian=()
  local target_ubuntu=()
  
  if [[ "$arch" == "armhf" ]]; then
      # Assume armhf targets raspi repo mostly, or standard debian/ubuntu
      if [[ "$suffix" == "+armv6" ]]; then
          target_debian=("${RASPI_CODENAMES[@]}")
      else
          # armv7 / generic armhf
          target_debian=("${STANDARD_DEBIAN_CODENAMES[@]}")
          target_ubuntu=("${ALL_UBUNTU_CODENAMES[@]}")
      fi
  else
      target_debian=("${STANDARD_DEBIAN_CODENAMES[@]}")
      target_ubuntu=("${ALL_UBUNTU_CODENAMES[@]}")
  fi

  for codename in "${target_debian[@]}"; do
    log "INFO" "Importing for debian $codename"
    sudo reprepro -b "$REPREPRO_BASE_PATH/debian" includedeb "$codename" "$deb_file"
  done

  for codename in "${target_ubuntu[@]}"; do
    log "INFO" "Importing for ubuntu $codename"
    sudo reprepro -b "$REPREPRO_BASE_PATH/ubuntu" includedeb "$codename" "$deb_file"
  done
  
  # Reset flags
  unset CXXFLAGS
  unset CFLAGS
}

function main() {
  check_dependencies

  log "INFO" "Fetching latest version information..."
  base_latest_version=$(get_latest_version)
  log "INFO" "Latest lnav version: $base_latest_version"

  # --- Cleanup and Setup ---
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR" "$REPREPRO_INCOMING_DIR"

  # --- Install build dependencies ---
  log "INFO" "Installing build dependencies..."
  sudo apt-get update
  sudo apt-get install -y automake autoconf libunistring-dev libpcre2-dev libsqlite3-dev

  # --- Download and Extract Source ---
  tarball_url=$(curl -s "$GITHUB_API_URL" | jq -r '.tarball_url')
  src_dir_name="tstack-lnav-$(curl -s $GITHUB_API_URL | jq -r '.target_commitish' | cut -c1-7)"
  
  log "INFO" "Downloading source from $tarball_url"
  curl -L "$tarball_url" | tar -xz -C "$BUILD_DIR"
  
  # Prepare source (autogen needs to run once)
  cd "$BUILD_DIR/$src_dir_name"
  ./autogen.sh
  cd "$BUILD_DIR"
  
  # 1. Native Build
  local native_arch
  native_arch=$(dpkg --print-architecture)
  build_and_package "$native_arch" "" "" ""

  # 2. Cross Compile for ARM if tools available
  if command_exists arm-linux-gnueabihf-g++; then
      log "INFO" "Cross-compiler found. Building for ARM."
      
      # ARMv6
      build_and_package "armhf" "+armv6" "arm-linux-gnueabihf" "-march=armv6 -mfpu=vfp -mfloat-abi=hard"
      
      # ARMv7
      build_and_package "armhf" "+armv7" "arm-linux-gnueabihf" "-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=hard"
  else
      log "INFO" "Cross-compiler arm-linux-gnueabihf-g++ not found. Skipping ARM builds."
      log "INFO" "Install g++-arm-linux-gnueabihf to enable cross-compilation."
  fi

  # --- Cleanup ---
  log "INFO" "Cleaning up build artifacts..."
  rm -rf "$BUILD_DIR" "$REPREPRO_INCOMING_DIR"

  log "INFO" "Build and import process completed successfully."
}

# --- Run main ---
main "$@"
