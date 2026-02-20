#!/usr/bin/env python3
"""
Secret Rotation Script
Securely rotate credentials by generating new values and updating encrypted files.
"""

import os
import secrets
import string
import subprocess
import sys
import argparse
from typing import Optional

def log(level: str, message: str) -> None:
    """Standard logging function."""
    print(f"[{level}] {message}")

def generate_secret(length: int = 32) -> str:
    """Generate a high-entropy secret string."""
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))

def update_env(file_path: str, key: str, value: str) -> None:
    """Update or add a key-value pair in an .env file."""
    lines = []
    found = False
    
    if os.path.exists(file_path):
        with open(file_path, "r") as f:
            lines = f.readlines()
            
    new_lines = []
    for line in lines:
        if line.startswith(f"{key}="):
            new_lines.append(f"{key}={value}\n")
            found = True
        else:
            new_lines.append(line)
            
    if not found:
        new_lines.append(f"{key}={value}\n")
        
    with open(file_path, "w") as f:
        f.writelines(new_lines)

def decrypt_file(enc_file: str, raw_file: str) -> bool:
    """Decrypt a file using SOPS."""
    try:
        subprocess.run(
            ["sops", "-d", enc_file],
            stdout=open(raw_file, "w"),
            check=True
        )
        return True
    except subprocess.CalledProcessError as e:
        log("ERRO", f"Failed to decrypt {enc_file}: {e}")
        return False

def encrypt_file(raw_file: str, enc_file: str) -> bool:
    """Encrypt a file using SOPS."""
    try:
        subprocess.run(
            ["sops", "-e", raw_file],
            stdout=open(enc_file, "w"),
            check=True
        )
        return True
    except subprocess.CalledProcessError as e:
        log("ERRO", f"Failed to encrypt {enc_file}: {e}")
        return False

def main() -> None:
    parser = argparse.ArgumentParser(description="Rotate secrets in .env.enc files.")
    parser.add_argument("--service", help="Name of the service (e.g., activepieces)")
    parser.add_argument("--key", help="The environment variable key to rotate")
    parser.add_argument("--length", type=int, default=32, help="Length of the new secret")
    parser.add_argument("--list", action="store_true", help="List available services and keys")
    
    args = parser.parse_args()
    
    if args.list:
        log("INFO", "Use 'conductor/tracks/rotate-secrets/mapping.md' for reference.")
        return

    if not args.service or not args.key:
        parser.print_help()
        sys.exit(1)

    service_dir = os.path.join("docker", args.service)
    if not os.path.exists(service_dir):
        log("ERRO", f"Service directory not found: {service_dir}")
        sys.exit(1)

    enc_file = os.path.join(service_dir, ".env.enc")
    raw_file = os.path.join(service_dir, ".env")
    
    if not os.path.exists(enc_file):
        log("ERRO", f"Encrypted file not found: {enc_file}")
        sys.exit(1)

    log("INFO", f"Rotating secret '{args.key}' for service '{args.service}'...")
    
    if not decrypt_file(enc_file, raw_file):
        sys.exit(1)
        
    new_secret = generate_secret(args.length)
    update_env(raw_file, args.key, new_secret)
    
    if not encrypt_file(raw_file, enc_file):
        os.remove(raw_file)
        sys.exit(1)
        
    os.remove(raw_file)
    log("INFO", f"Successfully rotated '{args.key}'. New value (hidden) saved to {enc_file}.")
    log("INFO", "Please restart the service to apply changes.")

if __name__ == "__main__":
    main()
