#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import urllib.request
import urllib.error
import time

def expand_vars(val):
    if isinstance(val, str):
        # Manually expand ${HOME} or $HOME to support cross-platform/shell-less execution
        val = val.replace("${HOME}", os.environ.get("HOME", ""))
        val = val.replace("$HOME", os.environ.get("HOME", ""))
        return os.path.expandvars(val)
    elif isinstance(val, list):
        return [expand_vars(v) for v in val]
    elif isinstance(val, dict):
        return {k: expand_vars(v) for k, v in val.items()}
    return val

def test_http_server(name, config):
    url = config.get("httpUrl")
    headers = config.get("headers", {})
    
    print(f"[*] Testing HTTP/SSE MCP Server '{name}' at {url}...")
    
    # 1. Try pure HTTP POST first (useful for Home Assistant's built-in MCP server)
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {
                "name": "mcp-test-client",
                "version": "1.0.0"
            },
            "implementation": {
                "name": "mcp-test-client",
                "version": "1.0.0"
            }
        }
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
            **headers
        },
        method="POST"
    )
    
    start_time = time.time()
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            res_body = response.read().decode("utf-8")
            elapsed = time.time() - start_time
            res_json = json.loads(res_body)
            
            if "error" in res_json:
                print(f"[\u274c] HTTP Server '{name}' returned JSON-RPC error: {res_json['error']}")
                return False, res_json["error"]
            
            result = res_json.get("result", {})
            server_info = result.get("serverInfo", {})
            server_name = server_info.get("name", "Unknown")
            server_version = server_info.get("version", "Unknown")
            print(f"[\u2705] HTTP Server '{name}' connected successfully! ({elapsed:.2f}s)")
            print(f"    Name: {server_name}")
            print(f"    Version: {server_version}")
            return True, result
    except Exception as post_err:
        print(f"[*] Pure HTTP POST failed ({post_err}). Retrying with SSE Transport...")
        
    # 2. Establish SSE stream (standard MCP SSE transport fallback)
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "text/event-stream",
            **headers
        },
        method="GET"
    )
    
    try:
        response = urllib.request.urlopen(req, timeout=10)
    except Exception as e:
        print(f"[\u274c] SSE connection to '{name}' failed: {e}")
        return False, f"SSE connection failed: {e}"
        
    post_url = None
    try:
        # Read SSE lines until we find the endpoint event
        current_event = None
        start_wait = time.time()
        
        while time.time() - start_wait < 5.0:
            line_bytes = response.readline()
            if not line_bytes:
                break
            line = line_bytes.decode("utf-8").strip()
            if not line:
                continue
                
            if line.startswith("event:"):
                current_event = line[6:].strip()
            elif line.startswith("data:"):
                data_val = line[5:].strip()
                if current_event == "endpoint":
                    post_url = data_val
                    # Resolve relative URL if necessary
                    if not post_url.startswith("http"):
                        from urllib.parse import urljoin
                        post_url = urljoin(url, post_url)
                    break
                    
        if not post_url:
            response.close()
            print(f"[\u274c] HTTP/SSE Server '{name}' did not send endpoint event.")
            return False, "No endpoint event received in SSE stream"
            
        print(f"[*] Found POST endpoint: {post_url}")
        
        # Send initialize POST request to post_url
        post_req = urllib.request.Request(
            post_url,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                **headers
            },
            method="POST"
        )
        
        # Send the POST request
        with urllib.request.urlopen(post_req, timeout=5) as post_res:
            pass
            
        # Read SSE stream to find the JSON-RPC response message
        res_json = None
        current_event = None
        start_wait = time.time()
        
        while time.time() - start_wait < 5.0:
            line_bytes = response.readline()
            if not line_bytes:
                break
            line = line_bytes.decode("utf-8").strip()
            if not line:
                continue
                
            if line.startswith("event:"):
                current_event = line[6:].strip()
            elif line.startswith("data:"):
                data_val = line[5:].strip()
                if current_event == "message":
                    # Parse the message
                    msg = json.loads(data_val)
                    if msg.get("id") == 1:
                        res_json = msg
                        break
                        
        response.close()
        
        if not res_json:
            print(f"[\u274c] HTTP/SSE Server '{name}' did not send initialize response over SSE.")
            return False, "No initialize response received in SSE stream"
            
        if "error" in res_json:
            print(f"[\u274c] HTTP/SSE Server '{name}' returned JSON-RPC error: {res_json['error']}")
            return False, res_json["error"]
            
        result = res_json.get("result", {})
        server_info = result.get("serverInfo", {})
        server_name = server_info.get("name", "Unknown")
        server_version = server_info.get("version", "Unknown")
        print(f"[\u2705] HTTP/SSE Server '{name}' connected successfully!")
        print(f"    Name: {server_name}")
        print(f"    Version: {server_version}")
        return True, result
        
    except Exception as e:
        response.close()
        print(f"[\u274c] HTTP/SSE Server '{name}' failed during communication: {e}")
        return False, str(e)

