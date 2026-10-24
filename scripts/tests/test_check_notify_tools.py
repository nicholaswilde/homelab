"""Unit tests for check_notify_tools.py."""

from unittest.mock import patch, MagicMock
import pytest

from check_notify_tools import (
    clean_version,
    extract_version_from_output,
    extract_version_from_title,
    compare_tool_versions,
    determine_upgrade_cmd,
    check_notify_tools,
    format_table,
)


def test_clean_version():
    """Verify version normalization."""
    assert clean_version("v1.2.3") == "1.2.3"
    assert clean_version("release-0.27.1") == "0.27.1"
    assert clean_version("  v0.0.72 \n") == "0.0.72"
    assert clean_version("") == "unknown"


def test_extract_version_from_output():
    """Verify extracting version from CLI command output."""
    assert extract_version_from_output("zensical 0.0.69") == "0.0.69"
    assert extract_version_from_output("Task version: v3.54.0 (h1:xyz)") == "3.54.0"
    assert extract_version_from_output("tmux 3.4") == "3.4"
    assert extract_version_from_output("shuck 0.2.3") == "0.2.3"


def test_compare_tool_versions():
    """Verify comparing tool versions."""
    status, ok = compare_tool_versions("0.0.72", "0.0.72")
    assert status == "up-to-date"
    assert ok is True

    status, ok = compare_tool_versions("0.0.69", "0.0.72")
    assert status == "update-available"
    assert ok is False

    status, ok = compare_tool_versions("not installed", "1.0.0")
    assert status == "not installed"
    assert ok is False


def test_determine_upgrade_cmd():
    """Verify upgrade command generation logic."""
    uv_tools = {"zensical": "0.0.69"}
    cmd = determine_upgrade_cmd("zensical", "/path/to/zensical", uv_tools)
    assert cmd == "uv tool upgrade zensical"

    cmd = determine_upgrade_cmd("task", "/home/linuxbrew/.linuxbrew/bin/task", {}, brew_formula="go-task")
    assert cmd == "brew upgrade go-task"

    cmd = determine_upgrade_cmd("uv", "/usr/bin/uv", {}, custom_upgrade="uv self update")
    assert cmd == "uv self update"


@patch("check_notify_tools.fetch_notifications")
@patch("check_notify_tools.get_installed_tool_version")
@patch("check_notify_tools.get_uv_tools")
def test_check_notify_tools(mock_uv_tools, mock_installed, mock_fetch):
    """Verify matching and comparing tools from notifications."""
    mock_fetch.return_value = [
        {
            "subject": {"type": "Release", "title": "0.0.72", "url": None},
            "repository": {"full_name": "zensical/zensical", "name": "zensical"},
            "updated_at": "2026-10-23T14:52:04Z",
        },
        {
            "subject": {"type": "Release", "title": "v3.55.0", "url": None},
            "repository": {"full_name": "go-task/task", "name": "task"},
            "updated_at": "2026-10-24T00:23:33Z",
        },
    ]

    mock_uv_tools.return_value = {"zensical": "0.0.69"}
    mock_installed.return_value = ("3.54.0", "/home/linuxbrew/.linuxbrew/bin/task")

    results = check_notify_tools()
    tools = {r["tool"]: r for r in results}

    assert "zensical" in tools
    assert tools["zensical"]["installed"] == "0.0.69"
    assert tools["zensical"]["notified"] == "0.0.72"
    assert tools["zensical"]["status"] == "update-available"
    assert tools["zensical"]["upgrade_cmd"] == "uv tool upgrade zensical"

    assert "task" in tools
    assert tools["task"]["installed"] == "3.54.0"
    assert tools["task"]["notified"] == "3.55.0"
    assert tools["task"]["status"] == "update-available"
    assert tools["task"]["upgrade_cmd"] == "brew upgrade go-task"


def test_format_table():
    """Verify table formatting."""
    results = [
        {
            "tool": "zensical",
            "installed": "0.0.69",
            "notified": "0.0.72",
            "status": "update-available",
            "bin_path": "/home/nicholas/.local/bin/zensical",
            "upgrade_cmd": "uv tool upgrade zensical",
        }
    ]
    table = format_table(results)
    assert "zensical" in table
    assert "0.0.69" in table
    assert "0.0.72" in table
    assert "Update available" in table
