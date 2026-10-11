#!/usr/bin/env python3
"""LXC Application Webhook & Auto-Update Manager.

Automates:
1. Scaffolding `hooks.json`, `<app>-webhook.service`, and `Taskfile.yml` targets.
2. Deploying the webhook listener inside Proxmox LXC containers (installing package, enabling service).
3. Sending test triggers to verify webhook execution.
4. Configuring ChangeDetection.io release watches to notify the webhook endpoint.
"""

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple
import urllib.error
import urllib.request

# Ensure scripts dir in sys.path
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.append(str(SCRIPT_DIR))

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
CYAN = "\033[38;2;148;226;213m"
RESET = "\033[0m"

DEFAULT_NODES: List[str] = ["pve04", "pve03", "pve01"]
DEFAULT_CD_HOST: str = "http://192.168.1.72:5000"
CD_CONTAINER_VMID: int = 116
CD_NODE: str = "pve04"


def log_info(msg: str) -> None:
    """Print info message in Catppuccin blue."""
    print(f"{BLUE}INFO{RESET}: {msg}")


def log_warn(msg: str) -> None:
    """Print warning message in Catppuccin yellow."""
    print(f"{YELLOW}WARN{RESET}: {msg}")


def log_error(msg: str) -> None:
    """Print error message in Catppuccin red."""
    print(f"{RED}ERRO{RESET}: {msg}")


def log_success(msg: str) -> None:
    """Print success message in Catppuccin green."""
    print(f"{GREEN}SUCC{RESET}: {msg}")


def run_ssh_command(
    node: str, cmd_args: List[str], timeout: int = 15, input_data: Optional[str] = None
) -> Tuple[int, str, str]:
    """Execute command on remote node over SSH and return (exit_code, stdout, stderr)."""
    quoted_cmd = " ".join(shlex.quote(arg) for arg in cmd_args)
    full_cmd = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        f"ConnectTimeout={timeout}",
        node,
        quoted_cmd,
    ]
    try:
        proc = subprocess.run(
            full_cmd,
            input=input_data,
            capture_output=True,
            text=True,
            timeout=timeout + 5,
            check=False,
        )
        return proc.returncode, proc.stdout, proc.stderr
    except subprocess.TimeoutExpired:
        return 124, "", f"Command timed out after {timeout} seconds"
    except Exception as e:
        return 1, "", str(e)


def parse_pct_list(stdout: str) -> List[Dict[str, Any]]:
    """Parse output of `pct list` into a list of container metadata dictionaries."""
    containers = []
    lines = stdout.strip().splitlines()
    if not lines:
        return containers

    for line in lines[1:]:
        line = line.strip()
        if not line:
            continue
        parts = re.split(r"\s+", line)
        if len(parts) >= 3 and parts[0].isdigit():
            containers.append(
                {
                    "vmid": int(parts[0]),
                    "status": parts[1].lower(),
                    "name": parts[-1].lower(),
                }
            )
    return containers


def find_lxc_container(
    app_name: str,
    node: Optional[str] = None,
    nodes: Optional[List[str]] = None,
) -> Optional[Tuple[str, int, str, str]]:
    """Locate container matching app_name across Proxmox nodes.

    Returns (node, vmid, container_name, status) or None if not found.
    """
    search_nodes = [node] if node else (nodes or DEFAULT_NODES)
    target = app_name.lower().strip()

    for n in search_nodes:
        ret, stdout, stderr = run_ssh_command(n, ["pct", "list"])
        if ret != 0:
            log_warn(f"Failed to query {n}: {stderr.strip() or 'unreachable'}")
            continue

        containers = parse_pct_list(stdout)
        # 1. Exact match
        for ct in containers:
            if ct["name"] == target:
                return n, ct["vmid"], ct["name"], ct["status"]

        # 2. Normalized match (ignore hyphens and underscores)
        target_norm = target.replace("-", "").replace("_", "")
        for ct in containers:
            ct_norm = ct["name"].replace("-", "").replace("_", "")
            if ct_norm == target_norm:
                return n, ct["vmid"], ct["name"], ct["status"]

        # 3. Substring match fallback
        for ct in containers:
            if target in ct["name"] or ct["name"] in target:
                return n, ct["vmid"], ct["name"], ct["status"]

    return None


