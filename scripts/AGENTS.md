# Scripts Guidelines for Gemini

## Bash Scripting Assistant

**Context:** This directory contains all project bash scripts.

**Specific Instructions for Markdown Files:**

- All scripts must begin with the shebang `#!/usr/bin/env bash`.
- The script's entry point should be a `main` function and pass arguments "@"
- The `main` function should be defined at the bottom of the script, after all other functions.
- Helper or sub-functions should be defined before the `main` function that calls them.
- The script should conclude by calling the `main` function to start execution.

## Coding Style:

- Use 2 spaces for indentation.
- All functions must be declared using the `function` keyword (e.g., `function my_function { ... }`).
- Use upper case variable names with underscores for separators (e.g., `MY_VARIABLE=""`).
- Add comments to explain complex logic.
- Use lower case function names with underscores for separators (e.g., `my_function { ... }`)
- Add a commented out header with the name of the script, description of the script, name of author and short gpg key fingerprint, and date.
- DATE should be in the format of DD Mmm YYYY.
- All dependencies shall be checked if they exist as a function.
- Instead of echo, use a log function to log in the format of go-lang (e.g. `INFO[date time] message`).
- Color INFO as blue, WARN as yellow, and ERRO as red.
- Use tput to define the colors (e.g. `RED=$(tput setaf 1)`)
- Make all constants as readonly (e.g. `readonly CONST`)
- Define all constants after the header and before the functions.
- Hard coded paths shall be set as variables after the options.
- options "-e" and "set -e pipefail" are used and set right underneath the header
- All script file names should not include spaces, not include underscores, and only includes dashes (e.g. `script-name.sh`)
- Bash files should attempt to read environment variables from .env files located in the application folder (usually same directory as script).
- Prefer `[[ ... ]]` for conditional expressions involving string and file tests. For checking command success or failure, use `if command ... ; then` or `if ! command ... ; then`.
- Use `shellcheck` to check bash scripts for coding practices.

## Example Script Structure:

```bash
#!/usr/bin/env bash
################################################################################
#
# Script Name
# ----------------
# Script description
#
# @author Nicholas Wilde, 0xb299a622
# @date DATE
# @version 0.1.0
#
################################################################################

# Options
set -e
set -o pipefail

# These are constants
CONSTANT="value"
readonly CONSTANT

readonly BLUE=$(tput setaf 4)
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly PURPLE=$(tput setaf 5)
readonly RESET=$(tput sgr0)
DEBUG="false"

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


# Checks if a command exists.
function commandExists() {
  command -v "$1" >/dev/null 2>&1
}

function check_dependencies() {
  # --- check for dependencies ---
  if ! commandExists curl || ! commandExists grep || ! commandExists unzip || ! commandExists esptool ; then
    log "ERRO" "Required dependencies (curl, grep, unzip, esptool) are not installed." >&2
    exit 1
  fi  
}

# This is a helper function
function _helper_function() {
  log "INFO" "Executing helper function..."
}

# This is another function
function process_data() {
  log "INFO" "Processing data..."
  _helper_function
}

# Main function to orchestrate the script execution
function main() {
  log "INFO" "Starting script..."
  process_data
  log "INFO" "Script finished."
}

# Call main to start the script
main "@"
```

## Mailrise Notification Example

*Note: The `ENABLE_NOTIFICATIONS`, `MAILRISE_URL`, `MAILRISE_FROM`, and `MAILRISE_RCPT` variables are typically defined in the application's `.env` file.*

```bash
function send_notification(){
  if [[ "${ENABLE_NOTIFICATIONS}" == "false" ]]; then
    log "WARN" "Notifications are disabled. Skipping."
    return 0
  fi
  if [[ -z "${MAILRISE_URL}" || -z "${MAILRISE_FROM}" || -z "${MAILRISE_RCPT}" ]]; then
    log "WARN" "Notification variables not set. Skipping notification."
    return 1
  fi

  local EMAIL_SUBJECT="Homelab - Update Summary"
  local EMAIL_BODY="Update completed successfully."

  log "INFO" "Sending email notification..."
  if ! curl -s \
    --url "${MAILRISE_URL}" \
    --mail-from "${MAILRISE_FROM}" \
    --mail-rcpt "${MAILRISE_RCPT}" \
    --upload-file - <<EOF
From: Application <${MAILRISE_FROM}>
To: User <${MAILRISE_RCPT}>
Subject: ${EMAIL_SUBJECT}

${EMAIL_BODY}
EOF
  then
    log "ERRO" "Failed to send notification."
  else
    log "INFO" "Email notification sent."
  fi
}
```

## Python Scripting Assistant

**Role**: You are an expert Python developer and my assistant for writing and refining scripts within this repository. Your primary goal is to ensure the code is high-quality, readable, and follows Python best practices.

### Instructions for all Python-related tasks:

* **Shebang**: Include `#!/usr/bin/env python3` as the first line of every executable Python script. This tells the operating system which interpreter to use.
* **Commented Header**: Every Python script must start with a commented header in the following format. The values should be automatically populated based on the script's purpose.

```
#!/usr/bin/env python3
################################################################################
#
# Script Name: <script_name>.py
# ----------------
# <A  description of the script's purpose>
#
# @author Nicholas Wilde, 0xb299a622
# @date <Current Date in DD MM YYYY format>
# @version <Version in semver format>
#
################################################################################
```

* **PEP 8 Compliance**: All code must strictly adhere to the PEP 8 style guide. This includes consistent indentation (4 spaces), clear variable names (snake_case), and proper whitespace.
* **Documentation**: Every function and class should have a clear, concise docstring. The docstring should explain what the function does, its parameters, and what it returns.
* **Modularity**: Break down complex tasks into smaller, reusable functions. A function should ideally do one thing and do it well.
* **Error Handling**: Use `try...except` blocks to handle potential errors gracefully. Your code should not crash if a file is missing or a network request fails.
* **Unit Tests**: For any new functionality or bug fixes, write comprehensive unit tests to ensure correctness and prevent regressions. Tests should cover typical use cases, edge cases, and error conditions.
* **Readability**: Prefer explicit, readable code over clever one-liners. The goal is for the code to be as self-documenting as possible.
* **Comments**: Use comments sparingly to explain the "why" behind complex logic, not the "what."
* **Imports**: Group your imports in the following order:
  1. Standard library imports.
  2. Third-party imports.
  3. Local application/library-specific imports.
* **Terminal Table Output**: When generating a script that outputs a table to the terminal, use the `tabulate` library with the `fancy_grid` format for clear and well-structured output.
