#!/usr/bin/env bash
################################################################################
#
# Script Name: new-doc.sh
# ----------------
# Automates the creation of new documentation files based on templates.
#
# @author Nicholas Wilde
# @date 06 Jun 2026
# @version 1.0.0
#
################################################################################

# Options
set -e
set -o pipefail

# Constants
readonly BLUE="\033[38;2;137;180;250m"
readonly RED="\033[38;2;243;139;168m"
readonly GREEN="\033[38;2;166;227;161m"
readonly YELLOW="\033[38;2;249;226;175m"
readonly RESET="\033[0m"

# Logging function
function log() {
  local level="$1"
  local msg="$2"
  local color="$RESET"
  case "$level" in
    "INFO") color="$BLUE" ;;
    "WARN") color="$YELLOW" ;;
    "ERRO") color="$RED" ;;
    "DEBU") color="$GREEN" ;;
  esac
  echo -e "${color}${level}${RESET}: ${msg}"
}

# Dependency check function
function check_dependencies() {
  if ! command -v uv &> /dev/null; then
    log "ERRO" "uv command could not be found. Please install it."
    exit 1
  fi
}

# Main logic function
function main() {
  check_dependencies

  local repo_root
  repo_root=$(git rev-parse --show-toplevel)
  local docs_dir="${repo_root}/docs"

  log "INFO" "--- New Documentation File Creation ---"

  # 1. Ask for documentation type
  echo "Select documentation type:"
  echo "  1) Application (docs/apps/)"
  echo "  2) Tool (docs/tools/)"
  echo "  3) Hardware (docs/hardware/)"
  read -p "Enter choice (1-3): " doc_type

  local output_subdir
  local template_type
  case "$doc_type" in
    1)
      output_subdir="apps"
      template_type="app"
      ;;
    2)
      output_subdir="tools"
      template_type="tool"
      ;;
    3)
      output_subdir="hardware"
      template_type="hardware"
      ;;
    *)
      log "ERRO" "Invalid choice. Exiting."
      exit 1
      ;;
  esac

  local output_dir="${docs_dir}/${output_subdir}"
  mkdir -p "$output_dir"

  # 2. Ask for APP_NAME
  read -p "Enter the application/tool/hardware name (e.g., My App): " app_name

  # Convert app_name to lowercase and replace spaces with hyphens for filename
  local filename
  filename=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--/-/g' | sed 's/^-//;s/-$//')
  local output_file="${output_dir}/${filename}.md"

  if [ -f "$output_file" ]; then
    log "ERRO" "File '$output_file' already exists. Exiting."
    exit 1
  fi

  # 3. Ask for template type (docker or generic)
  local template_file=".template.md.j2"
  if [ "$template_type" == "app" ]; then
    read -p "Is this a Docker-based application? (y/N): " is_docker
    if [[ "$is_docker" =~ ^[Yy]$ ]]; then
      template_file=".template-docker.md.j2"
    fi
  fi

  # 4. Ask for APP_PORT (optional)
  local app_port_var
  local app_port_arg=""
  read -p "Enter the default port (optional, press Enter to skip): " app_port_var
  if [ -n "$app_port_var" ]; then
    app_port_arg="-D APP_PORT=$(printf %q "$app_port_var")"
  fi

  # 5. Ask for CONFIG_PATH (optional)
  local config_path_var
  local config_path_arg=""
  read -p "Enter the configuration path (optional, press Enter to skip): " config_path_var
  if [ -n "$config_path_var" ]; then
    config_path_arg="-D CONFIG_PATH=$(printf %q "$config_path_var")"
  fi

  log "INFO" "Generating documentation file: $output_file"

  # Execute the task command via uv run jinja2 and redirect output
  (cd "$docs_dir" && uv run jinja2 "$template_file" -D APP_NAME="$(printf %q "$app_name")" $app_port_arg $config_path_arg > "$output_file")

  log "INFO" "Successfully created '$output_file'."
  log "WARN" "Remember to run 'task generate-docs-nav' to update navigation in 'zensical.toml'."
}

# Run the main function
main "$@"
