import os
import glob
import re

def get_markdown_title(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip().startswith('# '):
                title = re.sub(r':([a-zA-Z0-9_-]+):', '', line.strip('# ')).strip()
                return title
    return os.path.basename(filepath).replace('.md', '').replace('-', ' ').title()

def generate_nav_section_content(docs_base_path, base_path):
    section_items = []
    full_path = os.path.join(docs_base_path, base_path)
    for md_file in sorted(glob.glob(os.path.join(full_path, '*.md'))):
        relative_path = os.path.relpath(md_file, docs_base_path).replace('\\', '/')
        title = get_markdown_title(md_file)
        section_items.append(f'  {{ "{title}" = "{relative_path}" }},')
    return section_items

def update_zensical_nav(zensical_toml_path, docs_base_path):
    with open(zensical_toml_path, 'r', encoding='utf-8') as f:
        content = f.read()

    sections = [
        ('Apps', 'apps'),
        ('Hardware', 'hardware'),
        ('Tools', 'tools'),
        ('Operating Systems', 'os')
    ]

    for label, folder in sections:
        new_items = generate_nav_section_content(docs_base_path, folder)
        if not new_items:
            continue
            
        # Regex to find the section
        # Format:
        # [[project.nav]]
        # "Label" = [
        #   ...
        # ]
        pattern = rf'(\[\[project\.nav\]\]\n"?{label}"?\s*=\s*\[)(.*?)(\n\])'
        
        # Replace the content within the brackets
        new_content_str = '\n' + '\n'.join(new_items)
        content = re.sub(pattern, rf'\1{new_content_str}\3', content, flags=re.DOTALL)

    with open(zensical_toml_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    zensical_toml_path = os.path.join(project_root, 'zensical.toml')
    docs_base_path = os.path.join(project_root, 'docs')
    update_zensical_nav(zensical_toml_path, docs_base_path)
    print("zensical.toml navigation updated successfully.")
