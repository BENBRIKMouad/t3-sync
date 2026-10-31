---
name: browser
description: Invoke a browser agent for web tasks.
metadata:
  icon: public
---

# Browser (Web & Preview Automation Agent)

The user invoked `/browser` for web navigation, inspection, testing, or UI automation tasks.

## Tool Integration & Best Practices
In T3 Code, browser automation is performed via the shared `preview_*` toolset:
- `preview_status`: Always check first to see if an automated browser tab is already open.
- `preview_open`: Open target URL if no tab can be automated.
- `preview_navigate`: Navigate to a new URL.
- `preview_snapshot`: Capture accessibility tree locators and visual state. **Prefer snapshot locators over raw coordinates.**
- `preview_act`: Interact with elements (click, fill input, hover, scroll).
- `preview_evaluate`: Run JavaScript in the page context for complex DOM inspection or state extraction.
- `preview_wait_for`: Wait for DOM conditions or network idle before acting.
