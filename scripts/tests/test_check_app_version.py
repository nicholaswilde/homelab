"""Unit tests for scripts/check_app_version.py."""

import os
import sys
from unittest.mock import patch
import pytest

# Add scripts directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from check_app_version import (
    clean_version,
    check_app_version,
    format_table,
    resolve_app_target,
)


def test_clean_version():
    """Verify normalization of version strings."""
    assert clean_version("v3.0.2") == "3.0.2"
    assert clean_version("v26.0.9") == "26.0.9"
    assert clean_version("3.0.2") == "3.0.2"
    assert clean_version("  v1.0.0\n") == "1.0.0"
    assert clean_version(None) == "unknown"
    assert clean_version("") == "unknown"


def test_resolve_app_target_known():
    """Verify known app target resolution."""
    node, vmid, repo, cmd, regex, ver_type, *rest = resolve_app_target("stirling-pdf")
    assert node == "pve04"
    assert vmid == 133
    assert repo == "Stirling-Tools/Stirling-PDF"
    assert cmd is not None
    assert regex is not None
    assert ver_type == "release"


def test_resolve_app_target_drawio():
    """Verify drawio app target resolution."""
    node, vmid, repo, cmd, _, ver_type, *rest = resolve_app_target("drawio")
    assert node == "pve04"
    assert vmid == 136
    assert repo == "jgraph/drawio"
    assert cmd == ["cat", "/var/lib/tomcat10/webapps/draw.version"]
    assert ver_type == "release"


def test_resolve_app_target_homepage():
    """Verify homepage target resolution includes web parser."""
    node, vmid, repo, cmd, _, ver_type, web_parser, web_url = resolve_app_target("homepage")
    assert node == "pve04"
    assert vmid == 110
    assert repo == "gethomepage/homepage"
    assert callable(web_parser)
    assert web_url == "http://192.168.1.47:3000"


def test_check_app_version_up_to_date():
    """Verify comparison when installed equals latest."""
    with patch("check_app_version.get_latest_github_release", return_value="3.0.2"), \
         patch("check_app_version.get_installed_version", return_value="3.0.2"):
        res = check_app_version("stirling-pdf")
        assert res["app"] == "stirling-pdf"
        assert res["installed"] == "3.0.2"
        assert res["latest"] == "3.0.2"
        assert res["status"] == "up-to-date"
        assert res["up_to_date"] is True


def test_check_app_version_update_available():
    """Verify comparison when installed differs from latest."""
    with patch("check_app_version.get_latest_github_release", return_value="3.0.2"), \
         patch("check_app_version.get_installed_version", return_value="2.8.0"):
        res = check_app_version("stirling-pdf")
        assert res["installed"] == "2.8.0"
        assert res["latest"] == "3.0.2"
        assert res["status"] == "update-available"
        assert res["up_to_date"] is False


def test_format_table():
    """Verify table formatter outputs expected headers and content."""
    mock_results = [
        {
            "app": "stirling-pdf",
            "node": "pve04",
            "vmid": 133,
            "installed": "3.0.2",
            "latest": "3.0.2",
            "status": "up-to-date",
        }
    ]
    table = format_table(mock_results)
    assert "App" in table
    assert "stirling-pdf" in table
    assert "3.0.2" in table
    assert "Up to date" in table


def test_parse_homepage_version_from_web():
    """Verify web-based parser extracts version from mocked web responses."""
    with patch("check_app_version.parse_homepage_version_from_web", return_value=("2.4.0", "v2.4.0 (source, Sep 17, 2026)")), \
         patch("check_app_version.get_latest_github_release", return_value="2.4.0"):
        res = check_app_version("homepage")
        assert res["app"] == "homepage"
        assert res["installed"] == "2.4.0"
        assert res["installed_detail"] == "v2.4.0 (source, Sep 17, 2026)"
        assert res["latest"] == "2.4.0"
        assert res["status"] == "up-to-date"
