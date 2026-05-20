# /task summary

Automatically summarize the work done in the current task, draft the required Git Note content, and update the track's `plan.md` following the `conductor/workflow.md`.

## Protocol

1. **Identify Active Track:**
   - Read `conductor/tracks.md`.
   - Identify the track currently marked as `[~]`.
   - Resolve the path to its `plan.md`.

2. **Find Active Task:**
   - Read the track's `plan.md`.
   - Identify the task currently marked as `[~]`.
   - Extract the task description.

3. **Summarize Changes:**
   - Analyze all file changes made since the task began (using `git diff`).
   - Create a concise summary of changes and the core "why".
   - List all modified/created files.

4. **Draft Git Note:**
   - Generate a Git Note draft in the following format:
     ```markdown
     ### Task Summary: <Task Description>
     - **Summary**: <Brief summary of changes and "why">
     - **Files**: <List of relative file paths>
     ```
   - Store this draft in a local state or temporary file as per `conductor/workflow.md`.

5. **Update Task Status:**
   - Modify the track's `plan.md`.
   - Change the task status from `[~]` to `[x]`.
   - Save the modified `plan.md`.

6. **Phase Completion Check:**
   - Check if all tasks in the current phase are now marked as `[x]`.
   - If the phase is complete, announce: "Phase complete! Initiating Phase Completion Verification and Checkpointing Protocol."
   - Proceed to follow the "Phase Completion Verification and Checkpointing Protocol" in `conductor/workflow.md`.

7. **Announce Completion:**
   - Inform the user that the task summary has been drafted and the plan updated.
