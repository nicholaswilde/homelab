#!/bin/bash
################################################################################
#
# export-task-lists
# ----------------
# Export task lists from Taskfiles using the export task.
#
# @author Nicholas Wilde, 0x08b7d7a3
# @date 27 Mar 2025
# @version 0.1.0
#
################################################################################

# set -e
# set -o pipefail

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
blue=$(tput setaf 4)
default=$(tput setaf 9)
white=$(tput setaf 7)
yellow=$(tput setaf 3)

readonly bold
readonly normal
readonly red
readonly blue
readonly default
readonly white
readonly yellow

TASK_LIST_FILENAME="task-list.txt"
TASK_TO_RUN="export" # Get task name from the first argument
START_DIR="../"   # Start searching from the current directory

function print_text(){
  echo "${blue}==> ${white}${bold}${1}${normal}"
}

function show_warning(){
  printf "${yellow}%s\n" "${1}${normal}"
}

function raise_error(){
  printf "${red}%s\n" "${1}${normal}"
  exit 1
}

# Check if variable is set
# Returns false if empty
function is_set(){
  [ -n "${1}" ]
}

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}


function check_task() {
  if ! command_exists "task"; then
    raise_error "task is not installed"
  fi
}

function find_taskfiles(){
  find "$START_DIR" -name "Taskfile.yml" -type f -print | while IFS= read -r taskfile_path; do
    # Extract the directory containing the Taskfile.yml
    dir_path=$(dirname "$taskfile_path")
    # Skip certain Taskfiles
    if [[ "${dir_path}" == "../docker" ]] \
      || [[ "${dir_path}" == ".." ]] \
      || [[ "${dir_path}" == "../docs" ]] \
      || [[ "${dir_path}" == "../site" ]] \
      || [[ "${dir_path}" == "../pve" ]]; then
        continue
    fi
    print_text "Found Taskfile in: '$dir_path'"
    print_text "Running task '$TASK_TO_RUN' in '$dir_path'..."
    task_list_path="${dir_path}/${TASK_LIST_FILENAME}"
    pushd "${dir_path}" > /dev/null # Change to the directory quietly
    if task "${TASK_TO_RUN}" > /dev/null; then
      print_text "Task '$TASK_TO_RUN' completed successfully in '$dir_path'."
      git add "${TASK_LIST_FILENAME}"
    else
      show_warning "Warning: Task '$TASK_TO_RUN' failed in '$dir_path' (Exit code: $?)."
    fi
    popd > /dev/null # Return to the previous directory quietly  
  done
}

function main(){
  check_task
  find_taskfiles
}

main "@"
