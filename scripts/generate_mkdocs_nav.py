import yaml
import os
import glob
import re

def get_markdown_title(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip().startswith('# '):
                # Remove emoji shortcodes and then strip whitespace
                title = re.sub(r':([a-zA-Z0-9_-]+):', '', line.strip('# ')).strip()
                return title
    return os.path.basename(filepath).replace('.md', '').replace('-', ' ').title()

def generate_nav_section_content(docs_base_path, base_path):
    section_items = []
    full_path = os.path.join(docs_base_path, base_path)
    for md_file in sorted(glob.glob(os.path.join(full_path, '*.md'))):
        relative_path = os.path.relpath(md_file, docs_base_path).replace('\\', '/') # Ensure forward slashes
        title = get_markdown_title(md_file)
        section_items.append(f'  - {title}: {relative_path}')
    return '\n'.join(section_items)

def update_mkdocs_nav_string(mkdocs_yml_path, docs_base_path):
    with open(mkdocs_yml_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the 'nav:' section
    nav_start_match = re.search(r'^nav:\s*\n', content, re.MULTILINE)
    if not nav_start_match:
        print("Error: 'nav:' section not found in mkdocs.yml")
        return

    nav_start_index = nav_start_match.end()

    # Find the end of the 'nav:' section (before the next top-level key or end of file)
    nav_end_index = len(content)
    top_level_keys = [
        'site_name', 'site_description', 'site_author', 'site_url', 'copyright',
        'dev_addr', 'repo_name', 'repo_url', 'edit_uri', 'exclude',
        'extra_css', 'extra', 'theme', 'plugins', 'markdown_extensions',
    ]

    # Sort keys by length in descending order to avoid partial matches
    top_level_keys.sort(key=len, reverse=True)

    for key in top_level_keys:
        # Look for a top-level key that starts at the beginning of a line after 'nav:'
        key_match = re.search(r'^\s*' + re.escape(key) + r':', content[nav_start_index:], re.MULTILINE)
        if key_match:
            # The end of the nav section is the start of the next top-level key
            nav_end_index = nav_start_index + key_match.start()
            break

    # Extract the static part of the nav (Home, About, Travel, Reference)
    current_nav_content = content[nav_start_index:nav_end_index]
    static_nav_lines = []
    dynamic_sections_found = False
    for line in current_nav_content.splitlines():
        stripped_line = line.strip()
        if stripped_line.startswith(('Apps:', 'Hardware:', 'Tools:')):
            dynamic_sections_found = True
            continue # Skip existing dynamic sections
        if not dynamic_sections_found:
            static_nav_lines.append(line)

    # Generate new dynamic sections
    apps_content = generate_nav_section_content(docs_base_path, 'apps')
    hardware_content = generate_nav_section_content(docs_base_path, 'hardware')
    tools_content = generate_nav_section_content(docs_base_path, 'tools')

    # Construct the new nav section
    new_dynamic_nav_lines = []
    if apps_content:
        new_dynamic_nav_lines.append('  - Apps:')
        new_dynamic_nav_lines.extend([f'    {line}' for line in apps_content.splitlines()])
    if hardware_content:
        new_dynamic_nav_lines.append('  - Hardware:')
        new_dynamic_nav_lines.extend([f'    {line}' for line in hardware_content.splitlines()])
    if tools_content:
        new_dynamic_nav_lines.append('  - Tools:')
        new_dynamic_nav_lines.extend([f'    {line}' for line in tools_content.splitlines()])

    # Combine static and new dynamic nav sections
    # Find the insertion point for dynamic sections (e.g., after 'About:')
    combined_nav_lines = []
    inserted_dynamic = False
    for line in static_nav_lines:
        combined_nav_lines.append(line)
        if not inserted_dynamic and line.strip().startswith('About:'):
            combined_nav_lines.extend(new_dynamic_nav_lines)
            inserted_dynamic = True
    
    if not inserted_dynamic:
        combined_nav_lines.extend(new_dynamic_nav_lines)

    new_nav_section = '\n'.join(combined_nav_lines)

    # Replace the old nav section with the new one
    new_content = content[:nav_start_index] + new_nav_section + content[nav_end_index:]

    with open(mkdocs_yml_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    mkdocs_yml_path = os.path.join(project_root, 'mkdocs.yml')
    docs_base_path = os.path.join(project_root, 'docs')
    update_mkdocs_nav_string(mkdocs_yml_path, docs_base_path)
    print("mkdocs.yml navigation updated successfully.")