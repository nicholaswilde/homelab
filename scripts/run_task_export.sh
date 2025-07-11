#!/usr/bin/env bash
################################################################################
#
# Script Name: run_task_export.sh
# ----------------
# This script loops through all subdirectories in the "pve/", "docker/", and
# "vm/" folders and runs "task export" if a Taskfile.yml file exists in the
# folder.
#
# @author Nicholas Wilde, 0xb299a622
# @date 12 Jul 2025
# @version 0.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# Constants
readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly RESET=$(tput sgr0)

readonly SCRIPT_NAME=$(basename "$0")

# Logging function
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

# Dependency check function
function check_dependencies() {
  if ! command -v task &> /dev/null; then
    log "ERRO" "task command could not be found. Please install it."
    exit 1
  fi
}

# Main function
function main() {
  check_dependencies

  local parent_dirs=("../pve/" "../docker/" "../vm/")
  local current_dir
  current_dir=$(pwd)

  for dir in "${parent_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
      log "WARN" "Directory $dir not found, skipping."
      continue
    fi

    log "INFO" "Scanning subdirectories in $dir"
    for subdir in "$dir"*/; do
      if [ -d "$subdir" ]; then
        if [ -f "${subdir}Taskfile.yml" ]; then
          log "INFO" "Found Taskfile.yml in $subdir"
          cd "$subdir" || continue
          log "INFO" "Running 'task export' in $(pwd)"
          task export
          cd "$current_dir" || exit
        fi
      fi
    done
  done
  log "INFO" "Script finished."
}

# Call main to start the script
main "$@"
