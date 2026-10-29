# backup.ps1: Exports local T3, provider configs, skills, plugins, and MCP configs to the repository
param (
    [switch]$Commit,
    [string]$Message,
    [switch]$NoSecretPrompt
)

$ErrorActionPreference = "Stop"
$root = (Split-Path -Parent $PSScriptRoot)
$userDir = "$env:USERPROFILE\.t3\userdata"
$cursorDir = "$env:USERPROFILE\.cursor"
$geminiDir = "$env:USERPROFILE\.gemini\config"
$providersRoot = "$root\config\providers"
$hostName = $env:COMPUTERNAME
$promptToStore = -not $NoSecretPrompt

# Load secret scanning and Bitwarden helpers
. "$PSScriptRoot\secret-utils.ps1"

function Copy-DirectorySafely {
    param (
        [string]$SourceDir,
        [string]$TargetDir
    )
    if (!(Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    Copy-Item -Path "$SourceDir\*" -Destination $TargetDir -Recurse -Force
}

Write-Host "Backing up T3 configs from $userDir to $root\config (Host: $hostName)..." -ForegroundColor Cyan

if (Test-Path "$userDir\client-settings.json") {
    Copy-Item "$userDir\client-settings.json" "$root\config\client-settings.json" -Force
    Write-Host "  [+] client-settings.json"
}

if (Test-Path "$userDir\keybindings.json") {
    Copy-Item "$userDir\keybindings.json" "$root\config\keybindings.json" -Force
    Write-Host "  [+] keybindings.json"
}

if (Test-Path "$userDir\desktop-settings.json") {
    Copy-Item "$userDir\desktop-settings.json" "$root\config\desktop-settings.json" -Force
    Write-Host "  [+] desktop-settings.json"
}

if (Test-Path "$userDir\settings.json") {
    $settings = Get-Content "$userDir\settings.json" -Raw | ConvertFrom-Json
    if ($settings.sourceControlHosts) {
        $settings.sourceControlHosts = [PSCustomObject]@{}
    }
    $settings | ConvertTo-Json -Depth 10 | Set-Content "$root\config\settings.template.json" -Encoding UTF8
    Write-Host "  [+] settings.template.json (sanitized)"
}

if (Test-Path "$cursorDir\mcp.json") {
    $mcpContent = Get-Content "$cursorDir\mcp.json" -Raw | ConvertFrom-Json
    Sanitize-ObjectSecrets -Obj $mcpContent -ContextName "mcp.json" -InteractivePrompt:$promptToStore | Out-Null
    $mcpContent | ConvertTo-Json -Depth 10 | Set-Content "$root\config\mcp.json" -Encoding UTF8
    Write-Host "  [+] mcp.json (from ~/.cursor/mcp.json)"
}

# --- Provider Configs Backup (Gemini / Antigravity) ---
Write-Host "`nBacking up Provider configs (Gemini / Antigravity: configs, skills, plugins, MCPs)..." -ForegroundColor Cyan
if (Test-Path $geminiDir) {
    $geminiTarget = "$providersRoot\gemini"
    if (!(Test-Path $geminiTarget)) {
        New-Item -ItemType Directory -Path $geminiTarget -Force | Out-Null
    }

    # 1. Backup & Smart Merge config.json (including plugins & permissions)
    $repoConfigPath = "$geminiTarget\config.json"
    $localConfigPath = "$geminiDir\config.json"
    if (Test-Path $localConfigPath) {
        $gConfig = Get-Content $localConfigPath -Raw | ConvertFrom-Json
        
        # Merge with existing repo config to prevent losing plugins or permissions from other machines
        if (Test-Path $repoConfigPath) {
            try {
                $repoConfig = Get-Content $repoConfigPath -Raw | ConvertFrom-Json
                
                # Merge plugins: preserve plugins from repo if missing locally
                if ($repoConfig.plugins) {
                    if (-not $gConfig.plugins) {
                        $gConfig | Add-Member -NotePropertyName "plugins" -NotePropertyValue ([PSCustomObject]@{})
                    }
                    foreach ($p in $repoConfig.plugins.PSObject.Properties) {
                        if (-not $gConfig.plugins.PSObject.Properties[$p.Name]) {
                            $gConfig.plugins | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value
                        }
                    }
                }
                
                # Merge globalPermissionGrants: union allow list
                if ($repoConfig.userSettings.globalPermissionGrants.allow) {
                    if (-not $gConfig.userSettings) {
                        $gConfig | Add-Member -NotePropertyName "userSettings" -NotePropertyValue ([PSCustomObject]@{})
                    }
                    if (-not $gConfig.userSettings.globalPermissionGrants) {
                        $gConfig.userSettings | Add-Member -NotePropertyName "globalPermissionGrants" -NotePropertyValue ([PSCustomObject]@{})
                    }
                    $existingAllow = @($gConfig.userSettings.globalPermissionGrants.allow)
                    foreach ($grant in $repoConfig.userSettings.globalPermissionGrants.allow) {
                        if ($existingAllow -notcontains $grant) {
                            $existingAllow += $grant
                        }
                    }
                    $gConfig.userSettings.globalPermissionGrants.allow = $existingAllow
                }
            } catch {
                Write-Warning "Could not parse existing repo config.json during merge: $_"
            }
        }

        Sanitize-ObjectSecrets -Obj $gConfig -ContextName "gemini/config.json" -InteractivePrompt:$promptToStore | Out-Null
        $gConfig | ConvertTo-Json -Depth 10 | Set-Content $repoConfigPath -Encoding UTF8
        Write-Host "  [+] gemini/config.json (merged plugins & settings)"
    }

    # 2. Backup & Smart Merge mcp_config.json
    $repoMcpPath = "$geminiTarget\mcp_config.json"
    $localMcpPath = "$geminiDir\mcp_config.json"
    $mergedMcpServers = [ordered]@{}

    if (Test-Path $repoMcpPath) {
        $repoRaw = Get-Content $repoMcpPath -Raw
        if ($repoRaw -and $repoRaw.Trim()) {
            try {
                $repoMcp = $repoRaw | ConvertFrom-Json
                if ($repoMcp.mcpServers) {
                    foreach ($s in $repoMcp.mcpServers.PSObject.Properties) {
                        $mergedMcpServers[$s.Name] = $s.Value
                    }
                }
            } catch {}
        }
    }

    if (Test-Path $localMcpPath) {
        $localRaw = Get-Content $localMcpPath -Raw
        if ($localRaw -and $localRaw.Trim()) {
            try {
                $localMcp = $localRaw | ConvertFrom-Json
                if ($localMcp.mcpServers) {
                    foreach ($s in $localMcp.mcpServers.PSObject.Properties) {
                        $mergedMcpServers[$s.Name] = $s.Value
                    }
                }
            } catch {}
        }
    }

    if ($mergedMcpServers.Keys.Count -gt 0) {
        $mcpObj = [PSCustomObject]@{ mcpServers = [PSCustomObject]$mergedMcpServers }
        Sanitize-ObjectSecrets -Obj $mcpObj -ContextName "gemini/mcp_config.json" -InteractivePrompt:$promptToStore | Out-Null
        $mcpObj | ConvertTo-Json -Depth 10 | Set-Content $repoMcpPath -Encoding UTF8
        Write-Host "  [+] gemini/mcp_config.json (merged $($mergedMcpServers.Keys.Count) servers: $($mergedMcpServers.Keys -join ', '))"
    }

    # 3. Backup Skills (~/.gemini/config/skills -> config/providers/gemini/skills)
    $geminiSkillsDir = "$geminiDir\skills"
    $skillsTarget = "$geminiTarget\skills"
    if (!(Test-Path $skillsTarget)) {
        New-Item -ItemType Directory -Path $skillsTarget -Force | Out-Null
    }
    $repoRootSkills = "$root\skills"
    if (Test-Path $repoRootSkills) {
        Get-ChildItem -Path $repoRootSkills -Directory | ForEach-Object {
            $dest = "$skillsTarget\$($_.Name)"
            if (!(Test-Path $dest)) {
                Copy-DirectorySafely -SourceDir $_.FullName -TargetDir $dest
            }
        }
    }
    if (Test-Path $geminiSkillsDir) {
        Get-ChildItem -Path $geminiSkillsDir -Directory | ForEach-Object {
            $dest = "$skillsTarget\$($_.Name)"
            Copy-DirectorySafely -SourceDir $_.FullName -TargetDir $dest
            Write-Host "  [+] gemini/skills/$($_.Name)"
            # Mirror to repo root skills as well
            if (Test-Path $repoRootSkills) {
                Copy-DirectorySafely -SourceDir $_.FullName -TargetDir "$repoRootSkills\$($_.Name)"
            }
        }
    }

    # 4. Backup Plugins (~/.gemini/config/plugins -> config/providers/gemini/plugins)
    $geminiPluginsDir = "$geminiDir\plugins"
    $pluginsTarget = "$geminiTarget\plugins"
    if (!(Test-Path $pluginsTarget)) {
        New-Item -ItemType Directory -Path $pluginsTarget -Force | Out-Null
    }
    if (Test-Path $geminiPluginsDir) {
        Get-ChildItem -Path $geminiPluginsDir -Directory | ForEach-Object {
            $dest = "$pluginsTarget\$($_.Name)"
            Copy-DirectorySafely -SourceDir $_.FullName -TargetDir $dest
            Write-Host "  [+] gemini/plugins/$($_.Name)"
        }
    }

    # 5. Backup Explicit Customization Manifests (skills.json / plugins.json)
    foreach ($mFile in @("skills.json", "plugins.json")) {
        if (Test-Path "$geminiDir\$mFile") {
            Copy-Item "$geminiDir\$mFile" "$geminiTarget\$mFile" -Force
            Write-Host "  [+] gemini/$mFile"
        }
    }

    # 6. Backup project definitions (projects/*.json)
    if (Test-Path "$geminiDir\projects") {
        $projTarget = "$geminiTarget\projects"
        if (!(Test-Path $projTarget)) {
            New-Item -ItemType Directory -Path $projTarget -Force | Out-Null
        }
        Get-ChildItem -Path "$geminiDir\projects\*.json" | ForEach-Object {
            Copy-Item $_.FullName "$projTarget\$($_.Name)" -Force
            Write-Host "  [+] gemini/projects/$($_.Name)"
        }
    }
}

Write-Host "`nBackup completed!" -ForegroundColor Green

if ($Commit) {
    Set-Location $root
    $statusLines = (git status --porcelain)
    if (-not $statusLines) {
        Write-Host "No changes detected to commit." -ForegroundColor Yellow
        return
    }

    # Determine changed files
    $changedList = @()
    foreach ($line in $statusLines) {
        $f = $line.Substring(3).Trim()
        $changedList += [System.IO.Path]::GetFileName($f)
    }
    $changedSummary = ($changedList | Select-Object -Unique) -join ", "

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $commitMsg = "sync($hostName): update $changedSummary [source: $hostName]"
    } else {
        $commitMsg = "$Message [source: $hostName | changed: $changedSummary]"
    }

    git add .
    git commit -m $commitMsg
    Write-Host "Committed changes to git repository: '$commitMsg'" -ForegroundColor Green
}
