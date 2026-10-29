# T3 Code Sync Repository (Method A)

This repository syncs your **T3 Code** UI configuration, keybindings, model preferences, custom skills, provider configs (e.g. Gemini / Antigravity), MCP servers, and agent instruction files between multiple machines without leaking credentials, tokens, or machine IDs.

---

## What is Synchronized

* **`config/client-settings.json`**: Appearance, theme, fonts, diff settings, floating browser configurations.
* **`config/keybindings.json`**: All custom keyboard shortcuts.
* **`config/desktop-settings.json`**: Window sizing and network/tailscale exposure modes.
* **`config/settings.template.json`**: Preferred models, favorites, and provider drivers (tokens and clerk credentials stripped).
* **`config/mcp.json`**: Global Model Context Protocol (MCP) server definitions with environment variable expansions (e.g., `${GITHUB_TOKEN}`).
* **`config/providers/gemini/`**: Complete Gemini & Antigravity provider configurations:
  * `config.json`: Execution policies, sandboxing, UI preferences, global permission grants, and installed marketplace/local **Plugins** (e.g. `chrome-devtools-plugin`, `flutter`, `modern-web-guidance-plugin`).
  * `mcp_config.json`: Gemini-specific MCP server definitions (e.g. Notion, etc.) with secret parameterization.
  * `skills/`: Custom & global agent skills synced to `~/.gemini/config/skills` and `~/.gemini/antigravity-cli/skills`.
  * `plugins/`: Custom plugins synced to `~/.gemini/config/plugins`.
  * `projects/*.json`: Registered projects and workspace definitions.
  * `skills.json` / `plugins.json`: Explicit customization manifests.
* **`instructions/`**: Canonical `AGENTS.md` and prompt rule templates.
* **`skills/`**: Shared agent skills (including the self-contained `t3-sync` skill).

---

## Smart Non-Destructive Merging

When synchronizing between multiple machines (e.g. Desktop & Laptop):
* **Plugins & Grants Merging**: `backup.ps1` and `apply.ps1` intelligently merge installed plugins and permission grants. Backing up from a machine that doesn't have a plugin yet will **not** clobber or remove plugins registered by another machine.
* **MCP Server Merging**: MCP servers defined across different hosts are merged additively into `mcp_config.json`.
* **Skills & Plugins Mirroring**: Skills and plugins from `config/providers/gemini/` are automatically deployed to local directories upon apply, keeping both machines in identical sync.

---

## Custom Agent Skill: `t3-sync`

This repository includes a built-in skill ([`skills/t3-sync/SKILL.md`](file:///C:/Users/mouad_benbrik/.t3/projects/t3-sync/skills/t3-sync/SKILL.md)) registered in `.agents/skills` and `.gemini/skills`. Whenever you are working in T3 Code or Gemini, you can ask the agent directly to:
* *"Compare my current environment with Git and Bitwarden"*
* *"Audit my configs for missed secrets"*
* *"Run git pull, backup my settings with host details, and commit & push"*
* *"Apply the latest repo settings and sync my Bitwarden keys"*

---

## Secret Detection & Bitwarden Integration

Whenever you back up your settings or provider configurations, `backup.ps1` and `diff-env.ps1` automatically scan for tokens, passwords, and API keys:

1. **Auto-Detection**: Scans JSON values for secret naming patterns (`key`, `token`, `secret`, `password`, `credential`) or prefix structures (`ghp_`, `sk-`, `AIza`, etc.).
2. **Interactive Prompt**: If a secret is detected:
   * It asks if you want to store it in your **Bitwarden Vault**.
   * It creates or updates the secret in your Bitwarden **`t3-secrets`** Secure Note.
   * It replaces the raw secret in the Git configuration file with an environment placeholder like `${KEY_NAME}`.
3. **Environment Synchronization**: Running `.\scripts\sync-secrets.ps1` extracts those secrets directly into Windows User Environment Variables so T3 Code and MCP servers can read them safely without hardcoded secrets in Git.

---

## Scripts & CLI Commands

### 1. Full Automated Synchronization (Recommended)
Always runs `git pull --rebase` first, compares local configs, audits for missed secrets, prompts before backup, and commits with hostname + changed files:
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
.\scripts\sync-all.ps1
```

### 2. Diff & Missed Secrets Inspection
Inspects differences between local configs, remote repo, and Bitwarden (including Gemini skills, plugins, configs, and MCPs):
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
.\scripts\diff-env.ps1 -CheckBitwarden
```

### 3. Backing Up Local Settings Individually
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
.\scripts\backup.ps1 -Commit
git push
```

### 4. Restoring on a New or Secondary Machine
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
git pull
# Copy mode:
.\scripts\apply.ps1 -SyncSecrets

# Or live symbolic links:
.\scripts\apply.ps1 -Symlink -SyncSecrets
```

### 5. Pulling Secrets from Bitwarden to Windows
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
.\scripts\sync-secrets.ps1
```
