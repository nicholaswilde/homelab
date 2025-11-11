# Markdown Documentation Guidelines for Gemini

**Context:** This directory contains all project documentation in Markdown format.

**Specific Instructions for Markdown Files:**
- Use clear and descriptive headings (H1 for main topic, H2 for sub-sections).
- Employ bullet points and numbered lists for readability.
- Use backticks (`` ` ``) for inline code and triple backticks (```) for code blocks, specifying the language (e.g., ```bash`, ```python`).
- Keep paragraphs concise.
- Link to relevant files or sections using relative paths where appropriate.
- Ensure a consistent tone and voice (e.g., formal, informal, instructional).
- Favor simple Markdown over complex HTML embeds unless absolutely necessary.
- All documentation is written in Markdown and generated using the MkDocs with the Material theme.
- Adhere strictly to the Zensical syntax extensions for features like admonitions, content tabs, and icons.
- Ensure all new pages are added to the `nav` section of the `mkdocs.yml` file to appear in the site navigation.
- All internal links must be relative and point to other `.md` files within the `docs/` directory.
- Do not use first-person nor third-person perspective in the document.

## Markdown Style Guide:

- **Headings:** Use ATX-style headings (`#`, `##`, `###`, etc.). The main page title is always H1 (`#`).
- All Headings should start with emoji using zensical compatible shortcode.
- **Admonitions:** Use admonitions to highlight important information.
- `!!! note` for general information.
- `!!! code` for computer code and commands.
- `!!! abstract` for referencing files.
- `??? abstract` for long files that need to be collapsed.
- `!!! tip` for helpful advice.
- `!!! warning` for critical warnings or potential issues.
- `!!! danger` for severe risks.
- **Code Blocks:** Always specify the language for syntax highlighting (e.g., ` ```python`). For shell commands, use `shell` or `bash`. Use `ini` for `.env` files.
- **Lists:** Use hyphens (`-`) for unordered lists and numbers (`1.`) for ordered lists.
- **Icons & Emojis:** Use Material Design icons and emojis where appropriate to improve visual communication, e.g., `:material-check-circle:` for success.
- **Icons & Emojis:** Use the short codes for emoji instead of the emoji itself.
- Use 2 spaces for indentation.
- List items that are links should be inclosed with < and >.
- Formatting shall be compatible with markdownlint.
- All hyperlinks should reference a number and the numbers should be at the bottom of the document (e.g. `[tool name][1] and `[1]: <url>` )

## Sections:

- All sections should have emoji in front of the section name.
- **References:** Always end a page with a References section.
- References section starts with the :link: emoji.
- References section has a list of relevant links.
- **Config:** Create a config section
- **Installation:** Create an installation section.
- This section should show instructions for both amd64 and arm64 architectures.
- **Usage:** Create a usage section
- **Upgrade:** Create an upgrade section.

## File Naming Conventions:

- **Applications:** Files in `docs/apps/` should be named `app-name.md` (e.g., `adguard.md`).
- **Tools:** Files in `docs/tools/` should be named `tool-name.md` (e.g., `sops.md`).
- **Hardware:** Files in `docs/hardware/` should be named `hardware-name.md` (e.g., `rpi5.md`).

## Content Structure:

All markdown files should follow a consistent structure to ensure readability and maintainability. The recommended sections are:

-   **Front Matter:** (Optional) Includes `tags` for categorization.
-   **Title:** H1 heading with an appropriate emoji and the name of the application, tool, or hardware.
-   **Description:** A brief overview of the item, often including a hyperlink to its official source.
-   **Installation:** Instructions on how to install the item, typically with code blocks for different architectures or methods (e.g., `amd64`, `arm64`, `Docker`, `Task`).
-   **Config:** Details on how to configure the item, including relevant file paths and example configurations.
-   **Usage:** Instructions and examples on how to use the item.
-   **Upgrade:** Instructions on how to upgrade the item, often with `Task` or manual commands.
-   **Troubleshooting:** (Optional) Common issues and their solutions.
-   **References:** A list of relevant external links, with numbered references at the bottom of the document.

## docs/apps/

This directory contains documentation for applications installed in the homelab. Each application's markdown file should provide comprehensive instructions for installation, configuration, usage, and upgrading, adhering to the general content structure.

## docs/tools/

This directory contains documentation for various tools used in the homelab. Each tool's markdown file should detail its installation, configuration, and usage, following the general content structure.

## docs/hardware/

This directory contains documentation for hardware components in the homelab. Each hardware's markdown file should include its specifications, configuration details, and any specific setup or usage instructions, following the general content structure.

## Regarding Dependencies:

- The primary dependency is zensical.
- The project also uses the pymdown-extensions for advanced formatting.
- Mermaid is an acceptable plugin.
- Do not introduce new MkDocs plugins without prior discussion and approval.

## Example Script Structure:
---
tags:
  - relevant-tags
---
# :emoji: Name of application or tool

Description of application or tool. The name of the tool should be a hyperlink to the original source.

## :hammer_and_wrench: Installation

Instructions on how to install the application or tool.

!!! code ""

    === "amd64"
    
        ```shell
        code to install the application or tool
        ```

    === "arm64"
        
        ```shell
        code to install the application or tool
        ```
            
## :gear: Config

Instructions on how to configure the application or tool.

!!! abstract "homelab/path/config/file"

    ```yaml
    example of yaml config file
    ```

## :pencil: Usage

Instructions on how to use the application or tool.

## :rocket: Upgrade

Code to upgrade the application or tool.

!!! code ""

    === "Task"
    
        ```shell
        task update
        ```
    === "Manual"

        ```shell
        command to update application or tool
        ```

## :link: References

- <url 1>
- <url 2>

[1]: <url>
