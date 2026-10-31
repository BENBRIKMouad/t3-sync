---
name: plan
description: Plan carefully before executing a task.
metadata:
  icon: edit_note
---

# Plan (Structured Implementation Blueprint)

The user is requesting that you think and plan carefully before executing the upcoming task.
Carefully research the task, make sure that you and the user are aligned on the goals and requirements,
create a detailed implementation plan artifact, and get user approval on the plan before making any code changes (besides artifacts)
or running any modifying commands.

## Guidelines
- **Establish a shared understanding**: If there are any ambiguities, underspecified requirements, or implicit assumptions, clarify them with the user before proceeding.
- **Thoroughly research the codebase**: Establish a solid understanding of the relevant components, systems, dependencies, and architecture. As you research, provide verbal updates of your research steps and thought process so the user can follow along.
- **Create an implementation plan artifact**: Create `<Artifact Directory>/<plan_name>.md` that outlines your proposed execution strategy. Set `request_feedback = true` and `user_facing = true` in the ArtifactMetadata. The user will automatically see any new and modified plans you create, so DO NOT re-summarize the plan in chat.
- **Approval gate**: Only after the user explicitly approves the plan should you proceed to execution.
- **Verify thoroughly**: Verify that your changes have the desired effects (e.g. run unit tests, ensure code builds, verify behavior) before claiming that the task is complete.
- **Walkthrough artifact**: After completing the task and verifying the solution, create a walkthrough artifact (`<Artifact Directory>/walkthrough.md`) to summarize the changes, test results, and visual walkthrough.

## Implementation Plan Format (`<Artifact Directory>/<plan_name>.md`)
Use the following format, omitting any irrelevant sections:

```markdown
## [Goal Description]
Brief description of the problem, background context, and what the change accomplishes.

## User Review Required
Document anything that requires user review or feedback (e.g., breaking changes or significant design decisions). Use GitHub alerts (IMPORTANT/WARNING/CAUTION).

## Open Questions
Any clarifying or design questions for the user that impact the plan.

## Proposed Changes
Group files by component and order logically (dependencies first). Separate components with horizontal rules.

### [Component Name]
Summary of what will change with explicit code snippets and diffs.
#### [MODIFY] file basename
#### [NEW] file basename
#### [DELETE] file basename

## Verification Plan
### Automated Tests
Exact commands to run automated tests.
### Manual Verification
Instructions for what the user or agent should manually verify.
```

## Walkthrough Format (`<Artifact Directory>/walkthrough.md`)
- Changes made
- What was tested
- Validation results & embedded screenshots/recordings
