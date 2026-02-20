#!/usr/bin/env python3
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

def run_command(cmd, text=True):
    try:
        result = subprocess.run(cmd, shell=True, check=True, capture_output=True, text=text)
        return result.stdout.strip() if text else result.stdout
    except subprocess.CalledProcessError:
        return None

def is_ignored(path):
    # git check-ignore returns 0 if ignored, 1 if not
    result = subprocess.run(f"git check-ignore -q {path}", shell=True)
    return result.returncode == 0

def check_secrets():
    root_dir = Path.cwd()
    all_files = list(root_dir.rglob("*"))
    
    healthy = []
    out_of_sync = []
    unprotected = []
    errors = []

    log_info("Scanning for sensitive files...")

    # Find all encrypted files
    enc_files = [f for f in all_files if f.suffix == ".enc"]
    
    # Find all potentially sensitive unencrypted files
    sensitive_patterns = [".env", "secret", "creds"]
    unencrypted_sensitive = []
    for f in all_files:
        if f.is_file() and not f.name.endswith(".enc") and not f.name.endswith(".tmpl") and not f.name.endswith(".j2"):
            if any(p in f.name.lower() for p in sensitive_patterns):
                if ".venv" in str(f) or ".git" in str(f) or "node_modules" in str(f):
                    continue
                unencrypted_sensitive.append(f)

    processed_unencrypted = set()

    for enc_path in enc_files:
        rel_enc = enc_path.relative_to(root_dir)
        
        # Determine the likely unencrypted filename
        unenc_name = enc_path.name.replace(".enc", "")
        unenc_path = enc_path.parent / unenc_name
        
        # Try to decrypt (using binary mode to avoid UnicodeDecodeError)
        decrypted_content = run_command(f"sops -d {enc_path}", text=False)
        
        if decrypted_content is None:
            errors.append(f"{rel_enc} (Decryption failed)")
            continue

        if unenc_path.exists():
            rel_unenc = unenc_path.relative_to(root_dir)
            processed_unencrypted.add(unenc_path)
            
            with open(unenc_path, "rb") as f:
                actual_content = f.read()
            
            # Compare binary content (stripped of trailing whitespace for text files)
            if actual_content.strip() == decrypted_content.strip():
                healthy.append(f"{rel_unenc} == {rel_enc}")
            else:
                out_of_sync.append(f"{rel_unenc} != {rel_enc}")
        else:
            healthy.append(f"{rel_enc} (Only encrypted exists)")

    # Check for unprotected files
    for unenc_path in unencrypted_sensitive:
        if unenc_path in processed_unencrypted:
            continue
            
        rel_unenc = unenc_path.relative_to(root_dir)
        if is_ignored(unenc_path):
            continue
        else:
            enc_version = unenc_path.parent / (unenc_path.name + ".enc")
            if not enc_version.exists():
                unprotected.append(str(rel_unenc))

    # Print Report
    print("\n" + "="*40)
    print("SECRETS ENCRYPTION REPORT")
    print("="*40)
    
    if healthy:
        print(f"\n{GREEN}✅ HEALTHY:{RESET}")
        for item in healthy: print(f"  - {item}")
        
    if out_of_sync:
        print(f"\n{YELLOW}⚠️ OUT-OF-SYNC (Unencrypted differs from Encrypted):{RESET}")
        for item in out_of_sync: print(f"  - {item}")
        
    if unprotected:
        print(f"\n{RED}❌ UNPROTECTED (Unencrypted, no .enc version, NOT ignored):{RESET}")
        for item in unprotected: print(f"  - {item}")
        
    if errors:
        print(f"\n{RED}🔒 ERRORS:{RESET}")
        for item in errors: print(f"  - {item}")

    print("\n" + "="*40)
    
    if not out_of_sync and not unprotected and not errors:
        log_success("All secrets are properly protected!")
        return True
    else:
        log_warn("Issues found in secrets protection.")
        return False

if __name__ == "__main__":
    if not check_secrets():
        sys.exit(1)
