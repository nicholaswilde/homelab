#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Non-interactive Vaultwarden updater. Mirrors the community-scripts Debian
# update path (cargo source build + bw_web_builds prebuild) without the
# whiptail menu so it can run via `pct exec`.
#
# @author Nicholas Wilde, 0xb299a622
# @date 10 Oct 2026
# @version 0.1.0
#
################################################################################

# Options
set -o pipefail

# Constants
APP_NAME="vaultwarden"
SERVICE_NAME="vaultwarden"
INSTALL_DIR="/opt/vaultwarden"
BIN="${INSTALL_DIR}/bin/vaultwarden"
WEB_DIR="${INSTALL_DIR}/web-vault"
SRC_DIR="/tmp/vaultwarden-src"
DEBUG="false"
SERVICE_MODE="false"
VERSION=""

# Source .env file if it exists
if [ -f "$(dirname "$0")/.env" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/.env"
fi

function log() {
  local type="$1"
  local message="$2"
  local color=""
  local reset=""
  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi
  if [[ -t 1 ]] && [[ "${SERVICE_MODE}" == "false" ]]; then
    case "$type" in
      INFO) color="\033[38;2;137;180;250m";;
      WARN) color="\033[38;2;249;226;175m";;
      ERRO) color="\033[38;2;243;139;168m";;
      DEBU) color="\033[38;2;203;166;247m";;
    esac
    reset="\033[0m"
  fi
  echo -e "${color}${type}${reset}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}"
}

function latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" | grep -m1 '"tag_name"' | cut -d '"' -f4
}

function update_server() {
  local current latest
  current=$("${BIN}" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
  latest="${VERSION:-$(latest_tag dani-garcia/vaultwarden)}"
  if [[ -z "${latest}" ]]; then
    log "ERRO" "Could not determine latest Vaultwarden release."
    return 1
  fi
  log "INFO" "Vaultwarden installed: ${current:-unknown}, target: ${latest}"
  if [[ "${current}" == "${latest}" ]]; then
    log "INFO" "Vaultwarden already up-to-date."
    return 0
  fi

  # shellcheck source=/dev/null
  source "${HOME}/.cargo/env"
  log "INFO" "Updating Rust stable toolchain (MSRV moves fast)..."
  rustup update stable || return 1
  rustup default stable || return 1
  # Prune old pinned toolchains; disk is tight and the build needs a few GB.
  rustup toolchain list | grep -v '^stable' | awk '{print $1}' | xargs -r -n1 rustup toolchain uninstall

  log "INFO" "Downloading source ${latest}..."
  rm -rf "${SRC_DIR}" && mkdir -p "${SRC_DIR}"
  curl -fsSL "https://github.com/dani-garcia/vaultwarden/archive/refs/tags/${latest}.tar.gz" \
    | tar -xz --strip-components=1 -C "${SRC_DIR}" || return 1

  log "INFO" "Building Vaultwarden ${latest} (patience)..."
  (
    cd "${SRC_DIR}" &&
    VW_VERSION="${latest}" CARGO_BUILD_JOBS="$(nproc)" CARGO_PROFILE_RELEASE_LTO=false \
      CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo build --features "sqlite,mysql,postgresql" --release
  ) || { log "ERRO" "cargo build failed."; rm -rf "${SRC_DIR}"; return 1; }

  systemctl stop "${SERVICE_NAME}"
  cp -a "${BIN}" "${BIN}.bak"
  cp "${SRC_DIR}/target/release/vaultwarden" "${BIN}"
  rm -rf "${SRC_DIR}"
  echo "${latest}" > "${HOME}/.vaultwarden"
  log "INFO" "Vaultwarden binary updated to ${latest} (previous saved as ${BIN}.bak)."
}

function update_webvault() {
  local current latest tmp
  current=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "${WEB_DIR}/vw-version.json" 2>/dev/null)
  latest=$(latest_tag dani-garcia/bw_web_builds)
  log "INFO" "Web-Vault installed: ${current:-unknown}, target: ${latest}"
  if [[ -z "${latest}" ]] || [[ "v${current}" == "${latest}" ]]; then
    log "INFO" "Web-Vault already up-to-date."
    return 0
  fi
  tmp=$(mktemp -d)
  curl -fsSL "https://github.com/dani-garcia/bw_web_builds/releases/download/${latest}/bw_web_${latest}.tar.gz" \
    | tar -xz --strip-components=1 -C "${tmp}" || { rm -rf "${tmp}"; return 1; }
  systemctl stop "${SERVICE_NAME}"
  rm -rf "${WEB_DIR}" && mv "${tmp}" "${WEB_DIR}"
  chmod 755 "${WEB_DIR}"
  chown -R root:root "${WEB_DIR}"
  echo "${latest#v}" > "${HOME}/.vaultwarden_webvault"
  log "INFO" "Web-Vault updated to ${latest}."
}

function verify() {
  systemctl start "${SERVICE_NAME}"
  sleep 3
  if curl -fsk https://localhost:8000/alive >/dev/null || curl -fs http://localhost:8000/alive >/dev/null; then
    log "INFO" "Verification succeeded: $("${BIN}" --version | head -n1)"
    return 0
  fi
  log "ERRO" "Service not responding on /alive."
  if [[ -f "${BIN}.bak" ]]; then
    log "WARN" "Rolling back binary to ${BIN}.bak..."
    systemctl stop "${SERVICE_NAME}"
    cp -a "${BIN}.bak" "${BIN}"
    systemctl start "${SERVICE_NAME}"
  fi
  return 1
}

function main() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -v|--version) VERSION="${2#v}"; shift 2;;
      -s|--service) SERVICE_MODE="true"; shift;;
      -d|--debug) DEBUG="true"; shift;;
      *) shift;;
    esac
  done

  log "INFO" "Starting ${APP_NAME} update script..."
  local rc=0
  update_server || rc=1
  update_webvault || rc=1
  verify || rc=1
  log "INFO" "Script finished."
  exit "${rc}"
}

main "$@"