def get_container_ip(node: str, vmid: int) -> Optional[str]:
    """Retrieve primary IPv4 address of an LXC container using `hostname -I`."""
    ret, stdout, stderr = run_ssh_command(node, ["pct", "exec", str(vmid), "--", "hostname", "-I"])
    if ret != 0 or not stdout.strip():
        # Fallback to ip -4 addr show eth0
        ret, stdout, stderr = run_ssh_command(
            node, ["pct", "exec", str(vmid), "--", "ip", "-4", "addr", "show", "eth0"]
        )
        if ret == 0:
            match = re.search(r"inet\s+(\d+\.\d+\.\d+\.\d+)", stdout)
            if match:
                return match.group(1)
        return None

    # hostname -I prints space-separated IPs; grab first IPv4
    for part in stdout.strip().split():
        if re.match(r"^\d+\.\d+\.\d+\.\d+$", part) and not part.startswith("127."):
            return part
    return None


def resolve_app_rel_dir(app_name: str) -> str:
    """Find relative path of application directory (lxc/app or pve/app)."""
    clean_name = app_name.lower().strip()
    if (REPO_ROOT / "pve" / clean_name).is_dir():
        return f"pve/{clean_name}"
    return f"lxc/{clean_name}"


def generate_hooks_json(app_name: str) -> str:
    """Generate hooks.json content for an application."""
    rel_path = resolve_app_rel_dir(app_name)
    hook_data = [
        {
            "id": "update-app",
            "execute-command": f"/root/git/nicholaswilde/homelab/{rel_path}/update.sh",
            "command-working-directory": f"/root/git/nicholaswilde/homelab/{rel_path}",
            "pass-arguments-to-command": [
                {
                    "source": "string",
                    "name": "-s",
                }
            ],
            "response-message": f"Updating {app_name}...",
        }
    ]
    return json.dumps(hook_data, indent=2) + "\n"


def generate_service_unit(app_name: str) -> str:
    """Generate systemd service unit content for webhook listener."""
    rel_path = resolve_app_rel_dir(app_name)
    return f"""[Unit]
Description={app_name} Webhook Listener
After=network.target

[Service]
Type=simple
User=root
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/bin
Environment=TERM=xterm-25color
WorkingDirectory=/root/git/nicholaswilde/homelab/{rel_path}
ExecStart=/usr/bin/webhook -hooks hooks.json -verbose -port 9000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
"""


def scaffold_taskfile_targets(taskfile_content: str, app_name: str) -> str:
    """Inject wh:* tasks into Taskfile.yml content if not already present."""
    if "wh:install:" in taskfile_content:
        return taskfile_content

    wh_tasks = f"""  wh:install:
    desc: Install and start the systemd webhook service
    cmds:
      - cp {app_name}-webhook.service /etc/systemd/system/
      - systemctl daemon-reload
      - systemctl enable --now {app_name}-webhook
      - echo "🚀 Webhook service installed and started!"
  wh:logs:
    desc: View the webhook service logs
    cmds:
      - journalctl -u {app_name}-webhook -f
  wh:status:
    desc: Check the status of the systemd webhook service
    cmds:
      - systemctl status {app_name}-webhook
  wh:test:
    desc: Test the webhook listener locally
    cmds:
      - 'curl -X POST -H "Content-Type: application/json" http://localhost:9000/hooks/update-app'
"""

    # Look for insertion before 'default:' or append under 'tasks:'
    if "\n  default:" in taskfile_content:
        parts = taskfile_content.split("\n  default:", 1)
        return parts[0] + "\n" + wh_tasks + "  default:" + parts[1]
    elif "\ntasks:" in taskfile_content:
        return taskfile_content + "\n" + wh_tasks
    else:
        return taskfile_content + "\n\ntasks:\n" + wh_tasks


