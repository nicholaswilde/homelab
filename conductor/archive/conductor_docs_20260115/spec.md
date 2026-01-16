# Specification: Conductor Documentation

## Overview
This track involves creating a comprehensive documentation page for **Google Conductor** within the project's documentation site. It will guide users and agents through the installation, setup, and usage of Conductor, explaining its spec-driven methodology and how it manages project context.

## Goals
1.  **Educate:** Provide a clear explanation of the Conductor methodology (Spec-driven development).
2.  **Guide:** Offer step-by-step instructions for installing and setting up Conductor in a repository.
3.  **Instruct:** Detail the core commands and workflows for creating and implementing tracks.
4.  **Document Context:** Explain the purpose and structure of the `conductor/` directory and its key files.

## Functional Requirements
- Create `docs/tools/conductor.md` following the project's documentation style guide.
- Include the following sections:
    - **Methodology:** Overview of spec-driven development.
    - **Installation:** Instructions for adding the Conductor extension to the Gemini CLI.
    - **Setup:** Details on the `/conductor:setup` command and initialization process.
    - **Project Context:** Explanation of `product.md`, `tech-stack.md`, `workflow.md`, and `index.md`.
    - **Usage:** Practical guide for `/conductor:newTrack` and `/conductor:implement`.
    - **Configuration:** How to customize workflows and code style guides.
- Ensure the page is added to the MkDocs navigation (if not automatically generated).

## Non-Functional Requirements
- **Consistency:** Use standard emojis, admonitions, and formatting as defined in `conductor/workflow.md`.
- **Clarity:** Use instructional and direct prose.

## Acceptance Criteria
- `docs/tools/conductor.md` exists and is correctly formatted.
- All specified sections (Installation, Setup, Usage, etc.) are present and accurate.
- Internal links to other Conductor files (if any) are valid.
- `task lint` passes for the new documentation file.

## Out of Scope
- Documenting the internal implementation details of the Conductor extension itself.
- Updating documentation for other tools.
