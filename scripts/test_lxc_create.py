import pytest
import subprocess
import os

# Mock pvesh output for nodes
PVESH_NODES_MOCK = """[
  {"node":"pve01","status":"online"},
  {"node":"pve03","status":"online"},
  {"node":"pve04","status":"online"}
]"""

def test_node_selection():
    # This is a placeholder for a test that will fail until implemented
    # We want to verify that the script can list nodes and allow selection
    script_path = os.path.join(os.getcwd(), "scripts/lxc_create.sh")
    
    # We expect the script to prompt for a node if none is provided
    # For TDD, we'll implement a simple check for node listing first
def test_arch_detection():
    script_path = os.path.join(os.getcwd(), "scripts/lxc_create.sh")
    
    # Check for x86_64 node
    result_x86 = subprocess.run([script_path, "--detect-arch", "pve01"], capture_output=True, text=True)
    assert "x86_64" in result_x86.stdout
    
def test_command_generation():
    script_path = os.path.join(os.getcwd(), "scripts/lxc_create.sh")
    
    # Test for standard x86_64 LXC creation command
    # Arguments: --generate-command <node> <vmid> <hostname> <template> <bridge> <ip> <gw>
    args = ["--generate-command", "pve01", "100", "test-lxc", "debian-12-standard_12.0-1_amd64.tar.zst", "vmbr0", "192.168.1.10/24", "192.168.1.1"]
    result = subprocess.run([script_path] + args, capture_output=True, text=True)
    
    assert "pct create 100" in result.stdout
    assert "debian-12-standard_12.0-1_amd64.tar.zst" in result.stdout
def test_post_setup_commands():
    script_path = os.path.join(os.getcwd(), "scripts/lxc_create.sh")
    
    # Test for post-setup command generation
    # Argument: --generate-setup <vmid>
    args = ["--generate-setup", "100"]
    result = subprocess.run([script_path] + args, capture_output=True, text=True)
    
    # Check for core commands we expect in the post-setup
    assert "pct exec 100 -- apt update" in result.stdout
    assert "pct exec 100 -- apt upgrade -y" in result.stdout
    assert "pct exec 100 -- apt install -y curl vim git htop sudo" in result.stdout
    assert "pct exec 100 -- useradd" in result.stdout
    assert "pct exec 100 -- tee /etc/sudoers.d/" in result.stdout
