#!/usr/bin/env python3
import argparse
import os
import sys
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
RESET = "\033[0m"

def log_info(msg):
    print(f"{BLUE}INFO{RESET}: {msg}")

def log_error(msg):
    print(f"{RED}ERRO{RESET}: {msg}")

def log_success(msg):
    print(f"{GREEN}SUCC{RESET}: {msg}")

def generate_doc(name, category, template_name, variables):
    root_dir = Path.cwd()
    template_dir = root_dir / "docs"
    name_lower = name.lower().replace(" ", "-").replace(".", "")
    target_file = root_dir / "docs" / category / f"{name_lower}.md"

    if target_file.exists():
        log_error(f"Documentation file already exists: {target_file}")
        sys.exit(1)

    if not (template_dir / template_name).exists():
        log_error(f"Template not found: {template_dir / template_name}")
        sys.exit(1)

    # Prepare Jinja2 environment
    env = Environment(loader=FileSystemLoader(str(template_dir)))
    
    # Standard variables
    variables['APP_NAME'] = name
    variables['APP_NAME_LOWER'] = name_lower

    try:
        template = env.get_template(template_name)
        content = template.render(**variables)
        
        # Ensure directory exists
        target_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(target_file, "w") as f:
            f.write(content)
        log_success(f"Generated: {target_file}")
    except Exception as e:
        log_error(f"Failed to generate documentation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate new documentation from template.")
    parser.add_argument("name", help="Name of the application/tool")
    parser.add_argument("category", choices=["apps", "tools", "hardware", "os"], help="Category of documentation")
    parser.add_argument("--template", help="Template file name (relative to docs/)")
    parser.add_argument("-v", "--var", action="append", help="Variable substitution (key=value)")

    args = parser.parse_args()
    
    variables = {}
    if args.var:
        for v in args.var:
            if "=" in v:
                key, val = v.split("=", 1)
                variables[key] = val
            else:
                log_error(f"Invalid variable format: {v}. Use key=value.")
                sys.exit(1)

    # Default template selection
    template = args.template
    if not template:
        if args.category == "tools":
            template = ".template-tool.md.j2"
        elif args.category == "apps":
            # We'll assume generic app unless specified, but usually the command will specify
            template = ".template.md.j2"
        else:
            template = ".template.md.j2"

    generate_doc(args.name, args.category, template, variables)
