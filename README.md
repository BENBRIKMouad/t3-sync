# T3 Code Sync Repository (Method A)

This repository syncs your **T3 Code** UI configuration, keybindings, model preferences, skills, MCP servers, and agent markdown instruction files between multiple machines and different accounts without clobbering account credentials or machine IDs.

---

## What is Synchronized

* **`config/client-settings.json`**: Appearance, theme, fonts, diff settings, floating browser configurations.
* **`config/keybindings.json`**: All custom keyboard shortcuts.
* **`config/desktop-settings.json`**: Window sizing and network/tailscale exposure modes.
* **`config/settings.template.json`**: Preferred models, favorites, and provider drivers (tokens and clerk credentials stripped).
* **`config/mcp.json`**: Global Model Context Protocol (MCP) server definitions with environment variable expansions (e.g., `${GITHUB_TOKEN}`).
* **`instructions/`**: Canonical `AGENTS.md` and prompt rule templates.
* **`skills/`**: Shared custom agent skills.

---

## Secret Management with Bitwarden Vault

Instead of keeping sensitive API tokens in plain text in Git, secrets are stored in your **Bitwarden Vault** and loaded directly into **Windows User Environment Variables**.

### Bitwarden Vault (`bw`) vs. Bitwarden Secrets Manager (`bws`)
* **Bitwarden Vault (`bw`)**: Part of standard Bitwarden accounts (Free & Premium). Uses items, logins, and Secure Notes in your personal vault. **This is what we use.**
* **Bitwarden Secrets Manager (`bws`)**: A separate enterprise developer product designed for CI/CD pipelines, machine accounts, and Kubernetes clusters requiring separate machine service access tokens.

### 1. Store Secrets in Bitwarden
1. In your Bitwarden Vault (Desktop app, mobile app, or browser extension), create a new **Secure Note** item.
2. Set the Name to: **`t3-secrets`**
3. Add your secrets using either:
   * **JSON in the Notes field**:
     ```json
     {
       "GITHUB_TOKEN": "ghp_xxxxxxxxxxxxxxxxxxxx",
       "BRAVE_API_KEY": "BSAxxxxxxxxxxxxxxxxxxxx"
     }
     ```
   * **Or Custom Fields**: Add Custom Hidden/Text fields with the variable name as the field name (e.g. `GITHUB_TOKEN`) and the token as the value.

### 2. Sync Secrets to Environment Variables
Run:
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
.\scripts\sync-secrets.ps1
```
* The script checks for `bw` (installs via `scoop` or `winget` if missing), unlocks your vault, reads `t3-secrets`, and applies each key to your **Windows User Environment** (`[Environment]::SetEnvironmentVariable`).
* MCP configurations in `config/mcp.json` automatically expand these variables (e.g. `"GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"`).

---

## Setup on a Remote / Secondary Machine

1. **Clone this repository** to the secondary machine:
   ```powershell
   git clone <YOUR-REMOTE-REPO-URL> "$env:USERPROFILE\.t3\projects\t3-sync"
   ```

2. **Apply configuration and sync secrets**:
   ```powershell
   cd "$env:USERPROFILE\.t3\projects\t3-sync"
   # To copy files, merge preferences, and sync Bitwarden secrets:
   .\scripts\apply.ps1 -SyncSecrets

   # Or, with live symbolic links:
   .\scripts\apply.ps1 -Symlink -SyncSecrets
   ```

3. **Restart T3 Code** on that machine.

---

## Workflow on this Main Machine

### Backing Up / Updating Settings
Whenever you change your keybindings, theme, MCP servers, or preferred models:

```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
.\scripts\backup.ps1 -Commit -Message "Update keybindings, MCPs, and UI settings"
git push
```

### Pulling Updates on Secondary Machine
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
git pull
.\scripts\apply.ps1
```
