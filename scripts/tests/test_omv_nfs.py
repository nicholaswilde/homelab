"""Unit tests for scripts/omv_nfs.py."""

import os
import subprocess
import sys
from unittest.mock import patch

# Add scripts directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from omv_nfs import check_status, fix_omv, run_ssh


def test_run_ssh_success():
    """Verify run_ssh parses subprocess success."""
    with patch("subprocess.run") as mock_run:
        mock_run.return_value = subprocess.CompletedProcess(
            args=["ssh"], returncode=0, stdout="pong\n", stderr=""
        )
        rc, stdout, stderr = run_ssh("host", "echo pong")
        assert rc == 0
        assert stdout == "pong"
        assert stderr == ""


def test_run_ssh_timeout():
    """Verify run_ssh handles TimeoutExpired gracefully."""
    with patch("subprocess.run") as mock_run:
        mock_run.side_effect = subprocess.TimeoutExpired(cmd=["ssh"], timeout=10)
        rc, stdout, stderr = run_ssh("host", "sleep 20")
        assert rc == 124
        assert "timed out" in stderr


def test_check_status_healthy():
    """Verify check_status returns healthy when all checks succeed."""
    pve_output = "status: running\n---\nBus 002 Device 002: ID 0bc2:ab31 Seagate\n---\nusb0: host=0bc2:ab31"
    omv_output = (
        "Bus 001 Device 002: ID 0bc2:ab31\n"
        "---\n"
        "5260fcea-c15a-4e0f-8b31-95bca0dc0d63\n"
        "---\n"
        "mounted\n"
        "---\n"
        "active\n"
        "---\n"
        "listening\n"
        "---\n"
        "/export/storage *(rw)"
    )

    def fake_ssh(host, cmd, timeout=10):
        if host == "pve01":
            return 0, pve_output, ""
        if host == "omv":
            if "mountpoint -q /export" in cmd:
                return 0, "", ""
            return 0, omv_output, ""
        return 1, "", "unknown host"

    with patch("omv_nfs.run_ssh", side_effect=fake_ssh):
        status = check_status()
        assert status["pve"]["reachable"] is True
        assert status["pve"]["vm_running"] is True
        assert status["pve"]["host_usb_detected"] is True
        assert status["pve"]["vm_passthrough_configured"] is True
        assert status["omv"]["reachable"] is True
        assert status["omv"]["usb_detected"] is True
        assert status["omv"]["disk_detected"] is True
        assert status["omv"]["base_mounted"] is True
        assert status["omv"]["nfs_active"] is True
        assert status["omv"]["nfs_listening"] is True
        assert status["healthy"] is True


def test_check_status_unhealthy_pve_offline():
    """Verify check_status returns unhealthy when PVE is unreachable."""
    with patch("omv_nfs.run_ssh", return_value=(255, "", "Connection refused")):
        status = check_status()
        assert status["pve"]["reachable"] is False
        assert status["healthy"] is False


def test_fix_omv():
    """Verify fix_omv executes expected repair actions."""
    status_unhealthy = {
        "pve": {"host_usb_detected": True},
        "omv": {"usb_detected": False, "base_mounted": False, "all_bind_mounts_ok": False},
    }
    status_healthy = {"healthy": True}

    with patch("omv_nfs.run_ssh", return_value=(0, "ok", "")) as mock_ssh, patch(
        "omv_nfs.check_status", return_value=status_healthy
    ):
        healthy, actions = fix_omv(status_before=status_unhealthy)
        assert healthy is True
        assert len(actions) == 3
        assert mock_ssh.call_count == 3
