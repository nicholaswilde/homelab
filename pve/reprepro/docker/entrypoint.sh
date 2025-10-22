#!/usr/bin/env bash
set -e

# Constants
readonly DIST_DIR="/dist"
readonly BUILD_DIR="/build"

# Logging function
log() {
  local type="$1"
  local message="$2"
  echo "[$type] $(date +'%Y-%m-%d %H:%M:%S') ${message}"
}

# Get latest neovim version from GitHub API
get_latest_version() {
  log "INFO" "Fetching latest Neovim version..."
  local api_url="https://api.github.com/repos/neovim/neovim/releases/latest"
  local curl_args=('-s')
  if [ -n "${GITHUB_TOKEN}" ]; then
    curl_args+=('-H' "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  json_response=$(curl "${curl_args[@]}" "${api_url}")

  if ! echo "${json_response}" | jq -e '.tag_name' >/dev/null 2>&1; then
    log "ERRO" "Failed to get latest version for neovim from GitHub API."
    echo "${json_response}"
    exit 1
  fi

  TAG_NAME=$(echo "${json_response}" | jq -r '.tag_name')
  log "INFO" "Latest neovim version: ${TAG_NAME}"
}

main() {
  log "INFO" "Starting Neovim build for architecture: $(dpkg --print-architecture)"

  get_latest_version

  local tarball_url
  tarball_url=$(echo "${json_response}" | jq -r '.tarball_url')
  if [ -z "${tarball_url}" ] || [ "${tarball_url}" == "null" ]; then
    log "ERRO" "Could not find tarball URL in GitHub API response."
    echo "${json_response}"
    exit 1
  fi

  log "INFO" "Downloading and extracting neovim version ${TAG_NAME} from ${tarball_url}"
  mkdir -p "${BUILD_DIR}/neovim"
  curl -sL "${tarball_url}" | tar -xz --strip-components=1 -C "${BUILD_DIR}/neovim"

  cd "${BUILD_DIR}/neovim"

  log "INFO" "Building neovim..."
  make CMAKE_BUILD_TYPE=RelWithDebInfo

  log "INFO" "Packaging neovim..."
  cd build
  cpack -G DEB

  local deb_file
  deb_file=$(find . -maxdepth 1 -name "*.deb")

  if [ -z "${deb_file}" ]; then
    log "ERRO" "Could not find the generated .deb file."
    exit 1
  fi

  log "INFO" "Moving ${deb_file} to ${DIST_DIR}"
  mkdir -p "${DIST_DIR}"
  mv "${deb_file}" "${DIST_DIR}/"

  log "INFO" "Changing ownership of ${deb_file} to ${UID}:${GID}"
  chown "${UID}:${GID}" "${DIST_DIR}/${deb_file}"

  log "INFO" "Neovim package created successfully."
  log "INFO" "Debian package: ${DIST_DIR}/${deb_file}"
  log "INFO" "Script finished."
}

main "$@"
