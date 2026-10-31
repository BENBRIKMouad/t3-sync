---
name: compact
description: Compact the conversation now (summarize history to free up the context window).
metadata:
  icon: compress
---

# Compact (Context Window History Compaction)

The user requested `/compact` to summarize history and free up context window space while preserving all critical continuity.

## Compaction Guidelines
Produce a structured summary preserving:
1. **Active Overall Goal**: The high-level objective and active user instructions.
2. **Key Decisions & Constraints**: Architecture decisions, user preferences, explicit rules established.
3. **File Modifications**: Files created, modified, or deleted during the conversation.
4. **Current Status & Verification State**: What has been implemented, what tests have passed, and what has been verified.
5. **Next Steps**: Exact remaining actions required to complete the task.

Format the summary concisely so both the user and future agent turns have immediate, lossless orientation.
