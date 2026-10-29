# T3 Code Sync Repository (Method A)

This repository syncs your **T3 Code** UI configuration, keybindings, model preferences, skills, provider configs (e.g. Gemini / Antigravity), MCP servers, and agent instruction files between multiple machines without clobbering credentials, tokens, or machine IDs.

---

## What is Synchronized

* **`config/client-settings.json`**: Appearance, theme, fonts, diff settings, floating browser configurations.
* **`config/keybindings.json`**: All custom keyboard shortcuts.
* **`config/desktop-settings.json`**: Window sizing and network/tailscale exposure modes.
* **`config/settings.template.json`**: Preferred models, favorites, and provider drivers (tokens and clerk credentials stripped).
* **`config/mcp.json`**: Global Model Context Protocol (MCP) server definitions with environment variable expansions (e.g., `${GITHUB_TOKEN}`).
* **`config/providers/gemini/`**: Gemini & Antigravity provider configurations:
  * `config.json`: Execution policies, sandboxing, and UI width preferences.
  * `mcp_config.json`: Gemini-specific MCP configurations.
  * `projects/*.json`: Registered projects and workspace definitions.
* **`instructions/`**: Canonical `AGENTS.md` and prompt rule templates.
* **`skills/`**: Shared custom agent skills.

---

## Secret Detection & Bitwarden Integration

Whenever you back up your settings or provider configurations, `backup.ps1` automatically scans for tokens, passwords, and API keys:

1. **Auto-Detection**: Scans JSON values for secret naming patterns (`key`, `token`, `secret`, `password`, `auth`) or prefix structures (`ghp_`, `sk-`, `AIza`, etc.).
2. **Interactive Prompt**: If a secret is detected:
   * It asks if you want to store it in your **Bitwarden Vault**.
   * It creates or updates the secret in your Bitwarden **`t3-secrets`** Secure Note.
   * It replaces the raw secret in the Git configuration file with an environment placeholder like `${KEY_NAME}`.
3. **Environment Synchronization**: Running `.\scripts\sync-secrets.ps1` (or `.\scripts\apply.ps1 -SyncSecrets`) extracts those secrets directly into Windows User Environment Variables so T3 Code and MCP servers can read them safely without hardcoded secrets in Git.

---

## Bitwarden Vault Setup

* Create a **Secure Note** named **`t3-secrets`** in your Bitwarden Vault (if not already created by the backup prompt).
* You can add custom fields or place a JSON object in the note body:
  ```json
  {
    "GITHUB_TOKEN": "ghp_xxxxxxxxxxxxxxxxxxxx",
    "BRAVE_API_KEY": "BSAxxxxxxxxxxxxxxxxxxxx"
  }
  ```

---

## Usage Commands

### 1. Backing Up Local Settings (Main Machine)
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
.\scripts\backup.ps1 -Commit -Message "Sync T3 and Gemini provider settings"
git push
```

### 2. Restoring on a New or Secondary Machine
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
git pull
# Copy files, merge preferences, and sync Bitwarden secrets:
.\scripts\apply.ps1 -SyncSecrets

# Or use live symbolic links:
.\scripts\apply.ps1 -Symlink -SyncSecrets
```

### 3. Syncing Secrets Alone
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
.\scripts\sync-secrets.ps1
```
