#!/usr/bin/env bash
################################################################################
#
# Script Name: package-ripgrep.sh
# ----------------
# Clones, builds, and packages the latest release of ripgrep for ARMv6 as a .deb file.
# Uses cargo and cargo-deb.
#
# @author Nicholas Wilde, 0xb299a622
# @date 03 Dec 2025
# @version 0.1.0
#
################################################################################

# Options
# set -e
# set -o pipefail

# These are constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly PURPLE=$(tput setaf 5)
readonly RESET=$(tput sgr0)
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Default variables
DEBUG="false"

if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  echo "ERRO[$(date +'%Y-%m-%d %H:%M:%S')] The .env file is missing. Please create it." >&2
  exit 1
fi
source "${SCRIPT_DIR}/.env"

# Logging function
function log() {
  local type="$1"
  local color="$RESET"

  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi

  case "$type" in
    INFO)
      color="$BLUE";;
    WARN)
      color="$YELLOW";;
    ERRO)
      color="$RED";;
    DEBU)
      color="$PURPLE";;
    *)
      type="LOGS";;
  esac
  if [[ -t 0 ]]; then
    local message="$2"
    echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
  else
    while IFS= read -r line; do
      echo -e "${color}${type}${RESET}[$(date +'%Y-%m-%d %H:%M:%S')] ${line}"
    done
  fi
}

function usage() {
  cat <<EOF
Usage: $0 [options]

Clones, builds, and packages the latest release of ripgrep for ARMv6 as a .deb file.

Options:
  -d, --debug         Enable debug mode, which prints more info.
  -h, --help          Display this help message.
EOF
}

# Cleanup function to remove temporary directory
function cleanup() {
  if [ -d "${TEMP_PATH}" ]; then
    log "INFO" "Cleaning up temporary directory: ${TEMP_PATH}"
    rm -rf "${TEMP_PATH}"
  fi
}

