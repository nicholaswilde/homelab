#!/usr/bin/env bash
################################################################################
#
# Script Name: update.sh
# ----------------
# Installs and updates dependencies for the GitHub Action Runner:
# - Golang
# - Rust
# - Docker
# - GitHub Actions Runner
#
# @author Nicholas Wilde, 0xb299a622
# @date 29 Dec 2025
# @version 0.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# Constants
readonly BLUE="\033[38;2;137;180;250m"
readonly RED="\033[38;2;243;139;168m"
readonly YELLOW="\033[38;2;249;226;175m"
readonly PURPLE="\033[38;2;203;166;247m"
readonly RESET="\033[0m"

APP_NAME="github-runner"
INSTALL_DIR="/opt/github-runner"
RUNNER_USER="runner"
DEBUG="false"

# Source .env file
if [ -f "$(dirname "$0")/.env" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/.env"
fi

# Logging
function log() {
  local type="$1"
  local message="$2"
  local color="$RESET"

  if [ "${type}" = "DEBU" ] && [ "${DEBUG}" != "true" ]; then
    return 0
  fi

  case "$type" in
    INFO) color="$BLUE";;
    WARN) color="$YELLOW";;
    ERRO) color="$RED";;
    DEBU) color="$PURPLE";;
    *) type="LOGS";;
  esac

  local timestamp
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')
  echo -e "${color}${type}${RESET}[${timestamp}] ${message}"
}

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function install_dependencies() {
  log "INFO" "Installing system dependencies..."
  apt-get update
  apt-get install -y curl git jq sudo build-essential tar libssl-dev pkg-config
}

function install_docker() {
  if command_exists docker; then
    log "INFO" "Docker is already installed."
    return
  fi
  log "INFO" "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  usermod -aG docker "${RUNNER_USER}" || true
}

function install_golang() {
  if command_exists go; then
    log "INFO" "Golang is already installed."
    # TODO: Add update logic
    return
  fi
  log "INFO" "Installing Golang..."
  # Fetch latest version
  local go_version
  go_version=$(curl -s https://go.dev/dl/?mode=json | jq -r '.[0].version')
  local arch="amd64"
  if [[ "$(uname -m)" == "aarch64" ]]; then
    arch="arm64"
  fi
  
  wget "https://go.dev/dl/${go_version}.linux-${arch}.tar.gz" -O /tmp/go.tar.gz
  rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz
  rm /tmp/go.tar.gz
  
  # Add to path if not present
  if ! grep -q "/usr/local/go/bin" /etc/profile; then
    echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
  fi
}

function install_rust() {
  if command_exists cargo; then
    log "INFO" "Rust is already installed."
    return
  fi
  log "INFO" "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # Add to path for all users or just runner?
  # Usually rustup installs to ~/.cargo
  # We might want to install it for the runner user specifically or globally
}

function install_runner() {
  if [ -d "${INSTALL_DIR}" ] && [ -f "${INSTALL_DIR}/config.sh" ]; then
    log "INFO" "Runner is already installed in ${INSTALL_DIR}."
    return
  fi

  if [ -z "${GITHUB_TOKEN}" ] || [ -z "${GITHUB_REPO}" ]; then
    log "WARN" "GITHUB_TOKEN or GITHUB_REPO not set. Skipping runner registration."
    return
  fi

  log "INFO" "Installing GitHub Runner..."
  mkdir -p "${INSTALL_DIR}"
  id -u "${RUNNER_USER}" &>/dev/null || useradd -m "${RUNNER_USER}"
  chown "${RUNNER_USER}:${RUNNER_USER}" "${INSTALL_DIR}"

  # Get latest runner version
  local runner_version
  runner_version=$(curl -s -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name' | sed 's/v//')
  
  local arch="x64"
  if [[ "$(uname -m)" == "aarch64" ]]; then
    arch="arm64"
  fi

  log "INFO" "Downloading runner version ${runner_version} for ${arch}..."
  su - "${RUNNER_USER}" -c "curl -o ${INSTALL_DIR}/actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v${runner_version}/actions-runner-linux-${arch}-${runner_version}.tar.gz"
  su - "${RUNNER_USER}" -c "tar xzf ${INSTALL_DIR}/actions-runner.tar.gz -C ${INSTALL_DIR}"
  
  log "INFO" "Configuring runner..."
  su - "${RUNNER_USER}" -c "cd ${INSTALL_DIR} && ./config.sh --url https://github.com/${GITHUB_REPO} --token ${GITHUB_TOKEN} --name ${RUNNER_NAME:-$(hostname)} --labels ${RUNNER_LABELS:-self-hosted} --unattended"
  
  log "INFO" "Installing service..."
  cd "${INSTALL_DIR}"
  ./svc.sh install "${RUNNER_USER}"
  ./svc.sh start
}

function main() {
  log "INFO" "Starting update/install script..."
  install_dependencies
  install_docker
  install_golang
  install_rust
  install_runner
  log "INFO" "Done."
}

main "$@"
