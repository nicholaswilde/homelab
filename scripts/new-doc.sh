#!/bin/bash

# This script automates the creation of new documentation files based on templates.

set -euo pipefail

DOCS_DIR="/home/nicholas/git/nicholaswilde/homelab/docs"

echo "--- New Documentation File Creation ---"

# 1. Ask for documentation type
echo "Select documentation type:"
echo "  1) Application (docs/apps/)"
echo "  2) Tool (docs/tools/)"
echo "  3) Hardware (docs/hardware/)"
read -p "Enter choice (1-3): " DOC_TYPE

case "$DOC_TYPE" in
    1)
        OUTPUT_SUBDIR="apps"
        TEMPLATE_TYPE="app"
        ;;
    2)
        OUTPUT_SUBDIR="tools"
        TEMPLATE_TYPE="tool"
        ;;
    3)
        OUTPUT_SUBDIR="hardware"
        TEMPLATE_TYPE="hardware"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

OUTPUT_DIR="${DOCS_DIR}/${OUTPUT_SUBDIR}"
mkdir -p "$OUTPUT_DIR"

# 2. Ask for APP_NAME
read -p "Enter the application/tool/hardware name (e.g., My App, My Tool, My Hardware): " APP_NAME

# Convert APP_NAME to lowercase and replace spaces with hyphens for filename
FILENAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--/-/g' | sed 's/^-//;s/-$//')
OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME}.md"

if [ -f "$OUTPUT_FILE" ]; then
    echo "Error: File '$OUTPUT_FILE' already exists. Exiting."
    exit 1
fi

# 3. Ask for template type (docker or generic)
TEMPLATE_FILE=".template.md.j2"
if [[ "$TEMPLATE_TYPE" == "app" ]]; then
    read -p "Is this a Docker-based application? (y/N): " IS_DOCKER
    if [[ "$IS_DOCKER" =~ ^[Yy]$ ]]; then
        TEMPLATE_FILE=".template-docker.md.j2"
    fi
fi

# 4. Ask for APP_PORT (optional)
read -p "Enter the default port (optional, press Enter to skip): " APP_PORT_VAR
if [ -n "$APP_PORT_VAR" ]; then
    APP_PORT_ARG="-D APP_PORT=$(printf %q "$APP_PORT_VAR")"
else
    APP_PORT_ARG=""
fi

# 5. Ask for CONFIG_PATH (optional)
read -p "Enter the configuration path (optional, press Enter to skip): " CONFIG_PATH_VAR
if [ -n "$CONFIG_PATH_VAR" ]; then
    CONFIG_PATH_ARG="-D CONFIG_PATH=$(printf %q "$CONFIG_PATH_VAR")"
else
    CONFIG_PATH_ARG=""
fi

echo "Generating documentation file: $OUTPUT_FILE"

# Execute the task command and redirect output
(cd "$DOCS_DIR" && jinja2 "$TEMPLATE_FILE" -D APP_NAME="$(printf %q "$APP_NAME")" $APP_PORT_ARG $CONFIG_PATH_ARG > "$OUTPUT_FILE")

echo "Successfully created '$OUTPUT_FILE'."
echo "Remember to add this new page to 'mkdocs.yml' navigation if it's a top-level page."
