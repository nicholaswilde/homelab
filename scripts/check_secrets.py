#!/usr/bin/env python3
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
RESET = "\033[0m"

SECRET_PATTERNS = [
    (re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC |DSA |PGP )?PRIVATE KEY-----"), "Private key header"),
    (re.compile(r"\bAKIA[0-9A-Z]{16}\b"), "AWS Access Key ID"),
    (re.compile(r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,}\b"), "GitHub personal token"),
    (re.compile(r"\bgithub_pat_[A-Za-z0-9_]{82}\b"), "GitHub fine-grained PAT"),
]

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
        sops_cmd = f"sops -d {enc_path}"
        if unenc_name.endswith(".env"):
            sops_cmd = f"sops -d --input-type dotenv --output-type dotenv {enc_path}"
        elif unenc_name.endswith(".json"):
            sops_cmd = f"sops -d --output-type json {enc_path}"
        elif unenc_name.endswith(".yaml") or unenc_name.endswith(".yml"):
            sops_cmd = f"sops -d --output-type yaml {enc_path}"
            
        decrypted_content = run_command(sops_cmd, text=False)
        
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


def check_staged_secrets() -> bool:
    """Inspect staged files in git index to prevent committing plaintext secrets."""
    log_info("Running pre-commit check on staged files...")
    res = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        log_error("Failed to inspect git staging area.")
        return False

    staged_files = [f.strip() for f in res.stdout.splitlines() if f.strip()]
    if not staged_files:
        log_success("No staged files found in git index.")
        return True

    violations = []

    for path_str in staged_files:
        p = Path(path_str)
        name_lower = p.name.lower()

        # 1. Plaintext .env files
        if name_lower.startswith(".env") or name_lower.endswith(".env"):
            if not any(
                name_lower.endswith(ext)
                for ext in [".enc", ".tmpl", ".sample", ".example", ".default"]
            ):
                violations.append(f"Forbidden plaintext .env file staged: {path_str}")

        # 2. Private key / credential extensions
        if any(name_lower.endswith(ext) for ext in [".pem", ".key", ".pkcs12", ".pfx"]):
            if not name_lower.endswith(".enc"):
                violations.append(f"Forbidden private key file staged: {path_str}")
        if name_lower in ["id_rsa", "id_ed25519", "id_ecdsa", "id_dsa"]:
            violations.append(f"Forbidden SSH private key file staged: {path_str}")

        # 3. .enc files must contain SOPS encryption markers
        if name_lower.endswith(".enc"):
            try:
                show_proc = subprocess.run(
                    ["git", "show", f":{path_str}"],
                    capture_output=True,
                    text=True,
                )
                if show_proc.returncode == 0:
                    content = show_proc.stdout
                    if "sops" not in content and "ENC[" not in content:
                        violations.append(
                            f"File has .enc extension but lacks SOPS encryption metadata: {path_str}"
                        )
            except Exception:
                pass

        # 4. Content patterns in staged diff additions (exclude test suites)
        if not name_lower.endswith(".enc") and not ("/tests/" in path_str or p.name.startswith("test_")):
            diff_proc = subprocess.run(
                ["git", "diff", "--cached", "-U0", "--", path_str],
                capture_output=True,
                text=True,
            )
            if diff_proc.returncode == 0:
                for line in diff_proc.stdout.splitlines():
                    if line.startswith("+") and not line.startswith("+++"):
                        added_text = line[1:]
                        for pattern, label in SECRET_PATTERNS:
                            if pattern.search(added_text):
                                violations.append(
                                    f"Detected {label} in staged diff: {path_str}"
                                )

    if violations:
        print("\n" + "=" * 40)
        print(f"{RED}❌ PRE-COMMIT SECRET VERIFICATION FAILED{RESET}")
        print("=" * 40)
        for v in violations:
            log_error(v)
        print("=" * 40)
        log_error("Commit aborted. Staging contains plaintext secrets or unencrypted credential files.")
        return False

    log_success(f"Verified {len(staged_files)} staged file(s) - zero plaintext secrets detected.")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Verify secret encryption and prevent committing plaintext secrets."
    )
    parser.add_argument(
        "--staged",
        action="store_true",
        help="Check only git staged files (fast pre-commit hook mode)",
    )
    args = parser.parse_args()

    if args.staged:
        if not check_staged_secrets():
            sys.exit(1)
    else:
        if not check_secrets():
            sys.exit(1)


if __name__ == "__main__":
    main()

