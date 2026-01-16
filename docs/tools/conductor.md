# :material-source-branch: Google Conductor

[Google Conductor][1] is a spec-driven development framework designed to organize and automate software projects using AI agents. It prioritizes clarity, traceability, and strict adherence to project-specific conventions.

## :brain: Methodology

Conductor follows a **Spec-Driven Development** methodology. This approach ensures that every change to the project is grounded in a clearly defined specification and implemented according to a structured plan.

### Core Concepts

- **Project Context:** A centralized directory (`conductor/`) containing the project's vision, technology stack, and workflows. This serves as the "source of truth" for both human developers and AI agents.
- **Tracks:** High-level units of work (features, bug fixes, or chores). Each track is a self-contained module with its own specification, plan, and metadata.
- **Phased Implementation:** Tracks are broken down into logical phases. Each phase concludes with a verification step and a Git checkpoint, ensuring incremental and validated progress.
- **Quality Gates:** Strict criteria that must be met before any task is considered complete, including test coverage, linting, and manual verification.

---

## :hammer_and_wrench: Installation

To install the Google Conductor extension, use the `extension:add` command within the Gemini CLI:

!!! code ""

    ```shell
    gemini extension:add google/conductor
    ```

Once added, you can verify the installation by checking the available commands:

!!! code ""

    ```shell
    gemini --help | grep conductor
    ```

## :gear: Setup

To initialize Conductor in a repository, run the `/conductor:setup` command. This interactive process guides you through defining the product vision, selecting a tech stack, and configuring workflows.

!!! code ""

    ```shell
    /conductor:setup
    ```

### Initialization Steps

1.  **Project Discovery:** Analyzes the directory to determine project maturity (Greenfield vs. Brownfield).
2.  **Product Definition:** Collaboratively creates `product.md`.
3.  **Guideline Generation:** Creates `product-guidelines.md` for persona and boundaries.
4.  **Tech Stack Selection:** Defines the core technologies in `tech-stack.md`.
5.  **Workflow Customization:** Sets up the task lifecycle and quality gates in `workflow.md`.
6.  **Scaffolding:** Creates the `conductor/` directory and index files.

### Key Outputs

After setup, you will have a `conductor/` directory structured as follows:

!!! abstract "conductor/"

    ```text
    conductor/
    ├── code_styleguides/   # Language-specific style guides
    ├── index.md            # Project context index
    ├── product-guidelines.md # Persona and boundaries
    ├── product.md          # Vision and goals
    ├── tech-stack.md       # Core technologies
    ├── tracks.md           # Registry of all work tracks
    ├── tracks/             # Implementation plans for each track
    └── workflow.md         # Operational procedures
    ```

## :open_file_folder: Project Context

Conductor stores the project's metadata and implementation strategies in the `conductor/` directory. These files are used by AI agents to maintain a consistent state and adhere to project standards.

### Key Files

- **`product.md`**: Defines the project's vision, target users, and core goals.
- **`tech-stack.md`**: Lists the primary technologies, frameworks, and tools used in the project.
- **`workflow.md`**: Outlines the development procedures, task lifecycles, and quality gates.
- **`product-guidelines.md`**: Specifies the AI agent persona, boundaries (Always/Ask/Never), and documentation style.
- **`tracks.md`**: A registry of all major units of work (tracks) and their current status.
- **`index.md`**: Serves as the project context index, linking all relevant Conductor files.

## :pencil: Usage

Conductor uses "Tracks" to organize work. A track is a high-level unit of work, such as a new feature or a bug fix.

### Creating a New Track

To start a new task, use the `/conductor:newTrack` command. You can provide a brief description as an argument.

!!! code ""

    ```shell
    /conductor:newTrack "Add user authentication"
    ```

Conductor will guide you through an interactive specification and planning phase, resulting in a new directory under `conductor/tracks/` containing `spec.md` and `plan.md`.

### Implementing a Track

To begin working on an existing track, use the `/conductor:implement` command.

!!! code ""

    ```shell
    /conductor:implement "Add user authentication"
    ```

If no track name is provided, Conductor will automatically select the next incomplete track from `tracks.md`. The implementation process follows the project's `workflow.md`, performing tasks, running tests, and creating Git checkpoints.

## :rocket: Upgrade

- [Google Conductor GitHub][1]

[1]: <https://github.com/google/conductor>