def scaffold_webhook_files(
    app_name: str, app_dir: Optional[Path] = None, force: bool = False
) -> bool:
    """Scaffold hooks.json, <app>-webhook.service, and Taskfile targets."""
    target_dir = app_dir or (REPO_ROOT / resolve_app_rel_dir(app_name))
    if not target_dir.exists():
        log_error(f"Target directory {target_dir} does not exist.")
        return False

    hooks_path = target_dir / "hooks.json"
    service_path = target_dir / f"{app_name}-webhook.service"
    taskfile_path = target_dir / "Taskfile.yml"

    # 1. hooks.json
    if hooks_path.exists() and not force:
        log_info(f"hooks.json already exists in {target_dir}. Keeping existing.")
    else:
        hooks_content = generate_hooks_json(app_name)
        hooks_path.write_text(hooks_content, encoding="utf-8")
        log_success(f"Created {hooks_path}")

    # 2. <app>-webhook.service
    if service_path.exists() and not force:
        log_info(f"Service unit already exists in {target_dir}. Keeping existing.")
    else:
        service_content = generate_service_unit(app_name)
        service_path.write_text(service_content, encoding="utf-8")
        log_success(f"Created {service_path}")

    # 3. Taskfile.yml
    if taskfile_path.exists():
        content = taskfile_path.read_text(encoding="utf-8")
        updated = scaffold_taskfile_targets(content, app_name)
        if updated != content:
            taskfile_path.write_text(updated, encoding="utf-8")
            log_success(f"Added webhook tasks (wh:*) to {taskfile_path}")
            # Try running task export if task tool is available
            try:
                subprocess.run(
                    ["task", "-d", str(target_dir), "export"],
                    capture_output=True,
                    check=False,
                )
            except Exception:
                pass
        else:
            log_info(f"Webhook tasks already present in {taskfile_path}")

    return True


def deploy_webhook_service(
    app_name: str, node: Optional[str] = None
) -> bool:
    """Deploy webhook listener inside the target Proxmox LXC container."""
    found = find_lxc_container(app_name, node)
    if not found:
        log_error(f"Could not find LXC container for application '{app_name}'.")
        return False

    pve_node, vmid, ct_name, status = found
    log_info(f"Found container '{ct_name}' (VMID {vmid}) on {pve_node} [status: {status}]")

    if status != "running":
        log_error(f"Container '{ct_name}' (VMID {vmid}) is stopped. Cannot deploy webhook service.")
        return False

    # 1. Check if webhook binary is installed inside container
    log_info(f"Checking if webhook package is installed on {ct_name}...")
    ret, stdout, stderr = run_ssh_command(
        pve_node, ["pct", "exec", str(vmid), "--", "which", "webhook"]
    )
    if ret != 0:
        log_info(f"Installing webhook package via apt inside {ct_name}...")
        install_ret, _, install_err = run_ssh_command(
            pve_node,
            [
                "pct",
                "exec",
                str(vmid),
                "--",
                "bash",
                "-c",
                "apt-get update && apt-get install -y webhook",
            ],
            timeout=60,
        )
        if install_ret != 0:
            log_error(f"Failed to install webhook inside {ct_name}: {install_err.strip()}")
            return False
        log_success("webhook package installed successfully.")
    else:
        log_info(f"webhook binary found at: {stdout.strip()}")

    # 2. Install and enable systemd service unit
    rel_path = resolve_app_rel_dir(app_name)
    service_filename = f"{app_name}-webhook.service"
    remote_repo_dir = f"/root/git/nicholaswilde/homelab/{rel_path}"
    remote_service_file = f"{remote_repo_dir}/{service_filename}"

    # Sync local scaffolded files into container if present
    local_app_dir = REPO_ROOT / rel_path
    run_ssh_command(
        pve_node, ["pct", "exec", str(vmid), "--", "mkdir", "-p", remote_repo_dir]
    )
    for fname in ["hooks.json", "update.sh", service_filename]:
        local_file = local_app_dir / fname
        if local_file.is_file():
            content = local_file.read_text(encoding="utf-8")
            remote_target = f"{remote_repo_dir}/{fname}"
            run_ssh_command(
                pve_node,
                ["pct", "exec", str(vmid), "--", "tee", remote_target],
                input_data=content,
            )
            if fname == "update.sh":
                run_ssh_command(
                    pve_node,
                    ["pct", "exec", str(vmid), "--", "chmod", "+x", remote_target],
                )

    setup_cmd = (
        f"cp {remote_service_file} /etc/systemd/system/ && "
        f"systemctl daemon-reload && "
        f"systemctl enable {app_name}-webhook && "
        f"systemctl restart {app_name}-webhook && "
        f"systemctl is-active {app_name}-webhook"
    )

    log_info(f"Enabling and starting {service_filename} inside container...")
    ret, stdout, stderr = run_ssh_command(
        pve_node, ["pct", "exec", str(vmid), "--", "bash", "-c", setup_cmd]
    )

    if ret != 0 or stdout.strip() != "active":
        log_error(f"Failed to activate webhook service: {stderr.strip() or stdout.strip()}")
        return False

    log_success(f"Webhook listener '{app_name}-webhook' is active and running on port 9000!")
    return True


