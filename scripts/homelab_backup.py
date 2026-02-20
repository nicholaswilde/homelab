#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
from pathlib import Path
import time

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
RESET = "\033[0m"

ALIASES = {
    "agh": "pve/adguardhome",
    "adguard": "pve/adguardhome",
    "adguardhome": "pve/adguardhome",
    "patchmon": "pve/patchmon",
    "changedetection": "pve/changedetection"
}

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
        log_info(f"Running command: {' '.join(cmd)}")
        result = subprocess.run(cmd, cwd=cwd, shell=False, check=True, capture_output=True, text=True)
        if result.stdout:
            print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"Command failed with exit code {e.returncode}")
        if e.stdout: print(e.stdout)
        if e.stderr: print(e.stderr)
        return False

def resolve_target(target):
    root_dir = Path.cwd()
    
    # Check aliases
    if target.lower() in ALIASES:
        return root_dir / ALIASES[target.lower()]
    
    # Check direct paths
    search_dirs = [root_dir / "docker", root_dir / "lxc", root_dir / "pve"]
    for d in search_dirs:
        if (d / target).is_dir():
            return d / target
            
    return None

def verify_backup(app_dir):
    log_info(f"Verifying backup in {app_dir}...")
    enc_files = list(app_dir.glob("*.enc"))
    if not enc_files:
        log_warn("No .enc files found in target directory. Backup might not be encrypted or used a different name.")
        return False
    
    # Sort by modification time
    enc_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
    latest_file = enc_files[0]
    
    # Check if updated in the last 5 minutes
    if (time.time() - latest_file.stat().st_mtime) < 300:
        log_success(f"Verified: {latest_file.name} was recently updated.")
        return True
    else:
        log_warn(f"Last updated .enc file ({latest_file.name}) is older than 5 minutes.")
        return False

def main():
    parser = argparse.ArgumentParser(description="Backup homelab applications.")
    parser.add_argument("target", help="Name or alias of the application to backup")

    args = parser.parse_args()
    
    target_dir = resolve_target(args.target)
    
    if not target_dir:
        log_error(f"Could not resolve target: {args.target}")
        sys.exit(1)
        
    if not (target_dir / "Taskfile.yml").exists():
        log_error(f"No Taskfile.yml found in {target_dir}")
        sys.exit(1)
        
    # Check if backup task exists
    check_task = subprocess.run(["task", "backup", "--summary"], cwd=target_dir, capture_output=True)
    if check_task.returncode != 0:
        log_error(f"No 'backup' task defined in {target_dir}/Taskfile.yml")
        sys.exit(1)

    log_info(f"Starting backup for {args.target} in {target_dir}...")
    
    if run_command(["task", "backup"], cwd=target_dir):
        log_success(f"Backup task completed for {args.target}")
        verify_backup(target_dir)
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
