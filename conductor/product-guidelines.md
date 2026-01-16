# Product Guidelines

## Prose Style
- **Primary:** Instructional and Direct. Documentation should guide users clearly through installation, configuration, and maintenance steps.
- **Secondary:** Narrative elements can be used in "About" or "Vision" sections to explain architectural choices, but the core value is usability.

## Formatting & Structure
- **Consistency:** Follow a strict structure for application documentation (e.g., Installation, Config, Usage, Upgrade, References).
- **Admonitions:** Use admonitions (Note, Warning, Tip) effectively to highlight critical information.
- **Code Blocks:** Ensure all code blocks have language identifiers for syntax highlighting.
- **Icons & Emojis:** Use emojis and icons (via Zensical/Material) to create a visual and engaging hierarchy.

## Visual Identity
- **Diagrams:** Use Mermaid diagrams to visualize network flows, container interactions, and system architecture.
- **Theme:** Use the Material for MkDocs theme with the "Catppuccin Mocha" color palette for consistency with scripts and terminal outputs.

## Development & Maintenance
- **Idempotency:** Scripts and configurations should be idempotent where possible.
- **Safety:** Always verify dependencies and use "dry run" or confirmation steps for destructive actions.
- **Version Control:** Commit messages should follow conventional commits.