def test_stdio_server(name, config):
    command = config.get("command")
    args = config.get("args", [])
    env = config.get("env", {})
    
    # Merge current env and server env, expanding variables
    full_env = os.environ.copy()
    full_env["RUST_LOG"] = "off"
    for k, v in env.items():
        full_env[k] = expand_vars(str(v))
        
    expanded_command = expand_vars(command)
    expanded_args = [expand_vars(a) for a in args]
    
    # Resolve absolute path of command if it is not absolute and not in PATH
    print(f"[*] Testing Stdio MCP Server '{name}'...")
    print(f"    Command: {expanded_command} {' '.join(expanded_args)}")
    
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {
                "name": "mcp-test-client",
                "version": "1.0.0"
            },
            "implementation": {
                "name": "mcp-test-client",
                "version": "1.0.0"
            }
        }
    }
    
    start_time = time.time()
    try:
        proc = subprocess.Popen(
            [expanded_command] + expanded_args,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=full_env,
            text=True,
            bufsize=1
        )
    except FileNotFoundError as e:
        print(f"[\u274c] Stdio Server '{name}' executable not found: {expanded_command}")
        return False, f"Executable not found: {e}"
    except Exception as e:
        print(f"[\u274c] Stdio Server '{name}' failed to start: {e}")
        return False, str(e)
        
    try:
        # Send initialize payload
        proc.stdin.write(json.dumps(payload) + "\n")
        proc.stdin.flush()
        
        # Read stdout line by line (expecting single line json response)
        # We will wait up to 5 seconds for a response
        res_line = None
        start_wait = time.time()
        while time.time() - start_wait < 5.0:
            # Check if process died
            if proc.poll() is not None:
                err_out = proc.stderr.read()
                print(f"[\u274c] Stdio Server '{name}' exited early with code {proc.returncode}")
                if err_out:
                    print(f"    Stderr output: {err_out.strip()}")
                return False, f"Exited with code {proc.returncode}: {err_out.strip()}"
                
            # Non-blocking check or simple readline (readline will block but we set a short timeout if we can,
            # or we rely on the server responding quickly). Since stdio MCP servers are interactive,
            # we read a line.
            res_line = proc.stdout.readline()
            if res_line:
                break
            time.sleep(0.1)
            
        if not res_line:
            proc.kill()
            err_out = proc.stderr.read()
            print(f"[\u274c] Stdio Server '{name}' timed out waiting for response.")
            if err_out:
                print(f"    Stderr output: {err_out.strip()}")
            return False, "Timeout waiting for initialize response"
            
        elapsed = time.time() - start_time
        try:
            res_json = json.loads(res_line)
        except json.JSONDecodeError as je:
            proc.terminate()
            time.sleep(0.2)
            proc.kill()
            err_out = proc.stderr.read()
            print(f"[\u274c] Stdio Server '{name}' returned invalid JSON: {res_line.strip()}")
            if err_out:
                print(f"    Stderr output: {err_out.strip()}")
            return False, f"Invalid JSON response: {res_line.strip()} | Stderr: {err_out.strip()}"
        
        # Shutdown cleanly
        shutdown_payload = {"jsonrpc": "2.0", "id": 2, "method": "shutdown", "params": {}}
        proc.stdin.write(json.dumps(shutdown_payload) + "\n")
        proc.stdin.flush()
        
        # Send exit
        exit_payload = {"jsonrpc": "2.0", "method": "notifications/exit", "params": {}}
        proc.stdin.write(json.dumps(exit_payload) + "\n")
        proc.stdin.flush()
        
        proc.terminate()
        
        if "error" in res_json:
            print(f"[\u274c] Stdio Server '{name}' returned JSON-RPC error: {res_json['error']}")
            return False, res_json["error"]
            
        result = res_json.get("result", {})
        server_info = result.get("serverInfo", {})
        server_name = server_info.get("name", "Unknown")
        server_version = server_info.get("version", "Unknown")
        print(f"[\u2705] Stdio Server '{name}' connected successfully! ({elapsed:.2f}s)")
        print(f"    Name: {server_name}")
        print(f"    Version: {server_version}")
        return True, result
        
    except Exception as e:
        proc.kill()
        print(f"[\u274c] Stdio Server '{name}' failed during communication: {e}")
        return False, str(e)

def main():
    workspace_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    settings_path = os.path.join(workspace_dir, ".antigravity", "settings.json")
    
    if not os.path.exists(settings_path):
        print(f"[-] settings.json not found at {settings_path}")
        sys.exit(1)
        
    print(f"[*] Loading MCP server settings from: {settings_path}")
    with open(settings_path, "r") as f:
        settings = json.load(f)
        
    servers = settings.get("mcpServers", {})
    if not servers:
        print("[-] No MCP servers defined in settings.json")
        sys.exit(0)
        
    results = {}
    print(f"[*] Found {len(servers)} configured MCP servers. Starting connection tests...\n")
    
    for name, config in servers.items():
        if "httpUrl" in config:
            success, detail = test_http_server(name, config)
        elif "command" in config:
            success, detail = test_stdio_server(name, config)
        else:
            print(f"[-] Invalid configuration for server '{name}': no command or httpUrl specified.")
            success, detail = False, "Missing command or httpUrl"
            
        results[name] = {"success": success, "detail": detail}
        print("-" * 60)
        
    print("\n" + "=" * 60)
    print("MCP SERVER TEST SUMMARY")
    print("=" * 60)
    
    all_ok = True
    for name, res in results.items():
        status_str = "[\u2705] OK    " if res["success"] else "[\u274c] FAILED"
        if not res["success"]:
            all_ok = False
            
        detail_str = ""
        if res["success"]:
            info = res["detail"].get("serverInfo", {})
            detail_str = f"{info.get('name', 'Unknown')} v{info.get('version', 'Unknown')}"
        else:
            detail_str = str(res["detail"])
            
        print(f"{status_str} | {name:<18} | {detail_str}")
        
    print("=" * 60)
    if all_ok:
        print("All configured MCP servers are functioning correctly!")
        sys.exit(0)
    else:
        print("Some MCP servers failed. Please check the logs and configurations above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
