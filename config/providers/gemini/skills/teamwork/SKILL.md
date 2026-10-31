---
name: teamwork
description: Invoke a team of agents to autonomously tackle large projects.
metadata:
  icon: groups
---

# Teamwork (Multi-Agent Team Orchestration)

The user wants a multi-agent team to autonomously tackle a large, complex, or cross-cutting project. Orchestrate specialized agents to work collaboratively.

## Team Roles & Capabilities
- **Researcher**: Explores the codebase, scans dependencies, inspects APIs, and gathers context (`invoke_subagent` with role `research`).
- **Test Writer**: Establishes reproduction cases, unit tests, and validation benchmarks before or alongside implementation.
- **Implementer / Coder**: Applies targeted modifications adhering to architectural design.
- **Reviewer / Challenger**: Inspects diffs, audits edge cases, checks security, and validates compliance.

## Teamwork Protocol
1. **Scope & Decomposition**: Break down the project into decoupled subtasks and workstreams.
2. **Subagent Delegation**:
   - Use `invoke_subagent` to spawn background subagents for distinct responsibilities.
   - For long-running or parallel tasks across threads/projects, utilize T3 Code's orchestration tools (`delegate_task`, `create_threads`).
3. **Coordination**:
   - Monitor agent messages and status.
   - Synthesize subagent findings, code diffs, and verification reports.
4. **Final Assembly**: Ensure all subagent contributions merge cohesively, pass all tests, and satisfy user requirements.
