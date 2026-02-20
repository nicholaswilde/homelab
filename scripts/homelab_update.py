#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
from pathlib import Path

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
RESET = "\033[0m"

def log_info(msg):
    print(f"{BLUE}INFO{RESET}: {msg}")

def log_error(msg):
    print(f"{RED}ERRO{RESET}: {msg}")

def log_success(msg):
    print(f"{GREEN}SUCC{RESET}: {msg}")

def log_warn(msg):
    print(f"{YELLOW}WARN{RESET}: {msg}")

def run_command(cmd, cwd=None):
    try:
        log_info(f"Running command: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
        result = subprocess.run(cmd, cwd=cwd, shell=False, check=True, capture_output=True, text=True)
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"Command failed with exit code {e.returncode}")
        print(e.stderr)
        return False

def get_app_info(app_name):
    root_dir = Path.cwd()
    search_dirs = [root_dir / "docker", root_dir / "lxc", root_dir / "pve"]
    matches = []

    for d in search_dirs:
        if (d / app_name).is_dir():
            matches.append(d / app_name)

    if not matches:
        return None, None
    
    if len(matches) > 1:
        log_warn(f"Multiple matches found for {app_name}: {[str(m.relative_to(root_dir)) for m in matches]}")
        # Return the first one for now, or we could be smarter
    
    app_dir = matches[0]
    app_type = None
    
    if "docker" in str(app_dir):
        app_type = "docker"
    elif "lxc" in str(app_dir):
        app_type = "lxc"
    elif "pve" in str(app_dir):
        if (app_dir / "compose.yaml").exists() or (app_dir / "compose.yml").exists():
            app_type = "docker"
        elif (app_dir / "update.sh").exists():
            app_type = "lxc"
            
    return app_dir, app_type

def update_app(app_dir, app_type):
    log_info(f"Updating {app_dir.name} ({app_type}) in {app_dir}...")
    
    if app_type == "docker":
        # Docker update logic
        if run_command(["docker", "compose", "pull"], cwd=app_dir):
            if run_command(["docker", "compose", "up", "-d", "--remove-orphans"], cwd=app_dir):
                log_success(f"Successfully updated Docker app: {app_dir.name}")
                return True
    elif app_type == "lxc":
        # LXC update logic
        update_script = app_dir / "update.sh"
        if update_script.exists():
            if run_command(["bash", str(update_script)], cwd=app_dir):
                log_success(f"Successfully updated LXC app: {app_dir.name}")
                return True
        else:
            log_error(f"update.sh not found in {app_dir}")
    else:
        log_error(f"Unknown app type for {app_dir.name}")
        
    return False

def main():
    parser = argparse.ArgumentParser(description="Update homelab applications.")
    parser.add_argument("name", nargs="?", help="Name of the application to update")
    parser.add_argument("--all", action="store_true", help="Update all applications")

    args = parser.parse_args()

    if args.all:
        log_info("Updating all applications (Dry-run)...")
        root_dir = Path.cwd()
        for type_dir in ["docker", "lxc"]:
            d = root_dir / type_dir
            if d.is_dir():
                for app_dir in d.iterdir():
                    if app_dir.is_dir() and not app_dir.name.startswith("."):
                        app_type = "docker" if type_dir == "docker" else "lxc"
                        log_info(f"[DRY-RUN] Would update {app_dir.name} ({app_type})")
        sys.exit(0)

    if not args.name:
        log_error("Application name is required unless --all is used.")
        sys.exit(1)

    app_dir, app_type = get_app_info(args.name)
    
    if not app_dir or not app_type:
        log_error(f"Could not find or identify app: {args.name}")
        sys.exit(1)

    if update_app(app_dir, app_type):
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
