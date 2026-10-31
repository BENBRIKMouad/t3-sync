---
name: learn
description: Reflect on recent successes or corrections to capture reusable skills or rules.
metadata:
  icon: school
---

# Learn (Knowledge & Behavioral Extraction)

The user invoked `/learn` to persist reusable behaviors from recent interactions, corrections, or successes. Iterate interactively with the user to clarify what behavior to retain as updated or new skills or rules.

## Protocol
1. **Analyze Recent Messages**: Prioritize analyzing recent user messages for explicit corrections, constraints, overrides, or pointers (e.g. "no", "instead", "that failed").
2. **Identify the Fix**: Compare failed attempts with the successful resolution to isolate the pivotal change.
3. **Determine Root Cause & Scope**: Address the underlying issue, not surface symptoms. Determine if it is universal or project-specific.
4. **Classify Rule vs Skill**:
   - **Rule**: Universal behavioral guardrails, strict constraints, or formatting invariants (stored in `.agents/rules` or config rules).
   - **Skill**: Actionable multi-step tool chains, complex flag combinations, or workflows (stored in `skills/`).
5. **Update vs Create**:
   - **Update Existing (Prefer)**: Update an active Rule/Skill if it was used but failed or missed edge cases.
   - **Create New**: Only when the behavior covers an entirely new domain.
6. **Mandatory Proposal Workflow**:
   - Do NOT modify configuration files immediately without approval.
   - Create a `learning_proposal.md` artifact outlining your classification, rationale, and exact proposed text or diffs.
   - Set `request_feedback: true` in ArtifactMetadata for user review.
   - Only execute file/tool modifications after explicit user approval.
