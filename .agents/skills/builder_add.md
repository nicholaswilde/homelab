# /builder add `<project_name>` `<github_repo_url>`

Automate adding a new application builder to the reprepro modular builders system, ensuring targets for standard and Raspberry Pi architectures (`armv6`, `armv7`) are fully supported.

## Description
This command simplifies registering a new project in the `pve/reprepro/builders/` workspace, scaffolding the project directory, setting up the compilation/packaging Taskfile, and registering it in the master configurations.

## Protocol

1. **Validate Input:**
   - **Step:** Ensure `<project_name>` is a valid package name (lowercase, alphanumeric, or hyphens).
   - **Step:** Ensure `<github_repo_url>` matches the standard GitHub repository URL format (`https://github.com/owner/repo`).
   - **Step:** Extract `owner/repo` from the URL.

2. **Select Builder Type:**
   - **Step:** Analyze the repository language (Go, Rust, or C/C++) by querying the GitHub repository details or asking the user.
   - **Step:** Choose the appropriate scaffolding template based on the language:
     - **Go**: Use the GoReleaser Snapshot template (`templates/goreleaser-main.yaml`).
     - **Rust**: Use the `cross` + `nfpm` multi-architecture template.
     - **C/C++ / Generic**: Use a custom native compilation `nfpm` template.

3. **Scaffold Project Directory:**
   - **Step:** Create the subdirectory `pve/reprepro/builders/projects/<project_name>/`.
   - **Step:** Create a project-specific `Taskfile.yml` configured with targets for:
     - `amd64` (standard 64-bit Intel/AMD)
     - `arm64` (modern 64-bit ARM)
     - `armv7` (`armhf` architecture for standard Raspberry Pi/ARM devices)
     - `armv6` (`armhf+armv6` suffix target to automatically route to the `raspi` distribution)

