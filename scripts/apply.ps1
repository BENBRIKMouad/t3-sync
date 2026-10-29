# apply.ps1: Applies repository configs to local T3 userdata, provider configs, and MCP configurations
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

# --- Apply Provider Configs (Gemini / Antigravity) ---
if (Test-Path "$providersRoot\gemini") {
    Write-Host "`nApplying Gemini / Antigravity configs..." -ForegroundColor Cyan
    if (!(Test-Path $geminiDir)) {
        New-Item -ItemType Directory -Path $geminiDir -Force | Out-Null
    }

    if (Test-Path "$providersRoot\gemini\config.json") {
        Copy-Item "$providersRoot\gemini\config.json" "$geminiDir\config.json" -Force
        Write-Host "  [Copied] gemini\config.json"
    }

    if (Test-Path "$providersRoot\gemini\mcp_config.json") {
        Copy-Item "$providersRoot\gemini\mcp_config.json" "$geminiDir\mcp_config.json" -Force
        Write-Host "  [Copied] gemini\mcp_config.json"
    }

    if (Test-Path "$providersRoot\gemini\projects") {
        $localProjectsDir = "$geminiDir\projects"
        if (!(Test-Path $localProjectsDir)) {
            New-Item -ItemType Directory -Path $localProjectsDir -Force | Out-Null
        }
        Get-ChildItem -Path "$providersRoot\gemini\projects\*.json" | ForEach-Object {
            Copy-Item $_.FullName "$localProjectsDir\$($_.Name)" -Force
            Write-Host "  [Copied] gemini\projects\$($_.Name)"
        }
    }
}

if ($SyncSecrets) {
    Write-Host "`nSyncing secrets from Bitwarden..." -ForegroundColor Cyan
    & "$PSScriptRoot\sync-secrets.ps1"
}

Write-Host "`nApply completed successfully! Restart T3 Code to ensure all settings take effect." -ForegroundColor Green
