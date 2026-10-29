# apply.ps1: Applies repository configs to local T3 userdata, provider configs, skills, plugins, and MCP configurations
param (
    [switch]$Symlink,
    [switch]$SyncSecrets
)

$ErrorActionPreference = "Stop"
$root = (Split-Path -Parent $PSScriptRoot)
$userDir = "$env:USERPROFILE\.t3\userdata"
$cursorDir = "$env:USERPROFILE\.cursor"
$geminiDir = "$env:USERPROFILE\.gemini\config"
$providersRoot = "$root\config\providers"
$geminiTarget = "$providersRoot\gemini"

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

if (!(Test-Path $userDir)) {
    New-Item -ItemType Directory -Path $userDir -Force | Out-Null
}

Write-Host "Applying T3 configs to $userDir..." -ForegroundColor Cyan

if ($Symlink) {
    Write-Host "Creating symbolic links (requires Dev Mode or Admin privileges)..." -ForegroundColor Yellow
    if (Test-Path "$userDir\client-settings.json") { Remove-Item "$userDir\client-settings.json" -Force }
    New-Item -ItemType SymbolicLink -Path "$userDir\client-settings.json" -Target "$root\config\client-settings.json" -Force | Out-Null
    Write-Host "  [Linked] client-settings.json"

    if (Test-Path "$userDir\keybindings.json") { Remove-Item "$userDir\keybindings.json" -Force }
    New-Item -ItemType SymbolicLink -Path "$userDir\keybindings.json" -Target "$root\config\keybindings.json" -Force | Out-Null
    Write-Host "  [Linked] keybindings.json"

    if (Test-Path "$userDir\desktop-settings.json") { Remove-Item "$userDir\desktop-settings.json" -Force }
    New-Item -ItemType SymbolicLink -Path "$userDir\desktop-settings.json" -Target "$root\config\desktop-settings.json" -Force | Out-Null
    Write-Host "  [Linked] desktop-settings.json"

    if (Test-Path "$root\config\mcp.json") {
        if (!(Test-Path $cursorDir)) { New-Item -ItemType Directory -Path $cursorDir -Force | Out-Null }
        if (Test-Path "$cursorDir\mcp.json") { Remove-Item "$cursorDir\mcp.json" -Force }
        New-Item -ItemType SymbolicLink -Path "$cursorDir\mcp.json" -Target "$root\config\mcp.json" -Force | Out-Null
        Write-Host "  [Linked] mcp.json -> ~/.cursor/mcp.json"
    }
} else {
    Write-Host "Copying configuration files..."
    Copy-Item "$root\config\client-settings.json" "$userDir\client-settings.json" -Force
    Write-Host "  [Copied] client-settings.json"

    Copy-Item "$root\config\keybindings.json" "$userDir\keybindings.json" -Force
    Write-Host "  [Copied] keybindings.json"

    Copy-Item "$root\config\desktop-settings.json" "$userDir\desktop-settings.json" -Force
    Write-Host "  [Copied] desktop-settings.json"

    if (Test-Path "$root\config\mcp.json") {
        if (!(Test-Path $cursorDir)) { New-Item -ItemType Directory -Path $cursorDir -Force | Out-Null }
        Copy-Item "$root\config\mcp.json" "$cursorDir\mcp.json" -Force
        Write-Host "  [Copied] mcp.json -> ~/.cursor/mcp.json"
    }
}

if (Test-Path "$root\config\settings.template.json") {
    $template = Get-Content "$root\config\settings.template.json" -Raw | ConvertFrom-Json
    if (Test-Path "$userDir\settings.json") {
        $existing = Get-Content "$userDir\settings.json" -Raw | ConvertFrom-Json
        if ($template.favorites) { $existing.favorites = $template.favorites }
        if ($template.providerModelPreferences) { $existing.providerModelPreferences = $template.providerModelPreferences }
        if ($template.defaultModelSelection) { $existing.defaultModelSelection = $template.defaultModelSelection }
        $existing | ConvertTo-Json -Depth 10 | Set-Content "$userDir\settings.json" -Encoding UTF8
        Write-Host "  [Merged] preferences into settings.json (preserved local auth tokens)"
    } else {
        Copy-Item "$root\config\settings.template.json" "$userDir\settings.json" -Force
        Write-Host "  [Created] settings.json from template"
    }
}