# Checks if a command exists.
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  local missing_deps=()
  local deps=(
    "curl" "jq" "git" "dpkg-deb" "tar"
  )
  for dep in "${deps[@]}"; do
    if ! command_exists "${dep}"; then
      missing_deps+=("${dep}")
    fi
  done

  if [ ${#missing_deps[@]} -ne 0 ]; then
    log "ERRO" "Required dependencies are not installed: ${missing_deps[*]}"
    exit 1
  fi

  # Check for cargo
  if command_exists "cargo"; then
    export CARGO_CMD="cargo"
  elif [ -f "$HOME/.cargo/bin/cargo" ]; then
    export CARGO_CMD="$HOME/.cargo/bin/cargo"
    export PATH="$HOME/.cargo/bin:$PATH"
  elif [ -f "/usr/local/cargo/bin/cargo" ]; then
    export CARGO_CMD="/usr/local/cargo/bin/cargo"
    export PATH="/usr/local/cargo/bin:$PATH"
  else
    log "ERRO" "cargo is not installed or not in PATH."
    exit 1
  fi

  # Check for cross-compilation linker if not on arm
  if [[ "$(uname -m)" != "arm"* ]]; then
    if ! command_exists "arm-linux-gnueabihf-gcc"; then
      log "ERRO" "arm-linux-gnueabihf-gcc not found. Required for cross-compilation."
      log "INFO" "Please install it with: sudo apt install gcc-arm-linux-gnueabihf"
      exit 1
    fi
  fi
}

function make_temp_dir(){
  export TEMP_PATH=$(mktemp -d)
  if [ ! -d "${TEMP_PATH}" ]; then
    log "ERRO" "Could not create temp dir"
    exit 1
  fi
  log "INFO" "Temp path: ${TEMP_PATH}"
}

function get_latest_version() {
  local api_url="https://api.github.com/repos/BurntSushi/ripgrep/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  export json_response=$(curl "${curl_args[@]}" "${api_url}")

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for ripgrep from GitHub API."
    echo "${json_response}"
    exit 1
  fi

  export TAG_NAME=$(echo "${json_response}" | jq -r '.tag_name')
  export RG_VERSION=$(echo "${TAG_NAME}" | sed 's/^v//')
  log "INFO" "Latest ripgrep version: ${TAG_NAME}"
}

function prepare_assets() {
  log "INFO" "Preparing assets (man page and completions)..."
  
  # Find download URL for x86_64 linux musl to extract assets
  # We need to be specific to avoid .sha256 files
  local asset_url
  asset_url=$(echo "${json_response}" | jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-musl.tar.gz")) | .browser_download_url')
  
  if [ -z "${asset_url}" ]; then
    log "ERRO" "Could not find x86_64-unknown-linux-musl asset for asset extraction."
    exit 1
  fi

  log "INFO" "Downloading assets from ${asset_url}..."
  local asset_tar="${TEMP_PATH}/assets.tar.gz"
  curl -sL "${asset_url}" -o "${asset_tar}"

  if [ ! -f "${asset_tar}" ]; then
     log "ERRO" "Failed to download assets."
     exit 1
  fi

  local deploy_dir="${TEMP_PATH}/ripgrep/deployment/deb"
  mkdir -p "${deploy_dir}"
  
  local extract_dir="${TEMP_PATH}/assets_extracted"
  mkdir -p "${extract_dir}"
  
  # Extract contents
  tar -xzf "${asset_tar}" -C "${extract_dir}"
  
  # Find and copy files
  find "${extract_dir}" -name "rg.1" -exec cp {} "${deploy_dir}/rg.1" \;
  find "${extract_dir}" -name "rg.bash" -exec cp {} "${deploy_dir}/rg.bash" \;
  find "${extract_dir}" -name "rg.fish" -exec cp {} "${deploy_dir}/rg.fish" \;
  find "${extract_dir}" -name "_rg" -exec cp {} "${deploy_dir}/_rg" \;
  
  # Verify assets
  local required_assets=("rg.1" "rg.bash" "rg.fish" "_rg")
  for asset in "${required_assets[@]}"; do
    if [ ! -f "${deploy_dir}/${asset}" ]; then
      log "ERRO" "Failed to prepare asset: ${asset}"
      exit 1
    fi
  done
  
  log "INFO" "Assets prepared successfully."
}

function ensure_cargo_deb() {
  if ! "${CARGO_CMD}" deb --version >/dev/null 2>&1; then
    log "INFO" "Installing cargo-deb..."
    "${CARGO_CMD}" install cargo-deb
  fi
}

function verify_deb() {
  local deb_file="$1"
  local expected_arch="$2"
  
  log "INFO" "Verifying ${deb_file}..."
  
  if [ ! -f "${deb_file}" ]; then
    log "ERRO" "File not found: ${deb_file}"
    return 1
  fi

  local arch
  arch=$(dpkg-deb -f "${deb_file}" Architecture)
  
  log "INFO" "Package Architecture: ${arch}"
  
  if [[ "${arch}" != "${expected_arch}" ]]; then
    log "ERRO" "Architecture mismatch! Expected ${expected_arch}, got ${arch}."
    return 1
  fi
  
  log "INFO" "Verification successful."
}

function main() {
  trap cleanup EXIT

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -d|--debug) DEBUG="true"; shift;;
      -h|--help) usage; exit 0;;
      *) log "ERRO" "Unknown parameter passed: $1"; usage; exit 1;;
    esac
  done

  log "INFO" "Starting package ripgrep script..."
  check_dependencies
  make_temp_dir
  
  ensure_cargo_deb

  get_latest_version

  log "INFO" "Cloning ripgrep..."
  git clone --depth 1 --branch "${TAG_NAME}" https://github.com/BurntSushi/ripgrep.git "${TEMP_PATH}/ripgrep" 2>&1 | log "DEBU"

  cd "${TEMP_PATH}/ripgrep"
  
  prepare_assets

  # ARMv6 target (Raspberry Pi 1/Zero)
  # Rust target: arm-unknown-linux-gnueabihf
  # This target usually enables VFPv2 which is compatible with Pi Zero.
  local target="arm-unknown-linux-gnueabihf"
  local deb_arch="armhf"
  local version_suffix="+armv6"
  local full_version="${RG_VERSION}${version_suffix}"

  log "INFO" "Building and Packaging for ${target} (Version: ${full_version})..."

  # We need to tell cargo to use the correct linker for this target
  # If we are on x86, we need to set the linker in .cargo/config.toml or env vars
  if [[ "$(uname -m)" != "arm"* ]]; then
    export CARGO_TARGET_ARM_UNKNOWN_LINUX_GNUEABIHF_LINKER="arm-linux-gnueabihf-gcc"
  fi

  # Using cargo deb
  # --no-strip might be needed if strip fails on cross compilation without correct strip tool
  # But cargo-deb usually tries to find the right strip.
  # We override the version to include +armv6
  
  "${CARGO_CMD}" deb --target "${target}" --deb-version "${full_version}" 2>&1 | log "INFO"

  # cargo deb outputs to target/<target>/debian/
  local generated_deb
  generated_deb=$(find "target/${target}/debian" -name "*.deb" -print -quit)

  if [ -z "${generated_deb}" ]; then
    log "ERRO" "No .deb file found after packaging."
    exit 1
  fi

  verify_deb "${generated_deb}" "${deb_arch}"

  log "INFO" "Copying ${generated_deb} to ${SCRIPT_DIR}"
  cp "${generated_deb}" "${SCRIPT_DIR}/"

  log "INFO" "Ripgrep package created."
  log "INFO" "Debian package: ${SCRIPT_DIR}/$(basename "${generated_deb}")"
  log "INFO" "Script finished."
}

main "$@"
