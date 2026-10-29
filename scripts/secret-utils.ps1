# secret-utils.ps1: Helper functions for detecting secrets and interacting with Bitwarden CLI (bw)

function Test-PotentialSecret {
    param (
        [string]$Key,
        [string]$Value
    )
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    if ($Value.Length -lt 8) { return $false }

    # Patterns indicating secrets
    $secretKeyRegex = '(key|token|secret|password|auth|credential|access_token|api_key|bearer)'
    if ($Key -match $secretKeyRegex) {
        # Exclude common false positives
        if ($Value -notmatch '^(true|false|none|default|null|\d+)$' -and $Value -notmatch '^\${.+}' -and $Value -notmatch '^\{\{.+}}$') {
            return $true
        }
    }

    # Known token prefix patterns
    if ($Value -match '^(ghp_[A-Za-z0-9_]{20,}|AIza[0-9A-Za-z-_]{35}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[0-9A-Za-z]{10,})') {
        return $true
    }

    return $false
}

function Ensure-BitwardenSession {
    $bwCmd = Get-Command bw -ErrorAction SilentlyContinue
    if (-not $bwCmd) {
        Write-Host "Bitwarden CLI ('bw') is not installed." -ForegroundColor Yellow
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            Write-Host "Installing via Scoop..." -ForegroundColor Cyan
            scoop install bitwarden-cli
        } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Installing via Winget..." -ForegroundColor Cyan
            winget install --id Bitwarden.CLI -e --accept-source-agreements --accept-package-agreements
        } else {
            Write-Warning "Could not find or install 'bw'. Please install Bitwarden CLI manually."
            return $null
        }
    }

    $statusJson = bw status | ConvertFrom-Json
    if ($statusJson.status -eq "unauthenticated") {
        Write-Host "You are not logged in to Bitwarden. Please log in:" -ForegroundColor Yellow
        bw login
    }

    $sessionKey = $env:BW_SESSION
    if (-not $sessionKey -or ($statusJson.status -eq "locked")) {
        Write-Host "Unlocking Bitwarden vault..." -ForegroundColor Cyan
        $sessionKey = (bw unlock --raw)
        if (-not $sessionKey) {
            Write-Warning "Failed to unlock vault."
            return $null
        }
        $env:BW_SESSION = $sessionKey
    }

    bw sync --session $sessionKey | Out-Null
    return $sessionKey
}

function Add-SecretToBitwarden {
    param (
        [string]$Key,
        [string]$Value,
        [string]$ItemName = "t3-secrets"
    )

    $sessionKey = Ensure-BitwardenSession
    if (-not $sessionKey) {
        Write-Warning "No active Bitwarden session. Skipping auto-save to Bitwarden."
        return $false
    }

    # Retrieve existing item or create new
    $existingItem = $null
    try {
        $raw = bw get item $ItemName --session $sessionKey 2>$null
        if ($raw) {
            $existingItem = $raw | ConvertFrom-Json
        }
    } catch {
        $existingItem = $null
    }

    $notesDict = [ordered]@{}
    if ($existingItem -and $existingItem.notes) {
        $trimmedNotes = $existingItem.notes.Trim()
        if ($trimmedNotes.StartsWith("{") -and $trimmedNotes.EndsWith("}")) {
            try {
                $parsed = $trimmedNotes | ConvertFrom-Json
                foreach ($prop in $parsed.PSObject.Properties) {
                    $notesDict[$prop.Name] = [string]$prop.Value
                }
            } catch {}
        }
    }

    $notesDict[$Key] = $Value
    $newNotesText = $notesDict | ConvertTo-Json -Depth 5

    if ($existingItem) {
        $existingItem.notes = $newNotesText
        $payloadJson = $existingItem | ConvertTo-Json -Depth 10 -Compress
        $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payloadJson))
        bw edit item $existingItem.id $b64 --session $sessionKey | Out-Null
        Write-Host "  [+] Updated '$Key' in Bitwarden item '$ItemName'." -ForegroundColor Green
    } else {
        $newItem = [ordered]@{
            type = 2 # Secure Note
            name = $ItemName
            notes = $newNotesText
        }
        $payloadJson = $newItem | ConvertTo-Json -Depth 10 -Compress
        $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payloadJson))
        bw create item $b64 --session $sessionKey | Out-Null
        Write-Host "  [+] Created Bitwarden item '$ItemName' with '$Key'." -ForegroundColor Green
    }

    # Also update environment variable immediately for convenience
    [Environment]::SetEnvironmentVariable($Key, $Value, "User")
    [Environment]::SetEnvironmentVariable($Key, $Value, "Process")
    return $true
}

function Sanitize-ObjectSecrets {
    param (
        [object]$Obj,
        [string]$ContextName,
        [switch]$InteractivePrompt
    )

    if ($null -eq $Obj) { return $Obj }

    if ($Obj -is [System.Management.Automation.PSCustomObject] -or $Obj -is [System.Collections.IDictionary]) {
        $properties = if ($Obj -is [System.Collections.IDictionary]) { $Obj.Keys } else { $Obj.PSObject.Properties.Name }
        foreach ($propName in $properties) {
            $val = if ($Obj -is [System.Collections.IDictionary]) { $Obj[$propName] } else { $Obj.$propName }

            if ($val -is [string] -and (Test-PotentialSecret -Key $propName -Value $val)) {
                $masked = "${$propName}"
                Write-Host "`n[!] Detected potential secret: '$propName' in $ContextName" -ForegroundColor Yellow
                Write-Host "    Current value preview: $($val.Substring(0, [Math]::Min(8, $val.Length)))..." -ForegroundColor Gray

                if ($InteractivePrompt) {
                    $choice = Read-Host "Would you like to store '$propName' in Bitwarden and replace with '$masked'? (y/n)"
                    if ($choice -match '^(y|yes)$') {
                        Add-SecretToBitwarden -Key $propName -Value $val
                        if ($Obj -is [System.Collections.IDictionary]) {
                            $Obj[$propName] = $masked
                        } else {
                            $Obj.$propName = $masked
                        }
                    }
                }
            } elseif ($val -is [System.Management.Automation.PSCustomObject] -or $val -is [System.Collections.IDictionary] -or $val -is [System.Collections.IEnumerable] -and -not ($val -is [string])) {
                Sanitize-ObjectSecrets -Obj $val -ContextName "$ContextName.$propName" -InteractivePrompt:$InteractivePrompt
            }
        }
    } elseif ($Obj -is [System.Collections.IEnumerable] -and -not ($Obj -is [string])) {
        foreach ($item in $Obj) {
            Sanitize-ObjectSecrets -Obj $item -ContextName $ContextName -InteractivePrompt:$InteractivePrompt
        }
    }

    return $Obj
}
