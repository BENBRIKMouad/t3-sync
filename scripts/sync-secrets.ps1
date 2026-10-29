# sync-secrets.ps1: Fetches secrets from Bitwarden Vault and sets them as User Environment Variables
param (
    [string]$ItemName = "t3-secrets"
)

$ErrorActionPreference = "Stop"

# 1. Verify Bitwarden CLI (bw) is installed
$bwCmd = Get-Command bw -ErrorAction SilentlyContinue
if (-not $bwCmd) {
    Write-Host "Bitwarden CLI ('bw') is not installed." -ForegroundColor Yellow
    Write-Host "Attempting installation via Scoop or Winget..." -ForegroundColor Cyan
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop install bitwarden-cli
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Bitwarden.CLI -e --accept-source-agreements --accept-package-agreements
    } else {
        Write-Error "Please install Bitwarden CLI ('scoop install bitwarden-cli' or 'npm install -g @bitwarden/cli') and re-run."
        return
    }
}

# 2. Check Bitwarden login / vault status
Write-Host "Checking Bitwarden vault status..." -ForegroundColor Cyan
$statusJson = bw status | ConvertFrom-Json
if ($statusJson.status -eq "unauthenticated") {
    Write-Host "You are not logged in to Bitwarden. Please log in:" -ForegroundColor Yellow
    bw login
}

# 3. Unlock vault to obtain session key
$sessionKey = $env:BW_SESSION
if (-not $sessionKey -or ($statusJson.status -eq "locked")) {
    Write-Host "Unlocking Bitwarden vault..." -ForegroundColor Cyan
    $sessionKey = (bw unlock --raw)
    if (-not $sessionKey) {
        Write-Error "Failed to unlock vault."
        return
    }
    $env:BW_SESSION = $sessionKey
}

Write-Host "Syncing latest Bitwarden vault state..." -ForegroundColor Cyan
bw sync --session $sessionKey | Out-Null

# 4. Retrieve secret item
Write-Host "Retrieving item '$ItemName' from Bitwarden..." -ForegroundColor Cyan
try {
    $itemRaw = bw get item $ItemName --session $sessionKey
    $item = $itemRaw | ConvertFrom-Json
} catch {
    Write-Host "`n[!] Could not find an item named '$ItemName' in your Bitwarden vault." -ForegroundColor Red
    Write-Host "To fix this:" -ForegroundColor Yellow
    Write-Host "  1. Open your Bitwarden Vault."
    Write-Host "  2. Create a Secure Note named '$ItemName'."
    Write-Host "  3. Add your secrets in Custom Fields or as JSON in the note body, for example:"
    Write-Host '     {"GITHUB_TOKEN": "ghp_xxx", "BRAVE_API_KEY": "xxx"}'
    Write-Host "  4. Re-run this script.`n"
    return
}

$secrets = @{}

# A. Extract custom fields if any exist
if ($item.fields) {
    foreach ($field in $item.fields) {
        if ($field.name -and $field.value) {
            $secrets[$field.name] = [string]$field.value
        }
    }
}

# B. Extract notes content (supports JSON or KEY=VALUE lines)
if ($item.notes) {
    $noteText = $item.notes.Trim()
    if ($noteText.StartsWith("{") -and $noteText.EndsWith("}")) {
        try {
            $jsonNotes = $noteText | ConvertFrom-Json
            foreach ($prop in $jsonNotes.PSObject.Properties) {
                $secrets[$prop.Name] = [string]$prop.Value
            }
        } catch {
            Write-Warning "Notes content looked like JSON but failed to parse."
        }
    } else {
        # Parse KEY=VALUE lines
        $lines = $noteText -split "`r?`n"
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -and -not $trimmed.StartsWith("#") -and $trimmed.Contains("=")) {
                $parts = $trimmed.Split("=", 2)
                $k = $parts[0].Trim()
                $v = $parts[1].Trim()
                if ($k) {
                    $secrets[$k] = $v
                }
            }
        }
    }
}

if ($secrets.Count -eq 0) {
    Write-Warning "No secret keys found in '$ItemName'. Add custom fields or JSON / KEY=VALUE pairs in notes."
    return
}

# 5. Apply variables to Windows User and Process environment
Write-Host "`nSetting User Environment Variables:" -ForegroundColor Green
foreach ($key in $secrets.Keys) {
    $val = $secrets[$key]
    [Environment]::SetEnvironmentVariable($key, $val, "User")
    [Environment]::SetEnvironmentVariable($key, $val, "Process")
    Write-Host "  [+] $key (length: $($val.Length) chars)" -ForegroundColor Green
}

Write-Host "`nSecrets synchronized successfully!" -ForegroundColor Green
Write-Host "NOTE: Running applications (like T3 Code or terminals) must be restarted to detect new User environment variables." -ForegroundColor Yellow
