# backup.ps1: Exports local T3 and MCP configs to the repository
param (
    [switch]$Commit,
    [string]$Message = "Update T3 configs and markdown"
)

$ErrorActionPreference = "Stop"
$root = (Split-Path -Parent $PSScriptRoot)
$userDir = "$env:USERPROFILE\.t3\userdata"
$cursorDir = "$env:USERPROFILE\.cursor"

Write-Host "Backing up T3 configs from $userDir to $root\config..." -ForegroundColor Cyan

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
    Copy-Item "$cursorDir\mcp.json" "$root\config\mcp.json" -Force
    Write-Host "  [+] mcp.json (from ~/.cursor/mcp.json)"
}

Write-Host "Backup completed!" -ForegroundColor Green

if ($Commit) {
    Set-Location $root
    git add .
    git commit -m $Message
    Write-Host "Committed changes to git repository." -ForegroundColor Green
}
