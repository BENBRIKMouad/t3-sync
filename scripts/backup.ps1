# backup.ps1: Exports local T3, provider configs, and MCP configs to the repository
param (
    [switch]$Commit,
    [string]$Message,
    [switch]$PromptToStoreSecrets = $true
)

$ErrorActionPreference = "Stop"
$root = (Split-Path -Parent $PSScriptRoot)
$userDir = "$env:USERPROFILE\.t3\userdata"
$cursorDir = "$env:USERPROFILE\.cursor"
$geminiDir = "$env:USERPROFILE\.gemini\config"
$providersRoot = "$root\config\providers"
$hostName = $env:COMPUTERNAME

# Load secret scanning and Bitwarden helpers
. "$PSScriptRoot\secret-utils.ps1"

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
    Sanitize-ObjectSecrets -Obj $mcpContent -ContextName "mcp.json" -InteractivePrompt:$PromptToStoreSecrets | Out-Null
    $mcpContent | ConvertTo-Json -Depth 10 | Set-Content "$root\config\mcp.json" -Encoding UTF8
    Write-Host "  [+] mcp.json (from ~/.cursor/mcp.json)"
}

# --- Provider Configs Backup (e.g. Gemini / Antigravity) ---
Write-Host "`nBacking up Provider configs (Gemini / Antigravity)..." -ForegroundColor Cyan
if (Test-Path $geminiDir) {
    $geminiTarget = "$providersRoot\gemini"
    if (!(Test-Path $geminiTarget)) {
        New-Item -ItemType Directory -Path $geminiTarget -Force | Out-Null
    }

    # Backup config.json (scan and sanitize secrets)
    if (Test-Path "$geminiDir\config.json") {
        $gConfig = Get-Content "$geminiDir\config.json" -Raw | ConvertFrom-Json
        Sanitize-ObjectSecrets -Obj $gConfig -ContextName "gemini/config.json" -InteractivePrompt:$PromptToStoreSecrets | Out-Null
        $gConfig | ConvertTo-Json -Depth 10 | Set-Content "$geminiTarget\config.json" -Encoding UTF8
        Write-Host "  [+] gemini/config.json"
    }

    # Backup mcp_config.json if present
    if (Test-Path "$geminiDir\mcp_config.json") {
        $mcpG = Get-Content "$geminiDir\mcp_config.json" -Raw
        if ($mcpG -and $mcpG.Trim()) {
            try {
                $mcpObj = $mcpG | ConvertFrom-Json
                Sanitize-ObjectSecrets -Obj $mcpObj -ContextName "gemini/mcp_config.json" -InteractivePrompt:$PromptToStoreSecrets | Out-Null
                $mcpObj | ConvertTo-Json -Depth 10 | Set-Content "$geminiTarget\mcp_config.json" -Encoding UTF8
            } catch {
                Copy-Item "$geminiDir\mcp_config.json" "$geminiTarget\mcp_config.json" -Force
            }
        } else {
            Set-Content "$geminiTarget\mcp_config.json" "" -Encoding UTF8
        }
        Write-Host "  [+] gemini/mcp_config.json"
    }

    # Backup project definitions (projects/*.json)
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
