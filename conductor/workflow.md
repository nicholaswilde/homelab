# Project Workflow

## Project Configuration

- **Required Test Coverage:** >80%
- **Commit Frequency:** After each phase
- **Task Summary Location:** Git Notes

## Project Structure

- **`docker/`**: Docker apps. Use `.template` for new.
- **`docs/`**: Markdown docs (Apps, Tools, Hardware).
- **`lxc/`**: Proxmox LXC app configs.
- **`pve/`**: Proxmox VE cluster + node configs.
- **`scripts/`**: Bash + Python automation.
- **`vm/`**: VM configs.

## Scaffolding & New Applications

### Docker Applications

1. **Copy Template:** Copy `docker/.template` to new dir.
2. **Update Environment:** Fill `.env.tmpl` (CONTAINER_NAME, DB creds).
3. **Configure Compose:** Update `compose.yaml` (service name, image version).
4. **Finalize:** Remove `.j2` after substitution.

### Proxmox LXC Applications

1. **Research & Reference:**
    - Search [community-scripts](https://github.com/community-scripts/ProxmoxVE/tree/main/install) for install script.
    - Found = use as main reference for install, config, deps.
    - Not found = search official docs or community guides.
2. **Scaffolding:** Copy `lxc/.template` to `lxc/<app_name>`.
3. **Environment:** Update `Taskfile.yml` (SERVICE_NAME, INSTALL_DIR, CONFIG_DIR).
4. **Provisioning:**
    - Use `list_templates` for `debian-trixie`.
    - Run `pct create` with `--unprivileged 0`, `--net0 name=eth0,bridge=vmbr0,ip=dhcp,ip6=slaac`, `--features nesting=1`.
    - Set `--password $(pass show default-lxc-password)`.
5. **Post-Setup:**
    - Install `openssh-server` + `syncthing`.
    - Purge `cloud-init`.
    - Update `/etc/ssh/sshd_config`:
        - Set `PermitRootLogin yes`.
        - Ensure `PubkeyAuthentication yes`.
    - Enable/start `syncthing@root`.
    - Restart SSH.
    - **Note:** No default user. Use root + `pass` password.
6. **Network & Routing:**
    - **Traefik:** Create config in `pve/traefik/conf.d/`.
    - **DNS:** Add AdGuard Home DNS rewrite.
    - **Syncthing:**
        - Get Device ID: `pct exec <vmid> -- syncthing --device-id`.
        - Add to host: Use `syncthing_manage_devices` (args: `action: "add"`, `device_id`, `name`).
    - **Dashboards:**
        - Add to `pve/homepage/config/services.yaml`.
        - Add to `lxc/gatus/config.yaml.enc` (decrypt/edit/encrypt).
    - **Finalize:** Run `/homepage update`, `/traefik update`, `/gatus update`.

## Common Commands

Run `Taskfile.yml` ops via `task`.

- `task build`: Build docs via Zensical.
- `task serve`: Start doc dev server (port 8000).
- `task lint`: Run Yamllint, Markdownlint, Linkcheck.
- `task markdownlint`: Run Markdownlint.
- `task yamllint`: Run Yamllint.
- `task linkcheck`: Check broken doc links.
- `task generate-docs-nav`: Regenerate the MkDocs navigation.
- `markitdown-rs`: CLI convert file to Markdown.

## Guiding Principles

1. **Plan = Source of Truth:** Track all work in `plan.md`.
2. **Tech Stack Deliberate:** Document changes in `tech-stack.md` before implementation.
3. **TDD:** Write unit tests before code.
4. **Coverage:** >80% code coverage.
5. **UX First:** Prioritize UX + doc clarity.
6. **Non-Interactive & CI-Aware:** Prefer non-interactive. Use `CI=true` for watch-mode.
7. **Scripting Excellence:**
    - **Bash:** Use ShellCheck, 2-space indent, `function` keyword, UPPERCASE constants. Handle errors (`set -e`, `set -o pipefail`). Standard log function with Catppuccin Mocha colors.
    - **Python:** Strict PEP 8, 4-space indent, type hints, modular. Use `f-strings` + docstrings.
8. **Doc Standards:** Strict Zensical/MkDocs style (emoji headings, relative links, standard sections, Material design).

## Task Workflow

Strict task lifecycle:

### Standard Task Workflow

1. **Select Task:** Pick next task in `plan.md`.

2. **Mark In Progress:** Set `plan.md` task `[ ]` -> `[~]`.

3. **Write Failing Tests (Red Phase):**
   - Create test file.
   - Write unit tests defining expected behavior.
   - **CRITICAL:** Run tests. Must fail (Red phase). Do not proceed until fail.

4. **Implement to Pass Tests (Green Phase):**
   - Write minimum code to pass tests.
   - Run tests. Must pass (Green phase).

5. **Refactor (Optional but Recommended):**
   - Refactor for clarity, dedup, perf. Keep external behavior.
   - Rerun tests. Must pass.

6. **Verify Coverage:** Run coverage tools.
   Target: >80% coverage new code.

7. **Document Deviations:** If code differs from tech stack:
   - **STOP**.
   - Update `tech-stack.md`.
   - Add dated note explaining change.
   - Resume.

8. **Stage Code Changes:**
   - Stage task code changes.
   - Do not commit. Commit happens end of phase.

9. **Draft Task Summary:**
   - **Step 9.1: Draft Note:** Summarize task (name, changes, files, core reason).
   - **Step 9.2: Save Summary:** Save locally. Will attach as Git Note to phase commit.

10. **Record Task Status:**
    - **Step 10.1: Update Plan:** Read `plan.md`. Set task `[~]` -> `[x]`.
    - **Step 10.2: Write Plan:** Write `plan.md`.

11. **Stage Plan Update:**
    - **Action:** Stage `plan.md`.

### Phase Completion Verification and Checkpointing Protocol

**Trigger:** Execute after completing task that ends phase in `plan.md`.

1. **Announce Start:** Tell user phase complete. Protocol start.

2. **Ensure Test Coverage for Phase Changes:**
    - **Step 2.1: Scope:** Find previous phase SHA in `plan.md`. No previous = all changes.
    - **Step 2.2: List Files:** Run `git diff --name-only <previous_checkpoint_sha> HEAD`.
    - **Step 2.3: Verify Tests:** For each file:
        - **CRITICAL:** Exclude non-code (`.json`, `.md`, `.yaml`).
        - Verify code files have test files.
        - Missing test? Create it. Analyze existing tests for style/naming first. Test must validate `plan.md` phase tasks.

3. **Execute Automated Tests with Proactive Debugging:**
    - Announce exact test shell command before run.
    - **Example:** "Running automated tests. **Command:** `CI=true npm test`"
    - Run command.
    - Tests fail = tell user, debug. Max 2 fix attempts. Still fail = STOP, report, ask user.

4. **Propose a Detailed, Actionable Manual Verification Plan:**
    - **CRITICAL:** Analyze `product.md`, `product-guidelines.md`, `plan.md` for phase goals.
    - Generate step-by-step manual verification plan (commands, expected outcomes).
    - Format:

        **For a Frontend Change:**
        ```
        The automated tests have passed. For manual verification, please follow these steps:

        **Manual Verification Steps:**
        1.  **Start the development server with the command:** `npm run dev`
        2.  **Open your browser to:** `http://localhost:3000`
        3.  **Confirm that you see:** The new user profile page, with the user's name and email displayed correctly.
        ```

        **For a Backend Change:**
        ```
        The automated tests have passed. For manual verification, please follow these steps:

        **Manual Verification Steps:**
        1.  **Ensure the server is running.**
        2.  **Execute the following command in your terminal:** `curl -X POST http://localhost:8080/api/v1/users -d '{"name": "test"}'`
        3.  **Confirm that you receive:** A JSON response with a status of `201 Created`.
        ```

5. **Await Explicit User Feedback:**
    - After presenting the detailed plan, ask the user for confirmation: "**Does this meet your expectations? Please confirm with yes or provide feedback on what needs to be changed.**"
    - **PAUSE** and await the user's response. Do not proceed without an explicit yes or confirmation.

6. **Create Phase Commit:**
    - Stage all remaining changes.
    - Perform a single commit for the entire phase with a message like `feat(phase): Complete Phase <Phase Name>`.

7. **Attach Task Summaries and Verification Report:**
    - **Step 7.1: Get Commit Hash:** Obtain the hash of the *just-created phase commit*.
    - **Step 7.2: Attach Summaries:** Attach all drafted task summaries from the phase to this commit using `git notes`.
    - **Step 7.3: Attach Verification Report:** Append the verification report (test results, manual verification steps, user confirmation) to the git notes for the same commit.

8. **Record Phase Checkpoint and Task SHAs:**
    - **Step 8.1: Get Commit Hash:** Obtain the hash of the phase commit.
    - **Step 8.2: Update Plan:** Read `plan.md`.
    - **Step 8.3: Update Phase Heading:** Update the phase heading with the checkpoint SHA in the format `[checkpoint: <sha>]`.
    - **Step 8.4: Update Task SHAs:** Update all tasks completed in this phase with the same 7-character SHA.
    - **Step 8.5: Write Plan:** Write the updated content back to `plan.md`.

9. **Commit Plan Update:**
    - **Action:** Stage and commit the modified `plan.md` file with a message like `conductor(plan): Mark phase '<PHASE NAME>' as complete`.

10. **Announce Completion:** Inform the user that the phase is complete and the checkpoint has been created, with the detailed verification report attached as a git note.

### Quality Gates

Before marking any task complete, verify:

- [ ] All tests pass
- [ ] Code coverage meets requirements (>80%)
- [ ] Code follows project's code style guidelines (as defined in `code_styleguides/`)
- [ ] No secrets or `.env` files are tracked in version control (run `git ls-files | grep -E "\.env$"` to verify)
- [ ] All public functions/methods are documented (e.g., docstrings, JSDoc, GoDoc)
- [ ] Type safety is enforced (e.g., type hints, TypeScript types, Go types)
- [ ] No linting or static analysis errors (using the project's configured tools)
- [ ] Works correctly on mobile (if applicable)
- [ ] Documentation updated if needed
- [ ] No security vulnerabilities introduced

## Development Commands

**AI AGENT INSTRUCTION: This section should be adapted to the project's specific language, framework, and build tools.**

### Setup

```bash
# Example: Commands to set up the development environment (e.g., install dependencies, configure database)
```

### Daily Development

```bash
# Example: Commands for common daily tasks (e.g., start dev server, run tests, lint, format)
```

### Before Committing

```bash
# Example: Commands to run all pre-commit checks (e.g., format, lint, type check, run tests)
```

## Testing Requirements

### Unit Testing

- Every module must have corresponding tests.
- Use appropriate test setup/teardown mechanisms (e.g., fixtures, beforeEach/afterEach).
- Mock external dependencies.
- Test both success and failure cases.

### Integration Testing

- Test complete user flows.
- Verify database transactions.
- Test authentication and authorization.
- Check form submissions.

### Mobile Testing

- Test on actual iPhone when possible.
- Use Safari developer tools.
- Test touch interactions.
- Verify responsive layouts.
- Check performance on 3G/4G.

## Documentation Style Guide

### File Naming & Structure

- **Applications:** `docs/apps/app-name.md`
- **Tools:** `docs/tools/tool-name.md`
- **Hardware:** `docs/hardware/hardware-name.md`
- **Sections:** All sections must have an emoji prefix. Standard sections include: `# :emoji: Title`, `## :hammer_and_wrench: Installation`, `## :gear: Config`, `## :pencil: Usage`, `## :rocket: Upgrade`, `## :link: References`.

### Markdown Conventions

- Use ATX-style headings (`#`, `##`, etc.).
- Use Material Design icons and shortcodes for emojis.
- All internal links must be relative and point to `.md` files.
- All hyperlinks must be numbered and listed at the bottom of the document.
- Admonitions (Zensical): `!!! note`, `!!! code`, `!!! abstract`, `!!! tip`, `!!! warning`, `!!! danger`.

## Scripting Guidelines

### Bash Scripting

- **Shebang:** `#!/usr/bin/env bash`
- **Main Function:** Encapsulate logic in `main "@"` at the bottom of the script.
- **Logging:** Use `log "INFO|WARN|ERRO|DEBU" "message"` with Catppuccin Mocha colors.
- **Header:** Include a commented header with Name, Description, Author (GPG key), Date, and Version.
- **Paths:** Hardcoded paths must be set as variables after options.

### Python Scripting

- **Shebang:** `#!/usr/bin/env python3`
- **Compliance:** Strict PEP 8. Use 4-space indentation and snake_case for variables/functions.
- **Documentation:** Use docstrings for all functions and classes.
- **Modularity:** Break complex tasks into small, reusable functions.
- **Imports:** Group by Standard Library, Third-party, and Local.

## Code Review Process

### Self-Review Checklist

Before requesting review:

1. **Functionality**
   - Feature works as specified.
   - Edge cases handled.
   - Error messages are user-friendly.

2. **Code Quality**
   - Follows style guide.
   - DRY principle applied.
   - Clear variable/function names.
   - Appropriate comments.

3. **Testing**
   - Unit tests comprehensive.
   - Integration tests pass.
   - Coverage adequate (>80%).

4. **Security**
   - No hardcoded secrets.
   - Input validation present.
   - SQL injection prevented.
   - XSS protection in place.

5. **Performance**
   - Database queries optimized.
   - Images optimized.
   - Caching implemented where needed.

6. **Mobile Experience**
   - Touch targets adequate (44x44px).
   - Text readable without zooming.
   - Performance acceptable on mobile.
   - Interactions feel native.

## Commit Guidelines

### Message Format

```text
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature.
- `fix`: Bug fix.
- `docs`: Documentation only.
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change that neither fixes a bug nor adds a feature.
- `test`: Adding missing tests.
- `chore`: Maintenance tasks.

### Examples

```bash
git commit -m "feat(auth): Add remember me functionality"
git commit -m "fix(posts): Correct excerpt generation for short posts"
git commit -m "test(comments): Add tests for emoji reaction limits"
git commit -m "style(mobile): Improve button touch targets"
```

## Definition of Done

A task is complete when:

1. All code implemented to specification.
2. Unit tests written and passing.
3. Code coverage meets project requirements.
4. Documentation complete (if applicable).
5. Code passes all configured linting and static analysis checks.
6. Works beautifully on mobile (if applicable).
7. Implementation notes added to `plan.md`.
8. Changes committed with proper message.
9. Git note with task summary attached to the commit.

## Emergency Procedures

### Critical Bug in Production

1. Hotfix branch from main.
2. Failing test for bug.
3. Minimal fix.
4. Test thoroughly (inc mobile).
5. Deploy immediately.
6. Document in `plan.md`.

### Data Loss

1. Stop writes.
2. Restore latest backup.
3. Verify data integrity.
4. Document incident.
5. Update backup procedures.

### Security Breach

1. Rotate secrets immediately.
2. Review access logs.
3. Patch vuln.
4. Notify affected users.
5. Document + update security procedures.

## Deployment Workflow

### Pre-Deployment Checklist

- [ ] Tests passing.
- [ ] Coverage >80%.
- [ ] No lint errors.
- [ ] Mobile testing complete.
- [ ] Env vars configured.
- [ ] DB migrations ready.
- [ ] Backup created.

### Deployment Steps

1. Merge branch to main.
2. Tag release version.
3. Push to deploy service.
4. Run DB migrations.
5. Verify deployment.
6. Test critical paths.
7. Monitor errors.

### Post-Deployment

1. Monitor analytics.
2. Check error logs.
3. Gather user feedback.
4. Plan next iteration.

## Continuous Improvement

- Review workflow weekly.
- Update based on pain points.
- Document lessons learned.
- Optimize for user happiness.
- Keep simple + maintainable.