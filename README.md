# T3 Code Sync Repository (Method A)

This repository syncs your **T3 Code** UI configuration, keybindings, model preferences, skills, and agent markdown instruction files between multiple machines and different accounts without clobbering account credentials or machine IDs.

---

## What is Synchronized

* **`config/client-settings.json`**: Appearance, theme, fonts, diff settings, floating browser configurations.
* **`config/keybindings.json`**: All custom keyboard shortcuts.
* **`config/desktop-settings.json`**: Window sizing and network/tailscale exposure modes.
* **`config/settings.template.json`**: Preferred models, favorites, and provider drivers (tokens and clerk credentials stripped).
* **`instructions/`**: Canonical `AGENTS.md` and prompt rule templates.
* **`skills/`**: Shared custom agent skills.

---

## Setup on a Remote / Secondary Machine

1. **Clone this repository** to the secondary machine:
   ```powershell
   git clone <YOUR-REMOTE-REPO-URL> "$env:USERPROFILE\.t3\projects\t3-sync"
   ```

2. **Apply the configuration**:
   ```powershell
   cd "$env:USERPROFILE\.t3\projects\t3-sync"
   # To copy files and merge model preferences:
   .\scripts\apply.ps1

   # Or, to create live symbolic links (requires Developer Mode or Administrator):
   .\scripts\apply.ps1 -Symlink
   ```

3. **Restart T3 Code** on that machine.

---

## Workflow on this Main Machine

### Backing Up / Updating Settings
Whenever you change your keybindings, theme, or preferred models in T3 Code and want to sync them:

```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
.\scripts\backup.ps1 -Commit -Message "Update keybindings and UI settings"
git push
```

### Pulling Updates on Secondary Machine
```powershell
cd "$env:USERPROFILE\.t3\projects\t3-sync"
git pull
.\scripts\apply.ps1
```
