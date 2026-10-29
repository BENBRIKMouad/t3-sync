---
name: t3-sync
description: Sync, diff, backup, and inspect T3 Code, Gemini/Antigravity providers, and MCP environment settings with Git and Bitwarden. Supports diff checking before backup, automated git pull, host-aware commit messages, missed secret detection, and secret pushing to Bitwarden Vault.
metadata:
  icon: sync
---

# T3 & Provider Environment Sync Skill

This skill allows the agent to inspect, diff, backup, commit, and synchronize your T3 Code configuration, Gemini/Antigravity provider configs, MCP servers, and Bitwarden secrets across machines.

---

## Capabilities & Workflows

### 1. Diff Current Environment (`/t3-diff` or asking to compare)
Compares active local configs against the Git repository and verifies secrets in Bitwarden:
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
powershell -NoProfile -File .\scripts\diff-env.ps1 -CheckBitwarden
```
* **Compares**:
  * `~/.t3/userdata/client-settings.json` vs `config/client-settings.json`
  * `~/.t3/userdata/keybindings.json` vs `config/keybindings.json`
  * `~/.t3/userdata/desktop-settings.json` vs `config/desktop-settings.json`
  * `~/.cursor/mcp.json` vs `config/mcp.json`
  * `~/.gemini/config/config.json` vs `config/providers/gemini/config.json`
  * `~/.gemini/config/mcp_config.json` vs `config/providers/gemini/mcp_config.json`
* **Scans for Missed Secrets**: Inspects JSON values for exposed API tokens (`ghp_`, `sk-`, `AIza`, keys, bearer tokens) that are not yet parameterized with `${VAR}`.
* **Checks Bitwarden**: Validates whether secret keys are registered in the `t3-secrets` item in Bitwarden Vault.

---

### 2. Full Sync Pipeline (`/t3-sync` or asking to sync the environment)
Executes the full automated workflow:
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
powershell -NoProfile -File .\scripts\sync-all.ps1
```

**Order of execution**:
1. **Git Pull (`git pull --rebase`)**: Always pulls remote changes first to prevent merge conflicts.
2. **Diff & Secret Scan**: Compares local environment against remote and scans for hardcoded secrets.
3. **Confirmation**: Presents the diff and asks if you want to proceed with the backup.
4. **Backup & Commit**:
   * Copies active settings and Gemini provider files to `config/`.
   * Sanitizes sensitive fields.
   * If unmasked secrets are found, prompts to save them into Bitwarden (`bw create/edit`) and replaces them with `${VAR}`.
   * Generates a commit message detailing **what changed** and the **source hostname** (e.g. `sync(MOUAD-BENBRIK-D): update desktop-settings.json [source: MOUAD-BENBRIK-D]`).
5. **Git Push**: Pushes the update to GitHub.

---

### 3. Check for Missed Secrets Only (`/t3-audit-secrets`)
Inspects active local environment files for any unparameterized or hardcoded tokens:
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
powershell -NoProfile -File .\scripts\diff-env.ps1
```

---

### 4. Pull Secrets from Bitwarden to Windows (`/t3-pull-secrets`)
Fetches all secrets from the `t3-secrets` Bitwarden item and sets them as Windows User Environment Variables:
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
powershell -NoProfile -File .\scripts\sync-secrets.ps1
```

---

### 5. Apply Configs to Current Machine (`/t3-apply`)
Applies the repository configurations to the current machine's T3 userdata and Gemini config directories:
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
# Copy mode:
powershell -NoProfile -File .\scripts\apply.ps1 -SyncSecrets

# Symlink mode (live links):
powershell -NoProfile -File .\scripts\apply.ps1 -Symlink -SyncSecrets
```

---

## Useful Prompt Examples for You

You can prompt the assistant naturally with requests like:

* **Sync everything**:
  > *"Sync my environment now."*
  > *"Run git pull, backup my local T3 & provider configs, and push."*

* **Diff & Preview**:
  > *"Compare my current T3 and Gemini configs with the GitHub repo and tell me what changed."*
  > *"Show me if my local environment has any differences before backing up."*

* **Secret Auditing & Migration**:
  > *"Check if any of my local config files or MCPs have unmasked secrets."*
  > *"I added a new API key in mcp.json; move it to Bitwarden and replace it with a variable."*

* **Restore / Setup Secondary PC**:
  > *"I'm on my second PC, apply the latest repo settings and pull my Bitwarden keys."*
