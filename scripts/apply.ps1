# apply.ps1: Applies repository configs to local T3 userdata directory
param (
    [switch]$Symlink
)

$ErrorActionPreference = "Stop"
$root = (Split-Path -Parent $PSScriptRoot)
$userDir = "$env:USERPROFILE\.t3\userdata"

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
} else {
    Write-Host "Copying configuration files..."
    Copy-Item "$root\config\client-settings.json" "$userDir\client-settings.json" -Force
    Write-Host "  [Copied] client-settings.json"

    Copy-Item "$root\config\keybindings.json" "$userDir\keybindings.json" -Force
    Write-Host "  [Copied] keybindings.json"

    Copy-Item "$root\config\desktop-settings.json" "$userDir\desktop-settings.json" -Force
    Write-Host "  [Copied] desktop-settings.json"
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

Write-Host "Apply completed successfully! Restart T3 Code to ensure all settings take effect." -ForegroundColor Green