def trigger_webhook_test(
    app_name: str,
    node: Optional[str] = None,
    ip: Optional[str] = None,
    port: int = 9000,
) -> bool:
    """Send an HTTP POST test trigger to the application's webhook listener."""
    target_ip = ip
    if not target_ip:
        found = find_lxc_container(app_name, node)
        if not found:
            log_error(f"Container '{app_name}' not found to determine IP.")
            return False
        pve_node, vmid, ct_name, _ = found
        target_ip = get_container_ip(pve_node, vmid)

    if not target_ip:
        log_error(f"Could not determine IP address for '{app_name}'.")
        return False

    webhook_url = f"http://{target_ip}:{port}/hooks/update-app"
    log_info(f"Triggering webhook listener at {webhook_url}...")

    try:
        req = urllib.request.Request(
            webhook_url,
            data=b"{}",
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode("utf-8", errors="ignore").strip()
            code = resp.getcode()
            log_success(f"Webhook responded ({code}): {body}")
            return code == 200
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="ignore").strip()
        log_error(f"Webhook returned HTTP {e.code}: {body}")
        return False
    except Exception as e:
        log_error(f"Failed to reach webhook at {webhook_url}: {e}")
        return False


# Alias for backwards compatibility
test_webhook_listener = trigger_webhook_test


def get_changedetection_token(node: str = CD_NODE, vmid: int = CD_CONTAINER_VMID) -> Optional[str]:
    """Retrieve ChangeDetection API access token from environment or remote container."""
    env_token = os.getenv("CHANGEDETECTION_API_KEY")
    if env_token:
        return env_token.strip()

    # Query container directly on Proxmox node
    ret, stdout, stderr = run_ssh_command(
        node,
        [
            "pct",
            "exec",
            str(vmid),
            "--",
            "jq",
            "-r",
            ".settings.application.api_access_token",
            "/opt/changedetection/changedetection.json",
        ],
    )
    if ret == 0 and stdout.strip() and stdout.strip() != "null":
        return stdout.strip()

    return None


