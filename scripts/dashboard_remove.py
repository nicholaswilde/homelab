#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path
from ruamel.yaml import YAML

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

def get_balanced_columns(item_count):
    """
    Heuristic to balance columns for Homepage dashboard.
    Max 4 columns.
    """
    if item_count <= 0:
        return 1
    if item_count <= 4:
        return item_count
    if item_count % 4 == 0:
        return 4
    if item_count % 3 == 0:
        return 3
    if item_count == 5:
        return 3
    if item_count == 7:
        return 4
    return 4

def update_settings_columns(group, item_count):
    root_dir = Path.cwd()
    settings_file = root_dir / "pve" / "homepage" / "config" / "settings.yaml"
    
    if not settings_file.exists():
        return

    yaml = YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)
    yaml.preserve_quotes = True

    with open(settings_file, 'r') as f:
        data = yaml.load(f)

    if 'layout' in data and group in data['layout']:
        new_cols = get_balanced_columns(item_count)
        old_cols = data['layout'][group].get('columns')
        if new_cols != old_cols:
            data['layout'][group]['columns'] = new_cols
            log_info(f"Updating '{group}' columns from {old_cols} to {new_cols} for {item_count} items.")
            with open(settings_file, 'w') as f:
                yaml.dump(data, f)

def remove_from_dashboard(name):
    root_dir = Path.cwd()
    services_file = root_dir / "pve" / "homepage" / "config" / "services.yaml"

    if not services_file.exists():
        log_error(f"Services file not found: {services_file}")
        sys.exit(1)

    yaml = YAML()
    yaml.indent(mapping=4, sequence=4, offset=2)
    yaml.preserve_quotes = True

    with open(services_file, 'r') as f:
        data = yaml.load(f)

    removed = False
    target_group = None
    item_count = 0

    for item in data:
        for group, services in item.items():
            initial_count = len(services)
            # Filter out the service with the matching name
            item[group] = [s for s in services if name not in s]
            if len(item[group]) < initial_count:
                removed = True
                target_group = group
                item_count = len(item[group])
                break
        if removed:
            break

    if removed:
        with open(services_file, 'w') as f:
            yaml.dump(data, f)
        log_success(f"Removed '{name}' from group '{target_group}' in services.yaml")
        update_settings_columns(target_group, item_count)
    else:
        log_info(f"Service '{name}' not found in any dashboard group.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Remove a service from the homepage dashboard.")
    parser.add_argument("name", help="Name of the service to remove")

    args = parser.parse_args()
    remove_from_dashboard(args.name)
