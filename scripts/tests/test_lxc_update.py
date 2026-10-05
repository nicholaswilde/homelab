"""Unit tests for scripts/lxc_update.py."""

import os
import sys
from unittest.mock import MagicMock, patch
import pytest

# Add scripts directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from lxc_update import (
    build_pct_exec_cmd,
    find_lxc_container,
    get_update_script_path,
    parse_pct_list,
    update_lxc,
)

SAMPLE_PCT_LIST = """VMID       Status     Lock         Name                
100        running                 dnsspeedtest        
101        running                 netbootxyz          
136        running                 drawio              
137        stopped                 rackula             
"""


def test_parse_pct_list():
    """Verify that pct list output is correctly parsed into structured dictionaries."""
    containers = parse_pct_list(SAMPLE_PCT_LIST)
    assert len(containers) == 4
    assert containers[0] == {"vmid": 100, "status": "running", "name": "dnsspeedtest"}
    assert containers[2] == {"vmid": 136, "status": "running", "name": "drawio"}
    assert containers[3] == {"vmid": 137, "status": "stopped", "name": "rackula"}


def test_parse_pct_list_empty():
    """Verify empty or header-only output returns empty list."""
    assert parse_pct_list("") == []
    assert parse_pct_list("VMID       Status     Lock         Name\n") == []


def test_get_update_script_path():
    """Verify update script path resolution for lxc, pve, and docker apps."""
    assert get_update_script_path("drawio") == "/root/git/nicholaswilde/homelab/lxc/drawio/update.sh"
    assert get_update_script_path("traefik") == "/root/git/nicholaswilde/homelab/pve/traefik/update.sh"
    assert get_update_script_path("convertx") == "/root/git/nicholaswilde/homelab/docker/convertx/update.sh"
    assert get_update_script_path("custom") == "/root/git/nicholaswilde/homelab/lxc/custom/update.sh"


def test_build_pct_exec_cmd():
    """Verify pct exec SSH command structure."""
    cmd = build_pct_exec_cmd("pve04", 136, ["bash", "/path/to/update.sh", "-v", "32.0.2"])
    expected = [
        "ssh",
        "pve04",
        "pct",
        "exec",
        "136",
        "--",
        "bash",
        "/path/to/update.sh",
        "-v",
        "32.0.2",
    ]
    assert cmd == expected


@patch("lxc_update.run_ssh_command")
def test_find_lxc_container(mock_ssh):
    """Verify finding container across nodes."""
    mock_ssh.side_effect = [
        (0, SAMPLE_PCT_LIST, ""),  # pve04 has drawio
    ]
    found = find_lxc_container("drawio", nodes=["pve04"])
    assert found == ("pve04", 136, "drawio", "running")


@patch("lxc_update.run_ssh_command")
def test_find_lxc_container_not_found(mock_ssh):
    """Verify returning None when container is not found on any node."""
    mock_ssh.return_value = (0, SAMPLE_PCT_LIST, "")
    found = find_lxc_container("nonexistent", nodes=["pve04"])
    assert found is None


@patch("lxc_update.find_lxc_container")
def test_update_lxc_dry_run(mock_find):
    """Verify update_lxc honors dry_run mode without executing commands."""
    mock_find.return_value = ("pve04", 136, "drawio", "running")
    result = update_lxc("drawio", version="32.0.2", dry_run=True)
    assert result is True
