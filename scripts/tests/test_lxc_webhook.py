"""Unit tests for scripts/lxc_webhook.py."""

import json
from pathlib import Path
from unittest.mock import MagicMock, patch
import pytest

from lxc_webhook import (
    generate_hooks_json,
    generate_service_unit,
    scaffold_taskfile_targets,
    scaffold_webhook_files,
    parse_pct_list,
    find_lxc_container,
    get_container_ip,
    deploy_webhook_service,
    trigger_webhook_test,
    register_cd_watch,
)


def test_generate_hooks_json():
    """Verify generated hooks.json contains expected structure and app name."""
    content = generate_hooks_json("wallos")
    data = json.loads(content)
    assert isinstance(data, list)
    assert len(data) == 1
    hook = data[0]
    assert hook["id"] == "update-app"
    assert "lxc/wallos/update.sh" in hook["execute-command"]
    assert "lxc/wallos" in hook["command-working-directory"]
    assert hook["response-message"] == "Updating wallos..."


def test_generate_service_unit():
    """Verify generated systemd unit has standard PATH and ExecStart."""
    service_content = generate_service_unit("wallos")
    assert "Description=wallos Webhook Listener" in service_content
    assert "Environment=PATH=" in service_content
    assert "ExecStart=/usr/bin/webhook -hooks hooks.json -verbose -port 9000" in service_content
    assert "WorkingDirectory=/root/git/nicholaswilde/homelab/lxc/wallos" in service_content


def test_scaffold_taskfile_targets_injection():
    """Test injecting wh:* targets into existing Taskfile content."""
    original = """version: '3'
tasks:
  update:
    desc: Update app
    cmds:
      - ./update.sh
  default:
    cmds:
      - task -l
"""
    result = scaffold_taskfile_targets(original, "testapp")
    assert "wh:install:" in result
    assert "wh:status:" in result
    assert "wh:logs:" in result
    assert "wh:test:" in result
    assert "testapp-webhook.service" in result
    # Ensure not duplicated if run again
    second_result = scaffold_taskfile_targets(result, "testapp")
    assert second_result == result


def test_scaffold_webhook_files(tmp_path):
    """Test end-to-end local file scaffolding in temporary directory."""
    app_dir = tmp_path / "testapp"
    app_dir.mkdir()
    taskfile = app_dir / "Taskfile.yml"
    taskfile.write_text("version: '3'\ntasks:\n  default:\n    cmds:\n      - task -l\n")

    ok = scaffold_webhook_files("testapp", app_dir=app_dir)
    assert ok is True

    hooks_file = app_dir / "hooks.json"
    service_file = app_dir / "testapp-webhook.service"

    assert hooks_file.exists()
    assert service_file.exists()

    hooks_data = json.loads(hooks_file.read_text())
    assert hooks_data[0]["id"] == "update-app"

    updated_taskfile = taskfile.read_text()
    assert "wh:install:" in updated_taskfile


def test_parse_pct_list():
    """Verify parsing pct list output."""
    raw = """VMID       Status     Lock         Name
104        running                 omni-tools
116        running                 changedetection
136        running                 drawio
"""
    containers = parse_pct_list(raw)
    assert len(containers) == 3
    assert containers[0]["vmid"] == 104
    assert containers[0]["name"] == "omni-tools"
    assert containers[2]["name"] == "drawio"


@patch("lxc_webhook.run_ssh_command")
def test_find_lxc_container(mock_ssh):
    """Test locating container across nodes."""
    mock_ssh.return_value = (
        0,
        "VMID       Status     Lock         Name\n136        running                 drawio\n",
        "",
    )
    result = find_lxc_container("drawio", nodes=["pve04"])
    assert result is not None
    node, vmid, name, status = result
    assert node == "pve04"
    assert vmid == 136
    assert name == "drawio"
    assert status == "running"


@patch("lxc_webhook.run_ssh_command")
def test_get_container_ip(mock_ssh):
    """Test retrieving IPv4 from container hostname -I."""
    mock_ssh.return_value = (0, "192.168.1.237 fd8b::1\n", "")
    ip = get_container_ip("pve04", 136)
    assert ip == "192.168.1.237"


@patch("lxc_webhook.run_ssh_command")
@patch("lxc_webhook.find_lxc_container")
def test_deploy_webhook_service(mock_find, mock_ssh):
    """Test deploying webhook service to running container."""
    mock_find.return_value = ("pve04", 136, "drawio", "running")
    # First call: which webhook (returns 0)
    # Second call: setup_cmd (returns active)
    mock_ssh.side_effect = [
        (0, "/usr/bin/webhook\n", ""),
        (0, "active\n", ""),
    ]
    ok = deploy_webhook_service("drawio", node="pve04")
    assert ok is True


@patch("urllib.request.urlopen")
def test_test_webhook_listener_success(mock_urlopen):
    """Test sending test trigger to webhook endpoint."""
    mock_resp = MagicMock()
    mock_resp.getcode.return_value = 200
    mock_resp.read.return_value = b"Updating testapp..."
    mock_urlopen.return_value.__enter__.return_value = mock_resp

    ok = trigger_webhook_test("testapp", ip="192.168.1.237")
    assert ok is True
