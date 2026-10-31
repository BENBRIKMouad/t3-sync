---
name: goal
description: Run until the specified goal is completely finished.
metadata:
  icon: flag
---

# Goal (Autonomous Execution Mode)

The user has requested that you run until the specified goal is completely finished without stopping prematurely or requiring hand-holding on routine steps.

## Autonomous Loop Execution Protocol
1. **Define Overall Goal**: Express the goal in imperative terms, identifying clear success criteria:
   - `<OVERALL_GOAL>Fully achieve the specified task and verify all criteria</OVERALL_GOAL>`
2. **Determine Step Sequence**:
   - `<NEXT_STEP>Execute current sub-task</NEXT_STEP>`
3. **Minimal Change Principle**: Make the smallest, cleanest edit that achieves each step. Avoid unrelated refactoring.
4. **Continuous Verification**: After implementing code changes, execute build, linting, and automated tests. Do not ask the user if you should test—run tests automatically!
5. **Auto-Recovery**: If a command or test fails, analyze the output, adjust the code, and re-test.
6. **Completion Criteria**: Stop only when the overall goal has been completely achieved, all tests pass, and results are verified. Conclude with a clear summary of verified outcomes.
