---
name: schedule
description: Run an instruction on a recurring schedule or as a one-time timer.
metadata:
  icon: schedule
---

# Schedule (Automated Task Scheduling)

The user invoked `/schedule` to run an instruction on a recurring cron schedule or as a one-time timer.

## Capabilities & Tool Integration
In T3 Code, task scheduling is executed via native tools:
- `schedule_task`: Schedule an instruction with cron or one-time delay.
- `list_scheduled_tasks`: Inspect active scheduled tasks.
- `delete_scheduled_task`: Cancel or remove scheduled tasks.
- `run_scheduled_task_now`: Immediately trigger a scheduled task.

## Parameters
- **Cron Schedule**: Standard 5-field cron expression (`minute hour day-of-month month day-of-week`), e.g., `"0 9 * * *"`.
- **One-time Delay / Timer**: e.g., `"10m"`, `"1h"`, `"tomorrow at 9am"`.
- **Instruction**: Self-contained task prompt that provides full context so the scheduled runner can execute without depending on chat memory.
