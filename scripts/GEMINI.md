# Bash Scripts Guidelines for Gemini

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

RED=$(tput setaf 1)
readonly RED

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
  echo "Starting script..."
  process_data
  echo "Script finished."
}

# Call main to start the script
main "@"
```
