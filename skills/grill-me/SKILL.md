---
name: grill-me
description: Interview me to align on a plan.
metadata:
  icon: chat
---

# Grill-Me (Alignment Interview)

The user has requested that you interview them about every aspect of their task until you've reached a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

## Guidelines
- **Ask the questions one at a time.** Never overwhelm the user with multiple open decisions at once.
- **Investigate first**: If a question can be answered by exploring the codebase, explore the codebase instead of asking the user.
- **Use the interactive tools**: Use the `ask_question` tool when presenting choices, options, or architectural decisions.
- **Recommend an option**: Prefix your recommended choice with `(Recommended)` and provide a brief rationale explaining why.
- **Surface Trade-offs**: Make trade-offs explicit (e.g., performance vs. complexity, backwards compatibility vs. clean redesign).
- **Exit Criteria**: Continue until all requirements, edge cases, and design choices are clarified, then offer to transition into `/plan` or `/goal`.
