#!/usr/bin/env bash

################################################################################
#
# HEIC Converter
# ----------------
# This script converts HEIC images to JPG or PNG format.
# It can also delete original HEIC files upon successful conversion,
# delete MP4 files, and extract zip/tar archives.
#
# It requires ImageMagick ('magick' or 'convert' command) for HEIC conversion,
# 'unzip' for .zip files, and 'tar' for .tar and compressed tarballs.
##
# @author Nicholas Wilde, 0xb299a622 
# @date 05 Jul 2025
# @version 0.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# Constants
bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
purple=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
default=$(tput setaf 9)

readonly bold
readonly normal
readonly red
readonly green
readonly yellow
readonly blue
readonly purple
readonly cyan
readonly white
readonly default

# Global variables
OUTPUT_FORMAT="jpg"
PROCESS_DIRECTORY=""
declare -a RAW_INPUT_ARGS # Holds all non-option arguments from the command line
declare -a HEIC_FILES_TO_PROCESS # Files identified for HEIC conversion
declare -a ARCHIVE_FILES_TO_EXTRACT # Files identified for archive extraction
IMAGEMAGICK_CMD=""
DELETE_HEIC_ON_SUCCESS=false
DELETE_MP4_FILES=false
EXTRACT_ARCHIVES=false # This flag now enables/disables the extraction *feature*

# Functions
function print_text(){
  echo "${blue}==> ${white}${bold}${1}${normal}"
}

function print_error(){
  echo "${red}${1}${normal}"
}

# Function to get the current timestamp
function get_timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

# INFO level logging (often default color or green/blue)
function log_info() {
  printf "${blue}INFO${normal}[%s] %s\n" "$(get_timestamp)" "$*"
}

# INFO level logging (often default color or green/blue)
function log_debu() {
  printf "${purple}DEBU${normal}[%s] %s\n" "$(get_timestamp)" "$*"
}

# WARN level logging (yellow)
function log_warn() {
  printf "${yellow}WARN${normal}[%s] %s\n" "$(get_timestamp)" "$*" >&2
}

# ERRO level logging (red)
function log_erro() {
  printf "${red}ERRO${normal}[%s] %s\n" "$(get_timestamp)" "$*" >&2
}

