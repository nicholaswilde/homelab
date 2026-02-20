#!/usr/bin/env python3
import re
import subprocess
import sys
from pathlib import Path

# Catppuccin Mocha Colors (approximate)
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

def run_command(cmd):
    try:
        result = subprocess.run(cmd, shell=True, check=True, capture_output=True, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        log_error(f"Command failed: {cmd}")
        log_error(f"Error: {e.stderr.strip()}")
        return None

def get_active_track():
    tracks_file = Path("conductor/tracks.md")
    if not tracks_file.exists():
        log_error("conductor/tracks.md not found.")
        return None
    
    content = tracks_file.read_text()
    match = re.search(r"- \[(.*?)\]\((.*?)\) \[~\]", content)
    if not match:
        log_error("No track currently in progress ([~]).")
        return None
    
    return {
        "name": match.group(1),
        "path": Path(match.group(2))
    }

def update_plan(plan_path):
    if not plan_path.exists():
        log_error(f"Plan file not found: {plan_path}")
        return None
    
    content = plan_path.read_text()
    lines = content.splitlines()
    active_task = None
    new_lines = []
    
    for line in lines:
        if "[~]" in line and not active_task:
            active_task = line.replace("[~]", "").strip("- ").strip()
            new_lines.append(line.replace("[~]", "[x]"))
        else:
            new_lines.append(line)
            
    if active_task:
        plan_path.write_text("\n".join(new_lines) + "\n")
        log_success(f"Updated plan.md: task '{active_task}' marked as complete [x].")
        return active_task
    else:
        log_error("No task currently in progress ([~]) in plan.md.")
        return None

def check_phase_completion(plan_path):
    if not plan_path.exists():
        return False
    
    content = plan_path.read_text()
    # Find the current phase
    lines = content.splitlines()
    current_phase = None
    tasks_in_phase = []
    
    # This logic needs to be robust. We'll look for the phase containing [x]
    # and check if all other tasks in that same phase are [x].
    # But since we just marked one as [x], we just need to see if ANY [ ] or [~] remain.
    # Actually, the workflow says "concludes a phase".
    
    # Let's just find all tasks and check their status.
    all_tasks = re.findall(r"- \[(.*?)\]", content)
    if not all_tasks:
        return False
        
    # If all tasks are [x], the track is complete.
    # But we want to know if the CURRENT phase is complete.
    
    # Simpler: check if there are any [ ] or [~] left in the whole file.
    if "[ ]" not in content and "[~]" not in content:
        log_success("All tasks in track are complete.")
        return True
        
    return False

def get_changed_files():
    # Staged, unstaged, and untracked
    staged = run_command("git diff --name-only --cached")
    unstaged = run_command("git diff --name-only")
    untracked = run_command("git ls-files --others --exclude-standard")
    
    files = set()
    if staged: files.update(staged.splitlines())
    if unstaged: files.update(unstaged.splitlines())
    if untracked: files.update(untracked.splitlines())
    
    # Filter out common noise if needed, but for now we list all
    return sorted(list(files))

def main():
    track = get_active_track()
    if not track:
        sys.exit(1)
    
    plan_path = track["path"] / "plan.md"
    active_task = update_plan(plan_path)
    if not active_task:
        sys.exit(1)
        
    phase_complete = check_phase_completion(plan_path)
    files = get_changed_files()
    
    print("\n" + "="*40)
    print("DRAFT GIT NOTE")
    print("="*40)
    print(f"### Task Summary: {active_task}")
    print(f"- **Summary**: [Update this summary with the core 'why' and changes]")
    print(f"- **Files**: {', '.join(files)}")
    if phase_complete:
        print("\n!!! PHASE/TRACK COMPLETE !!!")
        print("Please initiate Phase Completion Verification and Checkpointing Protocol.")
    print("="*40 + "\n")

if __name__ == "__main__":
    main()
