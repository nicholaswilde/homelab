#!/usr/bin/env python3
import os
import requests
import sys
from ruamel.yaml import YAML
from packaging import version
from tabulate import tabulate

yaml = YAML(typ='safe')

def scan_compose_files(root_dir):
    """Scan root_dir recursively for compose.yaml or docker-compose.yml files."""
    compose_files = []
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file in ['compose.yaml', 'docker-compose.yml']:
                compose_files.append(os.path.join(root, file))
    return compose_files

def extract_images(file_path):
    """Extract unique image tags from a compose file."""
    images = set()
    try:
        with open(file_path, 'r') as f:
            data = yaml.load(f)
            if not data or 'services' not in data:
                return list(images)
            
            for service in data['services'].values():
                image = service.get('image')
                if image:
                    images.add(image)
    except Exception as e:
        print(f"Error parsing {file_path}: {e}")
    return list(images)

def get_registry(image_name):
    """Identify the registry for a given image name."""
    if image_name.startswith('ghcr.io/'):
        return 'ghcr'
    if '.' in image_name.split('/')[0] and '/' in image_name:
        return 'unknown'
    return 'dockerhub'

def get_latest_tag(image_name):
    """Query the registry for the latest tag of an image."""
    registry = get_registry(image_name)
    
    # Strip registry prefix if present
    repo = image_name
    if registry == 'ghcr':
        repo = repo.replace('ghcr.io/', '')
    elif registry == 'dockerhub':
        if '/' not in repo:
            repo = f"library/{repo}"
    
    # Strip current tag if present
    if ':' in repo:
        repo = repo.split(':')[0]

    if registry == 'dockerhub':
        return _get_latest_tags_registry(repo, "https://auth.docker.io/token?service=registry.docker.io&scope=repository:{repo}:pull", "https://registry-1.docker.io/v2/{repo}/tags/list")
    elif registry == 'ghcr':
        return _get_latest_tags_registry(repo, "https://ghcr.io/token?service=ghcr.io&scope=repository:{repo}:pull", "https://ghcr.io/v2/{repo}/tags/list")
    return None

def _get_latest_tags_registry(repo, token_url_fmt, tags_url_fmt):
    try:
        # Get token
        token_url = token_url_fmt.format(repo=repo)
        r = requests.get(token_url, timeout=10)
        if r.status_code != 200:
            return None
        token = r.json().get('token')
        
        # Get tags
        tags_url = tags_url_fmt.format(repo=repo)
        headers = {'Authorization': f'Bearer {token}'}
        r = requests.get(tags_url, headers=headers, timeout=10)
        if r.status_code != 200:
            return None
        tags = r.json().get('tags', [])
        
        # Filter for semantic versions
        valid_versions = []
        for t in tags:
            try:
                # Basic check: tag should contain a digit
                if any(c.isdigit() for c in t):
                    parse_version_safe(t)
                    valid_versions.append(t)
            except (version.InvalidVersion, ValueError):
                continue
        
        if valid_versions:
            # Sort by parsed versions but return original tags
            return sorted(valid_versions, key=lambda x: parse_version_safe(x), reverse=True)[0]
    except Exception:
        pass
    return None

def parse_version_safe(v_string):
    """Attempt to parse a version string, handling common prefixes and suffixes."""
    clean = v_string.lstrip('v')
    # Try direct parse
    try:
        return version.parse(clean)
    except version.InvalidVersion:
        # Try parsing just the prefix before any '-' or '_'
        prefix = clean.split('-')[0].split('_')[0]
        try:
            return version.parse(prefix)
        except version.InvalidVersion:
            raise

def audit_image(image_full_name):
    """Compare current tag with latest available tag."""
    if ':' in image_full_name:
        name_part, current_tag = image_full_name.split(':', 1)
    else:
        name_part = image_full_name
        current_tag = 'latest'
    
    # get_latest_tag expects image name WITHOUT registry prefix or tag
    latest_tag = get_latest_tag(name_part)
    
    status = "UP TO DATE"
    if not latest_tag:
        status = "UNKNOWN"
    elif current_tag == 'latest':
        status = "OUTDATED (latest)"
    else:
        try:
            curr_v = parse_version_safe(current_tag)
            late_v = parse_version_safe(latest_tag)
            if late_v > curr_v:
                status = "OUTDATED"
        except (version.InvalidVersion, ValueError):
            status = "UNKNOWN (parse error)"
            
    return current_tag, latest_tag, status

def main():
    root = 'docker'
    if len(sys.argv) > 1:
        root = sys.argv[1]
        
    files = scan_compose_files(root)
    results = []
    
    for file in files:
        images = extract_images(file)
        for image in images:
            current, latest, status = audit_image(image)
            results.append([file, image, current, latest or "N/A", status])

    headers = ["File", "Image", "Current", "Latest", "Status"]
    print(tabulate(results, headers=headers, tablefmt="fancy_grid"))

if __name__ == '__main__':
    main()