4. **Scaffolding Templates:**

   ### For Go Projects
   Create `pve/reprepro/builders/projects/<project_name>/Taskfile.yml` that invokes GoReleaser using the shared `templates/goreleaser-main.yaml` (which automatically supports `goarch: arm`, `goarm: 6` and `7` for armv6/armv7):
   ```yaml
   version: '3'
   vars:
     ROOT: "{{.TASKFILE_DIR}}/../.."
     REMOTE_IP: { sh: 'grep REMOTE_IP {{.ROOT}}/../.env | cut -d= -f2' }
     PROJECT_NAME: <project_name>
     PROJECT_REPO_URL: <github_repo_url>
     PROJECT_LATEST_VERSION:
       sh: git ls-remote --tags --refs --sort="v:refname" {{.PROJECT_REPO_URL}} | tail -n1 | sed 's/.*\///'
     PROJECT_VERSION_TAG: '{{default .PROJECT_LATEST_VERSION .VERSION}}'
     PROJECT_MAIN_PATH: .
     DIST_DIR: "{{.ROOT}}/dist"
     BUILD_DIR: "{{.ROOT}}/build"
   tasks:
     build:
       desc: Build "<project_name>" (Go)
       cmds:
         - goreleaser release --config {{.ROOT}}/templates/goreleaser-main.yaml --snapshot --clean --skip=publish
         - mkdir -p {{.DIST_DIR}}
         - mv {{.BUILD_DIR}}/{{.PROJECT_NAME}}/dist/*.deb {{.DIST_DIR}}/
   ```

   ### For Rust Projects
   Create `pve/reprepro/builders/projects/<project_name>/Taskfile.yml` using `cross` to target cross-compilations (supporting both `arm-unknown-linux-gnueabihf` for `armv6` and `armv7-unknown-linux-gnueabihf` for `armv7` hard float targets):
   ```yaml
   version: '3'
   vars:
     ROOT: "{{.TASKFILE_DIR}}/../.."
     REMOTE_IP: { sh: 'grep REMOTE_IP {{.ROOT}}/../.env | cut -d= -f2' }
     PROJECT_NAME: <project_name>
     PROJECT_REPO_URL: <github_repo_url>
     PROJECT_LATEST_VERSION:
       sh: git ls-remote --tags --refs --sort="v:refname" {{.PROJECT_REPO_URL}} | tail -n1 | sed 's/.*\///'
     PROJECT_VERSION_TAG: '{{default .PROJECT_LATEST_VERSION .VERSION}}'
     CACHE_DIR: "{{.ROOT}}/.cache"
     DIST_DIR: "{{.ROOT}}/dist"
     BUILD_DIR: "{{.ROOT}}/build"
   tasks:
     build:
       desc: "Build <project_name> (Rust)"
       cmds:
         - mkdir -p {{.CACHE_DIR}} {{.DIST_DIR}} {{.BUILD_DIR}}/stage
         - # Clone repository and checkout PROJECT_VERSION_TAG...
         - task: process-target
           vars: {RUST: "x86_64-unknown-linux-gnu", GO: "amd64", DEB: "amd64", SUFFIX: "amd64"}
         - task: process-target
           vars: {RUST: "aarch64-unknown-linux-gnu", GO: "arm64", DEB: "arm64", SUFFIX: "arm64"}
         - task: process-target
           vars: {RUST: "armv7-unknown-linux-gnueabihf", GO: "arm_7", DEB: "armhf", SUFFIX: "armhf"}
         - task: process-target
           vars: {RUST: "arm-unknown-linux-gnueabihf", GO: "arm_6", DEB: "armhf", SUFFIX: "armhf+armv6"}
     process-target:
       internal: true
       cmds:
         - task: compile
           vars: {RUST_TARGET: "{{.RUST}}", GO_FOLDER: "linux_{{.GO}}"}
         - task: package
           vars: {GO_ARCH: "{{.GO}}", ARCH: "{{.DEB}}", SUFFIX: "{{.SUFFIX}}"}
     compile:
       internal: true
       dir: "{{.BUILD_DIR}}/{{.PROJECT_NAME}}"
       cmds:
         - cross build --release --target {{.RUST_TARGET}}
         - mkdir -p {{.CACHE_DIR}}/{{.GO_FOLDER}}
         - cp target/{{.RUST_TARGET}}/release/{{.PROJECT_NAME}} {{.CACHE_DIR}}/{{.GO_FOLDER}}/
     package:
       internal: true
       dir: "{{.BUILD_DIR}}/stage"
       cmds:
         - cp {{.CACHE_DIR}}/linux_{{.GO_ARCH}}/<project_name> ./binary
         - # Write nfpm.yaml and run:
         - nfpm pkg --config nfpm.yaml --packager deb --target {{.DIST_DIR}}/{{.PROJECT_NAME}}_{{.PROJECT_VERSION_TAG}}_{{.SUFFIX}}.deb
   ```

5. **Register the Project in Configurations:**
   - **Step:** Append the project to the `includes` section of the master `pve/reprepro/builders/Taskfile.yml`:
     ```yaml
     includes:
       <project_name>: ./projects/<project_name>/Taskfile.yml
     ```
   - **Step:** Append `- task: <project_name>:build` inside the `build-all` task in the master `Taskfile.yml`.
   - **Step:** Add the entry `"<project_name>:<project_name>:<owner>/<repo>"` to the `PROJECTS` array in `pve/reprepro/builders/scripts/sync.sh`.
   - **Step:** Add mapping in `pve/reprepro/builders/scripts/webhook_trigger.sh` case statement to support individual webhook calls:
     ```bash
     "<project_name>") REPO="<owner>/<repo>" ;;
     ```

6. **Verify and Stage:**
   - **Step:** Run `task <project_name>:latest` to verify that repository and tag comparisons work properly.
   - **Step:** Stage the new project folder and updated configuration files.
   - **Announce:** "Successfully registered and structured the `<project_name>` builder supporting both amd64, arm64, armv6, and armv7 platforms."
