#!/usr/bin/env python3
import argparse
import os
import shutil
import sys
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

# Set up logging with Catppuccin Mocha colors (approximate)
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

def deploy(app_name, deploy_type, variables):
    app_name = app_name.lower()
    root_dir = Path.cwd()
    template_dir = root_dir / deploy_type / ".template"
    target_dir = root_dir / deploy_type / app_name

    if not template_dir.exists():
        log_error(f"Template directory not found: {template_dir}")
        sys.exit(1)

    if target_dir.exists():
        log_error(f"Target directory already exists: {target_dir}")
        sys.exit(1)

    log_info(f"Creating directory: {target_dir}")
    target_dir.mkdir(parents=True)

    # Prepare Jinja2 environment
    env = Environment(loader=FileSystemLoader(str(template_dir)))
    
    # Standard variables
    variables['APP_NAME'] = app_name
    # Default user name if not provided
    if 'USER_NAME' not in variables:
        import getpass
        variables['USER_NAME'] = getpass.getuser()

    log_info(f"Copying and substituting files from {template_dir}...")
    for item in template_dir.iterdir():
        if item.name.endswith(".j2"):
            # Handle .j2 files
            log_info(f"Processing template: {item.name}")
            try:
                template = env.get_template(item.name)
                # Find all variables in the template
                from jinja2 import meta
                template_source = env.loader.get_source(env, item.name)[0]
                parsed_content = env.parse(template_source)
                variables_in_template = meta.find_undeclared_variables(parsed_content)
                
                # Check for missing variables (except standard ones)
                missing = [v for v in variables_in_template if v not in variables]
                if missing:
                    log_error(f"Missing variables for {item.name}: {', '.join(missing)}")
                    # In a real CLI, we might prompt here, but the script expects them as arguments.
                    # The Gemini CLI protocol will handle prompting.
                    sys.exit(1)

                content = template.render(**variables)
                
                # Naming logic
                target_name = item.name.replace(".j2", "")
                if target_name == ".env.tmpl":
                    target_name = ".env"
                
                target_file = target_dir / target_name
                with open(target_file, "w") as f:
                    f.write(content)
                log_info(f"Generated: {target_file}")
            except Exception as e:
                log_error(f"Failed to process template {item.name}: {e}")
                sys.exit(1)
        else:
            # Copy other files as is
            target_path = target_dir / item.name
            if item.is_dir():
                shutil.copytree(item, target_path)
            else:
                shutil.copy2(item, target_path)
            log_info(f"Copied: {target_path}")

    # Register Track in conductor/tracks.md
    tracks_file = root_dir / "conductor" / "tracks.md"
    if tracks_file.exists():
        log_info(f"Registering track in {tracks_file}...")
        track_link = f"conductor/tracks/deploy-{app_name}/"
        track_entry = f"- [Deploy {app_name}]({track_link}) [ ]\n"
        with open(tracks_file, "a") as f:
            f.write(track_entry)
        
        # Create track directory
        track_dir = root_dir / "conductor" / "tracks" / f"deploy-{app_name}"
        track_dir.mkdir(parents=True, exist_ok=True)
        
        # Create metadata.json
        import json
        from datetime import datetime
        metadata = {
            "track_id": f"deploy-{app_name}",
            "name": f"Deploy {app_name}",
            "status": "not started",
            "created_at": datetime.utcnow().isoformat() + "Z",
            "updated_at": datetime.utcnow().isoformat() + "Z"
        }
        with open(track_dir / "metadata.json", "w") as f:
            json.dump(metadata, f, indent=2)

        # Create basic spec.md and plan.md
        spec_content = (
            f"# Spec: Deploy {app_name}\n\n"
            f"Finalize the deployment and verification of {app_name} as a {deploy_type} application.\n"
        )
        with open(track_dir / "spec.md", "w") as f:
            f.write(spec_content)
        
        plan_content = (
            f"# Implementation Plan: Deploy {app_name}\n\n"
            f"## Phase 1: Configuration\n"
            f"- [ ] Finalize environment variables in `{deploy_type}/{app_name}/.env`.\n"
            f"- [ ] Verify template substitutions.\n\n"
            f"## Phase 2: Deployment\n"
            f"- [ ] Start the service.\n"
            f"- [ ] Verify functionality.\n"
        )
        with open(track_dir / "plan.md", "w") as f:
            f.write(plan_content)

    log_success(f"Successfully deployed {app_name} to {target_dir}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Deploy a new application from template.")
    parser.add_argument("name", help="Name of the application")
    parser.add_argument("type", choices=["docker", "lxc"], help="Type of deployment (docker or lxc)")
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

    deploy(args.name, args.type, variables)