function raise_error(){
  print_error "${1}"
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

# Function to display usage instructions
function show_usage() {
  echo "Usage: $0 [-f <jpg|png>] [file1.heic ...] [-d <dir>] [--delete-heic-on-success] [--delete-mp4] [--extract-archives] [archive1.zip ...]"
  echo ""
  echo "Options:"
  echo "  -f <jpg|png>             : Specify the output format (default: jpg)."
  echo "  -d <directory>           : Process files in the specified directory."
  echo "                             Required for --delete-mp4 and automatic archive detection in directory."
  echo "  --delete-heic-on-success : DELETE original HEIC files after successful conversion."
  echo "                             USE WITH CAUTION: This action is irreversible!"
  echo "  --delete-mp4             : DELETE all MP4 files found in the processed directory (-d option)."
  echo "                             USE WITH CAUTION: This action is irreversible!"
  echo "  --extract-archives       : Enable extraction for provided archive files or archives found via -d."
  echo "  -h                       : Display this help message."
  echo ""
  echo "Examples:"
  echo "  $0 image.heic photo.heic"
  echo "  $0 -f png photo.heic --extract-archives archive.zip"
  echo "  $0 -d ~/Pictures/MyHEICImages -f jpg --delete-heic-on-success --extract-archives"
  echo "  $0 -d ./my_media --delete-mp4 --extract-archives"
  echo "  $0 --extract-archives my_photos.zip video_archive.tar.gz"
  exit 1
}

# Function to parse command-line arguments
function parse_arguments() {
  local ARGS=$(getopt -o f:d:h -l delete-heic-on-success,delete-mp4,extract-archives -- "$@")
  if [[ $? -ne 0 ]]; then
    show_usage
  fi

  eval set -- "$ARGS"

  while true; do
    case "$1" in
      -f )
        if [[ "$2" == "jpg" || "$2" == "png" ]]; then
          OUTPUT_FORMAT="$2"
        else
          log_erro "Invalid format '$2'. Only 'jpg' or 'png' are supported."
          show_usage
        fi
        shift 2;;
      -d )
        PROCESS_DIRECTORY="$2"
        shift 2;;
      --delete-heic-on-success )
        DELETE_HEIC_ON_SUCCESS=true
        shift;;
      --delete-mp4 )
        DELETE_MP4_FILES=true
        shift;;
      --extract-archives )
        EXTRACT_ARCHIVES=true
        shift;;
      -h )
        show_usage;;
      -- )
        shift
        break;;
      * )
        break;;
    esac
  done

  # All remaining arguments are file paths (HEIC, archives, or others)
  RAW_INPUT_ARGS=("$@")

  if [[ -z "$PROCESS_DIRECTORY" ]] && [[ ${#RAW_INPUT_ARGS[@]} -eq 0 ]]; then
    log_erro "No input files or directory specified."
    show_usage
  fi
}

# Function to resolve and categorize input file paths
function resolve_input_files() {
  local files_to_categorize=()

  if [[ -n "$PROCESS_DIRECTORY" ]]; then
    # Resolve the directory path to its absolute form for robustness
    local ABS_PROCESS_DIRECTORY
    if [[ "$PROCESS_DIRECTORY" == /* ]]; then # Already an absolute path
      ABS_PROCESS_DIRECTORY="$PROCESS_DIRECTORY"
    else # Relative path, resolve it
      ABS_PROCESS_DIRECTORY="$(pwd)/$PROCESS_DIRECTORY"
    fi

    if [[ ! -d "$ABS_PROCESS_DIRECTORY" ]]; then
      log_erro "Directory '$PROCESS_DIRECTORY' (resolved to '$ABS_PROCESS_DIRECTORY') not found."
      exit 1
    fi
    log_info "Scanning directory: $PROCESS_DIRECTORY (resolved to '$ABS_PROCESS_DIRECTORY') for HEIC and archive files..."
    # Find all relevant files in the directory
    mapfile -t files_to_categorize < <(find "$ABS_PROCESS_DIRECTORY" -maxdepth 1 -type f \
      \( -iname "*.heic" -o -iname "*.heif" -o \
         -iname "*.zip" -o \
         -iname "*.tar" -o -iname "*.tar.gz" -o -iname "*.tgz" -o -iname "*.tar.bz2" -o -iname "*.tbz2" \))

    if [[ ${#files_to_categorize[@]} -eq 0 ]] && ! $DELETE_MP4_FILES; then
      log_info "No HEIC, archive files, or MP4 files found in '$ABS_PROCESS_DIRECTORY' for processing."
      exit 0 # Exit if directory specified but nothing to do
    fi
  else
    # Direct file arguments were passed
    files_to_categorize=("${RAW_INPUT_ARGS[@]}")
    # For directly passed files, resolve them to absolute paths for consistency
    local resolved_files=()
    for file_arg in "${files_to_categorize[@]}"; do
      if [[ "$file_arg" == /* ]]; then # Already an absolute path
        resolved_files+=("$file_arg")
      else # Relative path, resolve it
        resolved_files+=("$(pwd)/$file_arg")
      fi
    done
    files_to_categorize=("${resolved_files[@]}")

    # If MP4 deletion or archive extraction flags are set without -d,
    # these ops only apply to explicitly provided files of that type.
    # Warn if --delete-mp4 is used without -d as its primary function is directory-wide.
    if $DELETE_MP4_FILES; then
      log_warn "--delete-mp4 primarily cleans MP4s in a directory (via -d). For specific MP4 files, pass them directly."
    fi
  fi

  # Now, categorize the identified files into HEIC_FILES_TO_PROCESS and ARCHIVE_FILES_TO_EXTRACT
  for file_path in "${files_to_categorize[@]}"; do
    local basename_lc=$(basename -- "$file_path" | tr '[:upper:]' '[:lower:]') # Lowercase for case-insensitive check
    if [[ "$basename_lc" =~ \.(heic|heif)$ ]]; then
      HEIC_FILES_TO_PROCESS+=("$file_path")
    elif [[ "$basename_lc" =~ \.(zip|tar|tar\.gz|tgz|tar\.bz2|tbz2)$ ]]; then
      ARCHIVE_FILES_TO_EXTRACT+=("$file_path")
    else
      log_info "Ignoring unrecognized file type: '$file_path'"
    fi
  done

  # Final check if any operations are actually going to run
  if [[ ${#HEIC_FILES_TO_PROCESS[@]} -eq 0 ]] && \
    [[ ! "$EXTRACT_ARCHIVES" || ${#ARCHIVE_FILES_TO_EXTRACT[@]} -eq 0 ]] && \
    [[ ! "$DELETE_MP4_FILES" || -z "$PROCESS_DIRECTORY" ]]; then
    log_info "No relevant files (HEIC, Archives, or directory for MP4 cleanup) found or specified for requested operations."
    exit 0
  fi
}

# Function to check for ImageMagick commands
function check_imagemagick_command() {
  if command -v magick &> /dev/null; then
    IMAGEMAGICK_CMD="magick"
  elif command -v convert &> /dev/null; then
    IMAGEMAGICK_CMD="convert"
  else
    log_erro "Neither 'magick' nor 'convert' commands (from ImageMagick) found in your PATH."
    log_erro "Please install ImageMagick. For example:"
    log_erro "  macOS: brew install imagemagick"
    log_erro "  Debian/Ubuntu: sudo apt install imagemagick"
    log_erro "  Fedora/RHEL: sudo yum install ImageMagick"
    exit 1
  fi
}

# Function to check for archive extraction commands
function check_archive_commands() {
  if $EXTRACT_ARCHIVES; then
    if ! command -v unzip &> /dev/null; then
      log_erro "'unzip' command not found. Cannot extract .zip files. Please install it."
      log_erro "  Debian/Ubuntu: sudo apt install unzip"
      log_erro "  Fedora/RHEL: sudo yum install unzip"
      log_erro "  macOS: brew install unzip"
      # Don't exit, allow tar extraction if available
    fi
    if ! command -v tar &> /dev/null; then
      log_erro "'tar' command not found. Cannot extract .tar/.tar.gz/.tar.bz2 files. Please install it."
      log_erro "  Tar is usually pre-installed on Linux/macOS. If not, install via your package manager."
      exit 1 # Tar is crucial for these types, so exit if not found
    fi
  fi
}

# Function to clean up MP4 files in the processed directory
function cleanup_mp4_files() {
  # This function only acts if -d is used to define a directory scope
  if $DELETE_MP4_FILES && [[ -n "$PROCESS_DIRECTORY" ]]; then
    log_info "Initiating MP4 File Deletion"
    local ABS_PROCESS_DIRECTORY # Ensure it's available from resolve_input_files scope
    if [[ "$PROCESS_DIRECTORY" == /* ]]; then
      ABS_PROCESS_DIRECTORY="$PROCESS_DIRECTORY"
    else
      ABS_PROCESS_DIRECTORY="$(pwd)/$PROCESS_DIRECTORY"
    fi

    log_info "Searching for and deleting MP4 files in '$ABS_PROCESS_DIRECTORY'..."
    local mp4_files=()
    mapfile -t mp4_files < <(find "$ABS_PROCESS_DIRECTORY" -maxdepth 1 -type f -iname "*.mp4")

    if [[ ${#mp4_files[@]} -eq 0 ]]; then
      log_info "No MP4 files found in '$ABS_PROCESS_DIRECTORY'."
    else
      for mp4_file in "${mp4_files[@]}"; do
        log_info "Deleting MP4: '$mp4_file'"
        rm -f "$mp4_file"
        if [[ $? -ne 0 ]]; then
          log_warn "Failed to delete '$mp4_file'."
        fi
      done
      log_info "MP4 file deletion complete."
    fi
  elif $DELETE_MP4_FILES && [[ -z "$PROCESS_DIRECTORY" ]]; then
    log_info "--delete-mp4 flag was used, but no directory (-d) was specified. Skipping directory-wide MP4 cleanup."
  fi
}

# Function to extract archives
function extract_archives() {
  if $EXTRACT_ARCHIVES && [[ ${#ARCHIVE_FILES_TO_EXTRACT[@]} -gt 0 ]]; then
    log_info "Initiating Archive Extraction"
    for archive_file in "${ARCHIVE_FILES_TO_EXTRACT[@]}"; do
      if [[ ! -f "$archive_file" ]]; then
        log_warn "Archive file '$archive_file' not found. Skipping extraction."
        continue
      fi

      local archive_basename=$(basename -- "$archive_file")
      local archive_dir=$(dirname "$archive_file")
      local extract_dir="${archive_dir}/${archive_basename%.*}_extracted" # Extract into a new dir next to the archive
      mkdir -p "$extract_dir" # Create the extraction directory

      log_info "Extracting '$archive_basename' to '$extract_dir'..."

      case "$archive_file" in
        *.zip)
          if command -v unzip &> /dev/null; then
            unzip -q "$archive_file" -d "$extract_dir"
            if [[ $? -eq 0 ]]; then
              log_info "Successfully extracted '$archive_basename'."
            else
              log_erro "Failed to extract '$archive_basename' with unzip."
            fi
          else
            log_warn "'unzip' command not found. Cannot extract '$archive_basename'."
          fi;;
        *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2)
          if command -v tar &> /dev/null; then
            local tar_flags="-xf"
            case "$archive_file" in
              *.tar.gz|*.tgz) tar_flags="-xzf";;
              *.tar.bz2|*.tbz2) tar_flags="-xjf";;
            esac
            tar "$tar_flags" "$archive_file" -C "$extract_dir"
            if [[ $? -eq 0 ]]; then
              log_info "Successfully extracted '$archive_basename'."
            else
              log_erro "Failed to extract '$archive_basename' with tar."
            fi
          else
            log_warn "'tar' command not found. Cannot extract '$archive_basename'."
          fi;;
        *)
          log_warn "Unrecognized archive type for '$archive_basename'. Skipping.";;
      esac
    done
    log_info "Archive extraction complete."
  elif $EXTRACT_ARCHIVES && [[ ${#ARCHIVE_FILES_TO_EXTRACT[@]} -eq 0 ]]; then
    log_info "--extract-archives flag was used, but no archive files were specified or found in the directory for extraction."
  fi
}

# Function to process (convert) the HEIC files
function process_files() {
  if [[ ${#HEIC_FILES_TO_PROCESS[@]} -eq 0 ]]; then
    log_info "No HEIC files to convert."
    return 0
  fi

  log_info "HEIC to ${OUTPUT_FORMAT^^} Converter (using '$IMAGEMAGICK_CMD')"

  for heic_file in "${HEIC_FILES_TO_PROCESS[@]}"; do
    if [[ ! -f "$heic_file" ]]; then
      log_warn "File '$heic_file' not found. Skipping."
      continue
    fi

    local heic_dir=$(dirname "$heic_file")
    local filename_no_ext=$(basename -- "$heic_file" | sed 's/\.[Hh][Ee][Ii][Cc]$//' | sed 's/\.[Hh][Ee][Ii][Ff]$//')
    local output_file="${heic_dir}/${filename_no_ext}.${OUTPUT_FORMAT}"

    log_info "Converting "$(basename "$heic_file")" to "$(basename "$output_file")"..."

    if "$IMAGEMAGICK_CMD" "$heic_file" "$output_file"; then
      log_info "Successfully converted" $(basename "$heic_file")" to "$(basename "$output_file")"."
      if $DELETE_HEIC_ON_SUCCESS; then
        log_info "Deleting original HEIC file: " $(basename "$heic_file")
        rm -f "$heic_file"
        if [[ $? -ne 0 ]]; then
          log_warn "Failed to delete original HEIC file "$(basename "$heic_file")"."
        fi
      fi
    else
      log_erro "Failed to convert "$(basename "$heic_file")"."
    fi
  done

  log_info "HEIC Conversion complete"
}

# Main Script Execution

# Main function to orchestrate the script execution
function main() {
  parse_arguments "$@"
  resolve_input_files # This categorizes files and sets ABS_PROCESS_DIRECTORY if -d is used

  # Only check commands if the relevant operations are requested
  if [[ ${#HEIC_FILES_TO_PROCESS[@]} -gt 0 ]]; then
    check_imagemagick_command
  fi
  if $EXTRACT_ARCHIVES && [[ ${#ARCHIVE_FILES_TO_EXTRACT[@]} -gt 0 ]]; then
    check_archive_commands
  fi

  cleanup_mp4_files # Run MP4 cleanup if enabled and in directory mode (still only applies to -d)
  extract_archives  # Run archive extraction if enabled and archives are found/passed
  process_files     # Run HEIC conversion if HEIC files are found/passed
}

# Call the main function with all command-line arguments
main "$@"
