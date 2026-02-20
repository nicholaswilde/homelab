# Spec: /doc new command

## :dart: Goal
Automate the creation of new documentation files using existing templates (`docs/.template-docker.md.j2`, etc.) to ensure consistency with the Zensical style guide.

## :gear: Requirements
- Accepts a document name and category (e.g., `apps`, `tools`, `hardware`).
- Uses Jinja2 templates from `docs/`.
- Prompts for tags, description, and relative links.
- Automatically registers the new file in the MkDocs navigation.
