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

def add_to_dashboard(name, group, icon, href, description=None):
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

    # Homepage services.yaml is a list of dictionaries where each key is a group name
    group_found = False
    for item in data:
        if group in item:
            group_found = True
            # Check for duplicates in this group
            for service in item[group]:
                if name in service:
                    log_error(f"Service '{name}' already exists in group '{group}'.")
                    sys.exit(1)
            
            # Create the new service entry
            new_service = {
                name: {
                    'icon': icon,
                    'href': href
                }
            }
            if description:
                new_service[name]['description'] = description
            
            item[group].append(new_service)
            break

    if not group_found:
        log_info(f"Group '{group}' not found. Creating a new one...")
        new_group = {
            group: [
                {
                    name: {
                        'icon': icon,
                        'href': href
                    }
                }
            ]
        }
        if description:
            new_group[group][0][name]['description'] = description
        data.append(new_group)

    with open(services_file, 'w') as f:
        yaml.dump(data, f)
    
    log_success(f"Added '{name}' to group '{group}' in {services_file.relative_to(root_dir)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Add a service to the homepage dashboard.")
    parser.add_argument("name", help="Name of the service")
    parser.add_argument("group", help="Group name in services.yaml")
    parser.add_argument("--icon", default="si-simpleicons", help="Icon slug or URL")
    parser.add_argument("--href", help="Destination URL")
    parser.add_argument("--desc", help="Optional description")

    args = parser.parse_args()
    
    href = args.href if args.href else f"https://{args.name.lower().replace(' ', '-')}.l.nicholaswilde.io"
    
    add_to_dashboard(args.name, args.group, args.icon, href, args.desc)
