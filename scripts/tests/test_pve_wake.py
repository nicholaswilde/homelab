"""Unit tests for scripts/pve_wake.py."""

import os
import subprocess
import sys
from unittest.mock import MagicMock, patch

# Add scripts directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pve_wake import (
    ensure_node_on,
    get_node_details,
    ping_node,
    run_ssh,
    send_wol_packet,
    send_wol_via_helper,
)


def test_ping_node_success():
    """Verify ping_node returns True on successful returncode."""
    with patch("subprocess.run") as mock_run:
        mock_run.return_value = subprocess.CompletedProcess(args=["ping"], returncode=0)
        assert ping_node("192.168.1.141") is True


def test_ping_node_failure():
    """Verify ping_node returns False on non-zero returncode."""
    with patch("subprocess.run") as mock_run:
        mock_run.return_value = subprocess.CompletedProcess(args=["ping"], returncode=1)
        assert ping_node("192.168.1.141") is False


def test_send_wol_packet_valid():
    """Verify send_wol_packet sends magic packet over UDP broadcast."""
    with patch("socket.socket") as mock_sock_cls:
        mock_sock = MagicMock()
        mock_sock_cls.return_value.__enter__.return_value = mock_sock
        success = send_wol_packet("1c:69:7a:a6:86:d5")
        assert success is True
        assert mock_sock.sendto.called


def test_send_wol_packet_invalid():
    """Verify send_wol_packet rejects invalid MAC."""
    success = send_wol_packet("invalid-mac")
    assert success is False


def test_send_wol_via_helper():
    """Verify send_wol_via_helper executes remote python command."""
    with patch("pve_wake.run_ssh", return_value=(0, "", "")) as mock_ssh:
        success = send_wol_via_helper("pve01", "1c:69:7a:a6:86:d5")
        assert success is True
        assert mock_ssh.called


def test_get_node_details():
    """Verify get_node_details parses uptime, quorum, and guests."""
    output = "up 5 days\n===SECTION===\nQuorate:          Yes\n===SECTION===\nVMID Status\n101 running\n102 stopped"
    with patch("pve_wake.run_ssh", return_value=(0, output, "")):
        details = get_node_details("pve03")
        assert details["uptime"] == "up 5 days"
        assert details["cluster_quorate"] is True
        assert details["total_guests"] == 2
        assert details["active_guests"] == 1


def test_ensure_node_on_already_online():
    """Verify ensure_node_on skips wake when node is already responding."""
    with patch("pve_wake.ping_node", return_value=True), patch(
        "pve_wake.get_node_details", return_value={"uptime": "up 1 day"}
    ):
        res = ensure_node_on("pve03")
        assert res["initially_online"] is True
        assert res["woken_up"] is False
        assert res["final_online"] is True


def test_ensure_node_on_wakes_offline_node():
    """Verify ensure_node_on sends WOL and waits when initially offline."""
    with patch("pve_wake.ping_node") as mock_ping, patch(
        "pve_wake.send_wol_packet", return_value=True
    ), patch("pve_wake.send_wol_via_helper", return_value=True), patch(
        "pve_wake.run_ssh", return_value=(0, "pve03", "")
    ), patch(
        "pve_wake.get_node_details", return_value={"uptime": "up 1 min"}
    ), patch(
        "time.sleep", return_value=None
    ):
        # 1st call: initial check (offline)
        # 2nd call: helper pve01 check (online)
        # 3rd call: loop poll for target (now online)
        mock_ping.side_effect = [False, True, True]
        res = ensure_node_on("pve03", timeout_sec=10)
        assert res["initially_online"] is False
        assert res["woken_up"] is True
        assert res["final_online"] is True
