---
name: task-summary
description: Automatically summarize work done in the current task and draft Git commit/note content.
---

# /task summary

Automatically summarize the work done in the current task and draft a Git Note or commit summary based on staged and working tree changes.

## Protocol

1. **Identify Current Context:**
   - Run `rtk git status` and `rtk git diff --stat`.
   - Check for open GitHub issues if relevant: `rtk gh issue list -L 5 | cat`.

2. **Summarize Changes:**
   - Analyze all file changes made in the working tree or staged commits.
   - Create a concise summary of changes and the core rationale.
   - List all modified/created files.

3. **Draft Summary / Git Note:**
   - Generate a summary draft in the following format:
     ```markdown
     ### Task Summary: <Description>
     - **Summary**: <Brief summary of changes and "why">
     - **Files**: <List of relative file paths>
     - **Issue**: <Fixes #123 if applicable>
     ```

4. **Announce Completion:**
   - Present the summary to the user.