def register_cd_watch(
    app_name: str,
    repo: str,
    title: Optional[str] = None,
    node: Optional[str] = None,
    cd_host: str = DEFAULT_CD_HOST,
    token: Optional[str] = None,
    feed_url: Optional[str] = None,
) -> bool:
    """Register or update release/commit watch in ChangeDetection.io pointing to webhook."""
    watch_title = title or f"release-{app_name}"
    atom_url = feed_url or f"https://github.com/{repo.strip()}/releases.atom"

    found = find_lxc_container(app_name, node)
    if not found:
        log_error(f"Could not find container for '{app_name}' to discover IP.")
        return False

    pve_node, vmid, ct_name, _ = found
    target_ip = get_container_ip(pve_node, vmid)
    if not target_ip:
        log_error(f"Could not retrieve IPv4 address for container '{ct_name}'.")
        return False

    notif_url = f"post://{target_ip}:9000/hooks/update-app?method=POST&header=Content-Type:application/json"
    log_info(f"Target Notification URL: {notif_url}")

    api_token = token or get_changedetection_token()
    if not api_token:
        log_error(
            "Could not obtain ChangeDetection API token. "
            "Set CHANGEDETECTION_API_KEY environment variable or verify container 116 on pve04."
        )
        return False

    # 1. Query existing watches to see if watch_title or atom_url already exists
    headers = {"x-api-key": api_token, "Content-Type": "application/json"}
    list_url = f"{cd_host}/api/v1/watch"

    try:
        req = urllib.request.Request(list_url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as resp:
            watches = json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        log_error(f"Failed to query ChangeDetection API at {list_url}: {e}")
        return False

    existing_uuid = None
    for uuid_key, wdata in watches.items():
        if wdata.get("title") == watch_title or wdata.get("url") == atom_url:
            existing_uuid = uuid_key
            break

    if existing_uuid:
        log_info(f"Found existing watch '{watch_title}' (UUID: {existing_uuid}). Updating notification URL...")
        put_url = f"{cd_host}/api/v1/watch/{existing_uuid}"
        payload = json.dumps({"notification_urls": [notif_url]}).encode("utf-8")
        try:
            req = urllib.request.Request(put_url, data=payload, headers=headers, method="PUT")
            with urllib.request.urlopen(req, timeout=10) as resp:
                log_success(f"Updated ChangeDetection watch {existing_uuid} successfully.")
                return True
        except Exception as e:
            log_error(f"Failed to update ChangeDetection watch {existing_uuid}: {e}")
            return False
    else:
        log_info(f"Creating new ChangeDetection watch for '{watch_title}' -> {atom_url}...")
        post_url = f"{cd_host}/api/v1/watch"
        payload = json.dumps(
            {
                "url": atom_url,
                "title": watch_title,
                "notification_urls": [notif_url],
            }
        ).encode("utf-8")
        try:
            req = urllib.request.Request(post_url, data=payload, headers=headers, method="POST")
            with urllib.request.urlopen(req, timeout=10) as resp:
                result = json.loads(resp.read().decode("utf-8"))
                new_uuid = result.get("uuid") or result
                log_success(f"Created ChangeDetection watch '{watch_title}' (UUID: {new_uuid})!")
                return True
        except Exception as e:
            log_error(f"Failed to create ChangeDetection watch: {e}")
            return False


def main() -> int:
    """CLI entrypoint."""
    parser = argparse.ArgumentParser(
        description="LXC Application Webhook & Auto-Update Manager"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # scaffold
    scaffold_p = subparsers.add_parser(
        "scaffold", help="Scaffold hooks.json, service unit, and Taskfile targets locally"
    )
    scaffold_p.add_argument("app", help="Application name (e.g. wallos, bentopdf)")
    scaffold_p.add_argument("--dir", help="Path to app directory (defaults to lxc/<app>)")
    scaffold_p.add_argument(
        "-f", "--force", action="store_true", help="Overwrite existing files"
    )

    # deploy
    deploy_p = subparsers.add_parser(
        "deploy", help="Deploy and enable webhook listener inside remote LXC container"
    )
    deploy_p.add_argument("app", help="Application name")
    deploy_p.add_argument("--node", help="Specific Proxmox node to target (e.g. pve03, pve04)")

    # test
    test_p = subparsers.add_parser(
        "test", help="Send test HTTP POST request to webhook listener"
    )
    test_p.add_argument("app", help="Application name")
    test_p.add_argument("--node", help="Specific Proxmox node")
    test_p.add_argument("--ip", help="Direct container IP override")
    test_p.add_argument("--port", type=int, default=9000, help="Webhook port (default: 9000)")

    # cd-watch
    cd_p = subparsers.add_parser(
        "cd-watch", help="Register/update upstream release watch in ChangeDetection.io"
    )
    cd_p.add_argument("app", help="Application name")
    cd_p.add_argument(
        "--repo", required=True, help="GitHub repository (owner/repo), e.g. wallosapp/wallos"
    )
    cd_p.add_argument("--feed-url", help="Custom feed URL override (e.g. commits/main.atom)")
    cd_p.add_argument("--title", help="Watch title (defaults to release-<app>)")
    cd_p.add_argument("--node", help="Specific Proxmox node for target app")
    cd_p.add_argument("--cd-host", default=DEFAULT_CD_HOST, help="ChangeDetection base URL")
    cd_p.add_argument("--token", help="ChangeDetection API token override")

    args = parser.parse_args()

    if args.command == "scaffold":
        app_dir = Path(args.dir) if args.dir else None
        ok = scaffold_webhook_files(args.app, app_dir, force=args.force)
        return 0 if ok else 1
    elif args.command == "deploy":
        ok = deploy_webhook_service(args.app, node=args.node)
        return 0 if ok else 1
    elif args.command == "test":
        ok = trigger_webhook_test(
            args.app, node=args.node, ip=args.ip, port=args.port
        )
        return 0 if ok else 1
    elif args.command == "cd-watch":
        ok = register_cd_watch(
            args.app,
            repo=args.repo,
            title=args.title,
            node=args.node,
            cd_host=args.cd_host,
            token=args.token,
            feed_url=args.feed_url,
        )
        return 0 if ok else 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
