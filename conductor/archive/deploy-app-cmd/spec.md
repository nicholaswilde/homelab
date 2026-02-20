# Spec: /deploy <app_name> command

## :dart: Goal
Automate the creation of a new application directory in `docker/` or `lxc/` based on existing templates, ensuring all steps in `conductor/workflow.md` are followed.

## :gear: Requirements
- Accepts an app name and deployment type (`docker` or `lxc`).
- Copies from `docker/.template` or `lxc/.template`.
- Prompts for required `.env.tmpl` values.
- Registers the new app in `conductor/tracks.md`.

## :link: References
- [Conductor Workflow](conductor/workflow.md)
- [Scaffolding & New Applications](conductor/workflow.md#scaffolding-&-new-applications)
