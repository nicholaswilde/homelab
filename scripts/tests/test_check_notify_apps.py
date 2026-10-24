"""Unit tests for check_notify_apps.py."""

from unittest.mock import patch, MagicMock
from pathlib import Path
import pytest

from check_notify_apps import (
    extract_version_from_title,
    resolve_release_version,
    compare_versions,
    build_repo_to_app_map,
    check_notify_apps,
    format_table,
)


def test_extract_version_from_title():
    """Verify version string extraction from various GitHub release title formats."""
    assert extract_version_from_title("v5.10.2") == "5.10.2"
    assert extract_version_from_title("Release 0.27.1") == "0.27.1"
    assert extract_version_from_title("v3.55.0-nightly") == "3.55.0-nightly"
    assert extract_version_from_title("2026.10.3") == "2026.10.3"
    assert extract_version_from_title("Custom Announcement") == "Custom Announcement"


@patch("subprocess.run")
def test_resolve_release_version(mock_run):
    """Verify fallback to release API when title has no digits."""
    mock_run.return_value = MagicMock(
        returncode=0,
        stdout='{"tag_name": "v3.2.1"}',
    )
    ver = resolve_release_version("Viewer improvements", "https://api.github.com/repos/x/y/releases/1")
    assert ver == "3.2.1"


def test_compare_versions():
    """Verify version comparison semantics."""
    status, ok = compare_versions("5.10.2", "5.10.2")
    assert status == "up-to-date"
    assert ok is True

    status, ok = compare_versions("5.10.1", "5.10.2")
    assert status == "update-available"
    assert ok is False

    status, ok = compare_versions("unknown", "1.0.0")
    assert status == "unknown"
    assert ok is False


def test_build_repo_to_app_map():
    """Verify building repo to app mapping."""
    mapping = build_repo_to_app_map()
    assert "ellite/wallos" in mapping
    assert mapping["ellite/wallos"] == "wallos"
    assert "sysadminsmedia/homebox" in mapping
    assert mapping["sysadminsmedia/homebox"] == "homebox"


@patch("check_notify_apps.check_app_version")
@patch("check_notify_apps.fetch_notifications")
def test_check_notify_apps_matching(mock_fetch, mock_check_app):
    """Verify checking release notifications against known apps."""
    mock_fetch.return_value = [
        {
            "subject": {"type": "Release", "title": "v5.10.2", "url": None},
            "repository": {"full_name": "ellite/Wallos"},
            "updated_at": "2026-10-23T22:24:38Z",
        },
        {
            "subject": {"type": "Issue", "title": "Bug report", "url": None},
            "repository": {"full_name": "ellite/Wallos"},
            "updated_at": "2026-10-23T20:00:00Z",
        },
    ]

    mock_check_app.return_value = {
        "installed": "5.10.2",
        "node": "pve03",
        "vmid": 116,
    }

    results = check_notify_apps()
    assert len(results) == 1
    assert results[0]["app"] == "wallos"
    assert results[0]["installed"] == "5.10.2"
    assert results[0]["notified"] == "5.10.2"
    assert results[0]["status"] == "up-to-date"
    assert results[0]["up_to_date"] is True


def test_format_table():
    """Verify table formatting."""
    results = [
        {
            "app": "wallos",
            "node": "pve03",
            "vmid": 116,
            "installed": "5.10.2",
            "notified": "5.10.2",
            "status": "up-to-date",
            "update_cmd": "rtk uv run python scripts/lxc_update.py wallos --node pve03",
        }
    ]
    table = format_table(results)
    assert "wallos" in table
    assert "pve03" in table
    assert "Up to date" in table