# --- Apply Provider Configs (Gemini / Antigravity: configs, skills, plugins, MCPs) ---
if (Test-Path $geminiTarget) {
    Write-Host "`nApplying Gemini / Antigravity configs..." -ForegroundColor Cyan
    if (!(Test-Path $geminiDir)) {
        New-Item -ItemType Directory -Path $geminiDir -Force | Out-Null
    }

    # 1. Merge config.json (preserve local machine settings while adopting repo plugins & permissions)
    if (Test-Path "$geminiTarget\config.json") {
        $repoCfg = Get-Content "$geminiTarget\config.json" -Raw | ConvertFrom-Json
        if (Test-Path "$geminiDir\config.json") {
            try {
                $localCfg = Get-Content "$geminiDir\config.json" -Raw | ConvertFrom-Json
                
                # Merge plugins into local
                if ($repoCfg.plugins) {
                    if (-not $localCfg.plugins) {
                        $localCfg | Add-Member -NotePropertyName "plugins" -NotePropertyValue ([PSCustomObject]@{})
                    }
                    foreach ($p in $repoCfg.plugins.PSObject.Properties) {
                        if (-not $localCfg.plugins.PSObject.Properties[$p.Name]) {
                            $localCfg.plugins | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value
                        }
                    }
                }
                
                # Merge globalPermissionGrants
                if ($repoCfg.userSettings.globalPermissionGrants.allow) {
                    if (-not $localCfg.userSettings) {
                        $localCfg | Add-Member -NotePropertyName "userSettings" -NotePropertyValue ([PSCustomObject]@{})
                    }
                    if (-not $localCfg.userSettings.globalPermissionGrants) {
                        $localCfg.userSettings | Add-Member -NotePropertyName "globalPermissionGrants" -NotePropertyValue ([PSCustomObject]@{})
                    }
                    $allowList = @($localCfg.userSettings.globalPermissionGrants.allow)
                    foreach ($grant in $repoCfg.userSettings.globalPermissionGrants.allow) {
                        if ($allowList -notcontains $grant) {
                            $allowList += $grant
                        }
                    }
                    $localCfg.userSettings.globalPermissionGrants.allow = $allowList
                }
                
                $localCfg | ConvertTo-Json -Depth 10 | Set-Content "$geminiDir\config.json" -Encoding UTF8
                Write-Host "  [Merged] gemini/config.json (merged plugins & permission grants into local)"
            } catch {
                Copy-Item "$geminiTarget\config.json" "$geminiDir\config.json" -Force
                Write-Host "  [Copied] gemini/config.json"
            }
        } else {
            Copy-Item "$geminiTarget\config.json" "$geminiDir\config.json" -Force
            Write-Host "  [Copied] gemini/config.json"
        }
    }

    # 2. Merge mcp_config.json
    if (Test-Path "$geminiTarget\mcp_config.json") {
        $repoMcpRaw = Get-Content "$geminiTarget\mcp_config.json" -Raw
        if ($repoMcpRaw -and $repoMcpRaw.Trim()) {
            try {
                $repoMcp = $repoMcpRaw | ConvertFrom-Json
                $localMcpPath = "$geminiDir\mcp_config.json"
                $localServers = [ordered]@{}
                if (Test-Path $localMcpPath) {
                    $localRaw = Get-Content $localMcpPath -Raw
                    if ($localRaw -and $localRaw.Trim()) {
                        $localObj = $localRaw | ConvertFrom-Json
                        if ($localObj.mcpServers) {
                            foreach ($p in $localObj.mcpServers.PSObject.Properties) {
                                $localServers[$p.Name] = $p.Value
                            }
                        }
                    }
                }
                if ($repoMcp.mcpServers) {
                    foreach ($p in $repoMcp.mcpServers.PSObject.Properties) {
                        $localServers[$p.Name] = $p.Value
                    }
                }
                $mergedLocalObj = [PSCustomObject]@{ mcpServers = [PSCustomObject]$localServers }
                $mergedLocalObj | ConvertTo-Json -Depth 10 | Set-Content $localMcpPath -Encoding UTF8
                Write-Host "  [Merged] gemini/mcp_config.json ($($localServers.Keys.Count) servers configured: $($localServers.Keys -join ', '))"
            } catch {
                Copy-Item "$geminiTarget\mcp_config.json" "$geminiDir\mcp_config.json" -Force
                Write-Host "  [Copied] gemini/mcp_config.json"
            }
        }
    }

    # 3. Apply Skills to ~/.gemini/config/skills & ~/.gemini/antigravity-cli/skills
    $localSkillsDir = "$geminiDir\skills"
    if (!(Test-Path $localSkillsDir)) {
        New-Item -ItemType Directory -Path $localSkillsDir -Force | Out-Null
    }
    $cliSkillsDir = "$env:USERPROFILE\.gemini\antigravity-cli\skills"
    if (!(Test-Path $cliSkillsDir)) {
        New-Item -ItemType Directory -Path $cliSkillsDir -Force | Out-Null
    }

    # Copy from repo gemini skills target and repo root skills
    $sources = @("$geminiTarget\skills", "$root\skills")
    foreach ($sDir in $sources) {
        if (Test-Path $sDir) {
            Get-ChildItem -Path $sDir -Directory | ForEach-Object {
                $dest = "$localSkillsDir\$($_.Name)"
                Copy-DirectorySafely -SourceDir $_.FullName -TargetDir $dest
                Copy-DirectorySafely -SourceDir $_.FullName -TargetDir "$cliSkillsDir\$($_.Name)"
                Write-Host "  [Installed Skill] $($_.Name) -> ~/.gemini/config/skills"
            }
        }
    }

    # 4. Apply Plugins to ~/.gemini/config/plugins
    $localPluginsDir = "$geminiDir\plugins"
    if (!(Test-Path $localPluginsDir)) {
        New-Item -ItemType Directory -Path $localPluginsDir -Force | Out-Null
    }
    if (Test-Path "$geminiTarget\plugins") {
        Get-ChildItem -Path "$geminiTarget\plugins" -Directory | ForEach-Object {
            $dest = "$localPluginsDir\$($_.Name)"
            Copy-DirectorySafely -SourceDir $_.FullName -TargetDir $dest
            Write-Host "  [Installed Plugin] $($_.Name) -> ~/.gemini/config/plugins"
        }
    }

    # 5. Apply Manifests (skills.json / plugins.json)
    foreach ($mFile in @("skills.json", "plugins.json")) {
        if (Test-Path "$geminiTarget\$mFile") {
            Copy-Item "$geminiTarget\$mFile" "$geminiDir\$mFile" -Force
            Write-Host "  [Copied] gemini/$mFile"
        }
    }

    # 6. Apply Project Definitions
    if (Test-Path "$geminiTarget\projects") {
        $localProjectsDir = "$geminiDir\projects"
        if (!(Test-Path $localProjectsDir)) {
            New-Item -ItemType Directory -Path $localProjectsDir -Force | Out-Null
        }
        Get-ChildItem -Path "$geminiTarget\projects\*.json" | ForEach-Object {
            Copy-Item $_.FullName "$localProjectsDir\$($_.Name)" -Force
            Write-Host "  [Copied] gemini/projects/$($_.Name)"
        }
    }
}

if ($SyncSecrets) {
    Write-Host "`nSyncing secrets from Bitwarden..." -ForegroundColor Cyan
    & "$PSScriptRoot\sync-secrets.ps1"
}

Write-Host "`nApply completed successfully! Restart T3 Code to ensure all settings take effect." -ForegroundColor Green
