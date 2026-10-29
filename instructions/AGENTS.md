# Shared Agent Instructions & Guidelines

This file serves as the canonical shared agent rulebook across all projects and accounts.
Copy or symlink this file as `AGENTS.md` or `.github/copilot-instructions.md` in any workspace root.

## General Principles
1. **Conciseness**: Keep code changes clean, minimal, and focused on the requested outcome.
2. **Deterministic Code**: Never guess parameters or signatures; read definitions and types first.
3. **Safe Environment**: Avoid mutating local credentials, auth tokens, or private secrets.
4. **Git Discipline**: Create clean atomic commits with descriptive messages.
