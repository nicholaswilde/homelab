# :runner: GitHub Runner

GitHub Actions runner for building Golang and Rust projects.

## :hammer_and_wrench: Installation

This application is installed in an LXC container.

### Dependencies

- `curl`
- `git`
- `jq`
- `docker`
- `golang`
- `rust`

## :gear: Config

Configuration is handled via environment variables in `.env`.

### Environment Variables

- `GITHUB_REPO`: The repository to attach the runner to (e.g., `nicholaswilde/homelab`).
- `GITHUB_TOKEN`: PAT with `repo` scope to register the runner.
- `RUNNER_NAME`: Name of the runner.
- `RUNNER_LABELS`: Comma-separated labels (e.g., `self-hosted,arm64`).

## :pencil: Usage

The runner starts automatically as a systemd service.

## :rocket: Upgrade

!!! code ""

    === "Task"
    
        ```shell
        task update
        ```

## :link: References

- [GitHub Actions Runner](https://github.com/actions/runner)
- [GoReleaser](https://goreleaser.com/)
- [Rust](https://www.rust-lang.org/)

[1]: <https://github.com/actions/runner>
