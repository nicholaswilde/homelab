"""Unit tests for scripts/check_secrets.py."""

import os
import subprocess
import sys
from unittest.mock import patch

# Add scripts directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from check_secrets import check_staged_secrets


def test_check_staged_clean():
    """Verify check_staged_secrets passes on safe files."""
    def fake_run(cmd, *args, **kwargs):
        if "git diff --cached --name-only" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="README.md\ndocker/app/compose.yaml\n"
            )
        if "git diff --cached -U0" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="+version: '3.8'\n"
            )
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="")

    with patch("subprocess.run", side_effect=fake_run):
        assert check_staged_secrets() is True


def test_check_staged_env_violation():
    """Verify check_staged_secrets flags forbidden plaintext .env file."""
    def fake_run(cmd, *args, **kwargs):
        if "git diff --cached --name-only" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="docker/app/.env\n"
            )
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="")

    with patch("subprocess.run", side_effect=fake_run):
        assert check_staged_secrets() is False


def test_check_staged_private_key_file():
    """Verify check_staged_secrets flags forbidden private key file."""
    def fake_run(cmd, *args, **kwargs):
        if "git diff --cached --name-only" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="id_ed25519\n"
            )
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="")

    with patch("subprocess.run", side_effect=fake_run):
        assert check_staged_secrets() is False


def test_check_staged_private_key_content():
    """Verify check_staged_secrets flags private key block in diff."""
    def fake_run(cmd, *args, **kwargs):
        if "git diff --cached --name-only" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="config.yml\n"
            )
        if "git diff --cached -U0" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd,
                returncode=0,
                stdout="+-----BEGIN RSA PRIVATE KEY-----\n+secretbytes\n",
            )
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="")

    with patch("subprocess.run", side_effect=fake_run):
        assert check_staged_secrets() is False


def test_check_staged_aws_key_content():
    """Verify check_staged_secrets flags AWS access key ID in diff."""
    def fake_run(cmd, *args, **kwargs):
        if "git diff --cached --name-only" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="config.py\n"
            )
        if "git diff --cached -U0" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd,
                returncode=0,
                stdout="+aws_key = 'AKIAIOSFODNN7EXAMPLE'\n",
            )
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="")

    with patch("subprocess.run", side_effect=fake_run):
        assert check_staged_secrets() is False


def test_check_staged_enc_valid():
    """Verify check_staged_secrets passes valid SOPS-encrypted file."""
    def fake_run(cmd, *args, **kwargs):
        if "git diff --cached --name-only" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="lxc/app/.env.enc\n"
            )
        if "git show" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="sops:\n    mac: ENC[AES256_GCM...]\n"
            )
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="")

    with patch("subprocess.run", side_effect=fake_run):
        assert check_staged_secrets() is True


def test_check_staged_enc_fake():
    """Verify check_staged_secrets rejects .enc file lacking SOPS metadata."""
    def fake_run(cmd, *args, **kwargs):
        if "git diff --cached --name-only" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="lxc/app/.env.enc\n"
            )
        if "git show" in " ".join(cmd):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="PASSWORD=supersecretplaintext\n"
            )
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="")

    with patch("subprocess.run", side_effect=fake_run):
        assert check_staged_secrets() is False
