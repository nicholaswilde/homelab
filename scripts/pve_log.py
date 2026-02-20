#!/usr/bin/env python3
import argparse
import json
import sys
from datetime import datetime

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
RESET = "\033[0m"

def log_info(msg):
    print(f"{BLUE}INFO{RESET}: {msg}")

def log_error(msg):
    print(f"{RED}ERRO{RESET}: {msg}")

def format_log_entry(entry):
    time_str = datetime.fromtimestamp(entry.get('time', 0)).strftime('%Y-%m-%d %H:%M:%S')
    node = entry.get('node', 'unknown')
    tag = entry.get('tag', 'unknown')
    msg = entry.get('msg', '')
    pri = entry.get('pri', 6)
    
    color = RESET
    level = "INFO"
    
    if pri <= 3: # Error
        color = RED
        level = "ERRO"
    elif pri <= 5: # Warning
        color = YELLOW
        level = "WARN"
        
    return f"{color}{level}{RESET} [{time_str}] {node} ({tag}): {msg}"

def summarize_logs(logs, node_filter=None, service_filter=None, limit=20):
    filtered_logs = []
    
    for entry in logs:
        if node_filter and entry.get('node') != node_filter:
            continue
        if service_filter:
            tag = entry.get('tag', '').lower()
            msg = entry.get('msg', '').lower()
            if service_filter.lower() not in tag and service_filter.lower() not in msg:
                continue
        filtered_logs.append(entry)
        
    # Sort by time ascending
    filtered_logs.sort(key=lambda x: x.get('time', 0))
    
    # Apply limit (last N entries)
    final_logs = filtered_logs[-limit:]
    
    if not final_logs:
        print(f"{YELLOW}No logs found matching filters.{RESET}")
        return

    print("\n" + "="*60)
    print(f"PVE LOG SUMMARY (Node: {node_filter or 'All'}, Service: {service_filter or 'All'})")
    print("="*60)
    
    for entry in final_logs:
        print(format_log_entry(entry))
        
    print("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(description="Summarize PVE logs from JSON.")
    parser.add_argument("file", help="Path to JSON file containing logs or '-' for stdin")
    parser.add_argument("--node", help="Filter by node")
    parser.add_argument("--service", help="Filter by service name (tag or message)")
    parser.add_argument("--limit", type=int, default=20, help="Number of entries to show")

    args = parser.parse_args()

    try:
        if args.file == '-':
            logs = json.load(sys.stdin)
        else:
            with open(args.file, 'r') as f:
                logs = json.load(f)
    except Exception as e:
        log_error(f"Failed to read logs: {e}")
        sys.exit(1)

    summarize_logs(logs, node_filter=args.node, service_filter=args.service, limit=args.limit)

if __name__ == "__main__":
    main()
