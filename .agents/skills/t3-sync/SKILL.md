---
name: t3-sync
description: Sync, diff, backup, and inspect T3 Code, Gemini/Antigravity providers (skills, plugins, MCPs, settings, projects), and Bitwarden secrets across machines. Features smart non-destructive merging, diff checking before backup, automated git pull, host-aware commit messages, missed secret detection, and Bitwarden integration.
metadata:
  icon: sync
---

# T3 & Provider Environment Sync Skill

This skill allows the agent to inspect, diff, backup, commit, and synchronize your T3 Code configuration, Gemini/Antigravity provider configs, skills, plugins, MCP servers, and Bitwarden secrets across machines.

---

## Capabilities & Workflows

### 1. Diff Current Environment (`/t3-diff` or asking to compare)
Compares active local configs, skills, and plugins against the Git repository and verifies secrets in Bitwarden:
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
powershell -NoProfile -File .\scripts\diff-env.ps1 -CheckBitwarden
```
* **Compares Configurations**:
  * `~/.t3/userdata/client-settings.json` vs `config/client-settings.json`
  * `~/.t3/userdata/keybindings.json` vs `config/keybindings.json`
  * `~/.t3/userdata/desktop-settings.json` vs `config/desktop-settings.json`
  * `~/.cursor/mcp.json` vs `config/mcp.json`
  * `~/.gemini/config/config.json` vs `config/providers/gemini/config.json` (including installed plugins & user settings)
  * `~/.gemini/config/mcp_config.json` vs `config/providers/gemini/mcp_config.json` (MCP servers)
* **Compares Skills & Plugins**:
  * `~/.gemini/config/skills` vs `config/providers/gemini/skills`
  * `~/.gemini/config/plugins` vs `config/providers/gemini/plugins`
* **Scans for Missed Secrets**: Inspects JSON values for exposed API tokens (`ghp_`, `sk-`, `AIza`, keys, bearer tokens) that are not yet parameterized with `${VAR}`.
* **Checks Bitwarden**: Validates whether secret keys are registered in the `t3-secrets` item in Bitwarden Vault.

---

## Smart Merging & Provider Completeness

* **No Clobbering Across Machines**: When syncing between different machines (e.g. desktop and laptop), `backup.ps1` and `apply.ps1` execute smart additive merges:
  * **Plugins**: Installed marketplace and local plugins (`plugins` block in `config.json`) are preserved and merged additively.
  * **MCP Servers**: MCP servers in `mcp_config.json` (e.g. Notion, etc.) are merged rather than overwritten.
  * **Skills**: All skills in `~/.gemini/config/skills` and `~/.gemini/antigravity-cli/skills` are tracked and distributed.
  * **Plugins Folder**: Any local or custom plugins in `~/.gemini/config/plugins` are tracked and distributed.
  * **Projects**: Gemini workspace project files in `projects/*.json` are backed up and restored.

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
   * Copies active settings and Gemini provider files (including skills, plugins, and MCPs) to `config/`.
   * Sanitizes sensitive fields.
   * If unmasked secrets are found, prompts to save them into Bitwarden (`bw create/edit`) and replaces them with `${VAR}`.
   * Generates a commit message detailing **what changed** and the **source hostname** (e.g. `sync(MOUAD-BENBRIK-D): update config.json, skills, plugins [source: MOUAD-BENBRIK-D]`).
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
  > *"Sync my environment now (including all Gemini configs, skills, plugins, and MCPs)."*
  > *"Run git pull, backup my local T3 & provider configs, and push."*

* **Diff & Preview**:
  > *"Compare my current T3 and Gemini configs, skills, and plugins with the GitHub repo and tell me what changed."*
  > *"Show me if my local environment has any differences before backing up."*

* **Secret Auditing & Migration**:
  > *"Check if any of my local config files or MCPs have unmasked secrets."*
  > *"I added a new API key in mcp.json; move it to Bitwarden and replace it with a variable."*

* **Restore / Setup Secondary PC**:
  > *"I'm on my second PC, apply the latest repo settings, install all skills and plugins, and pull my Bitwarden keys."*
