# Spec: /task summary command

## :dart: Goal
Automatically summarize the work done in the current session, draft the required Git Note content, and update the track's `plan.md` following the `conductor/workflow.md`.

## :gear: Requirements
- Parse the current `plan.md` of the active track.
- Summarize changes from the last task.
- Generate a Git Note draft following the project's format.
- Update `plan.md` task status from `[~]` to `[x]`.

## :link: References
- [Project Workflow: Task Summary Location](conductor/workflow.md#project-configuration)
- [Project Workflow: Standard Task Workflow](conductor/workflow.md#standard-task-workflow)
