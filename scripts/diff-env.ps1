# diff-env.ps1: Compares local active environment configurations against repository and Bitwarden secrets
param (
    [string]$SecretItemName = "t3-secrets",
    [switch]$CheckBitwarden
)

$ErrorActionPreference = "Continue"
$root = (Split-Path -Parent $PSScriptRoot)
$userDir = "$env:USERPROFILE\.t3\userdata"
$cursorDir = "$env:USERPROFILE\.cursor"
$geminiDir = "$env:USERPROFILE\.gemini\config"
$providersRoot = "$root\config\providers"

. "$PSScriptRoot\secret-utils.ps1"

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " T3 / Provider Environment Diff & Secret Inspection" -ForegroundColor Cyan
Write-Host " Hostname: $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host "=====================================================" -ForegroundColor Cyan

$hasDiffs = $false
$diffSummary = @()
$missedSecrets = @()

function Compare-ConfigJson {
    param (
        [string]$LocalPath,
        [string]$RepoPath,
        [string]$DisplayName
    )
    if (-not (Test-Path $LocalPath)) {
        if (Test-Path $RepoPath) {
            Write-Host "[-] $DisplayName is missing locally (exists in repo)." -ForegroundColor Yellow
            $script:hasDiffs = $true
            $script:diffSummary += "Missing local: $DisplayName"
        }
        return
    }
    if (-not (Test-Path $RepoPath)) {
        Write-Host "[+] $DisplayName is new locally (not tracked in repo)." -ForegroundColor Yellow
        $script:hasDiffs = $true
        $script:diffSummary += "New local: $DisplayName"
        return
    }

    $localRaw = Get-Content $LocalPath -Raw
    $repoRaw = Get-Content $RepoPath -Raw

    try {
        $localObj = $localRaw | ConvertFrom-Json
        $repoObj = $repoRaw | ConvertFrom-Json
        $localNorm = $localObj | ConvertTo-Json -Depth 10
        $repoNorm = $repoObj | ConvertTo-Json -Depth 10
        if ($localNorm -ne $repoNorm) {
            Write-Host "[*] Diff detected in $DisplayName" -ForegroundColor Yellow
            $script:hasDiffs = $true
            $script:diffSummary += "Modified: $DisplayName"
        } else {
            Write-Host "    [OK] $DisplayName matches repo" -ForegroundColor DarkGray
        }
    } catch {
        if ($localRaw.Trim() -ne $repoRaw.Trim()) {
            Write-Host "[*] Diff detected in $DisplayName (raw text)" -ForegroundColor Yellow
            $script:hasDiffs = $true
            $script:diffSummary += "Modified: $DisplayName"
        } else {
            Write-Host "    [OK] $DisplayName matches repo" -ForegroundColor DarkGray
        }
    }
}

function Scan-FileForSecrets {
    param (
        [string]$FilePath,
        [string]$DisplayName
    )
    if (-not (Test-Path $FilePath)) { return }
    $content = Get-Content $FilePath -Raw
    if (-not $content -or -not $content.Trim()) { return }

    try {
        $obj = $content | ConvertFrom-Json
        $script:currentFile = $DisplayName
        Find-SecretsInObject -Obj $obj -Context $DisplayName
    } catch {}
}

function Find-SecretsInObject {
    param (
        [object]$Obj,
        [string]$Context
    )
    if ($null -eq $Obj) { return }
    if ($Obj -is [System.Management.Automation.PSCustomObject] -or $Obj -is [System.Collections.IDictionary]) {
        $props = if ($Obj -is [System.Collections.IDictionary]) { $Obj.Keys } else { $Obj.PSObject.Properties.Name }
        foreach ($p in $props) {
            $v = if ($Obj -is [System.Collections.IDictionary]) { $Obj[$p] } else { $Obj.$p }
            if ($v -is [string] -and (Test-PotentialSecret -Key $p -Value $v)) {
                $script:missedSecrets += [PSCustomObject]@{
                    Location = "$Context.$p"
                    Key = $p
                    Length = $v.Length
                    Preview = "$($v.Substring(0, [Math]::Min(8, $v.Length)))..."
                }
            } elseif ($v -is [System.Management.Automation.PSCustomObject] -or $v -is [System.Collections.IDictionary] -or $v -is [System.Collections.IEnumerable] -and -not ($v -is [string])) {
                Find-SecretsInObject -Obj $v -Context "$Context.$p"
            }
        }
    } elseif ($Obj -is [System.Collections.IEnumerable] -and -not ($Obj -is [string])) {
        foreach ($item in $Obj) {
            Find-SecretsInObject -Obj $item -Context $Context
        }
    }
}

Write-Host "`n--- 1. Comparing Local vs. Repo Configs ---" -ForegroundColor Cyan
Compare-ConfigJson -LocalPath "$userDir\client-settings.json" -RepoPath "$root\config\client-settings.json" -DisplayName "client-settings.json"
Compare-ConfigJson -LocalPath "$userDir\keybindings.json" -RepoPath "$root\config\keybindings.json" -DisplayName "keybindings.json"
Compare-ConfigJson -LocalPath "$userDir\desktop-settings.json" -RepoPath "$root\config\desktop-settings.json" -DisplayName "desktop-settings.json"
Compare-ConfigJson -LocalPath "$cursorDir\mcp.json" -RepoPath "$root\config\mcp.json" -DisplayName "mcp.json (~/.cursor)"
Compare-ConfigJson -LocalPath "$geminiDir\config.json" -RepoPath "$providersRoot\gemini\config.json" -DisplayName "gemini/config.json"
Compare-ConfigJson -LocalPath "$geminiDir\mcp_config.json" -RepoPath "$providersRoot\gemini\mcp_config.json" -DisplayName "gemini/mcp_config.json"

Write-Host "`n--- 2. Scanning Local Environment for Missed / Hardcoded Secrets ---" -ForegroundColor Cyan
Scan-FileForSecrets -FilePath "$userDir\settings.json" -DisplayName "settings.json"
Scan-FileForSecrets -FilePath "$cursorDir\mcp.json" -DisplayName "mcp.json"
Scan-FileForSecrets -FilePath "$geminiDir\config.json" -DisplayName "gemini/config.json"
Scan-FileForSecrets -FilePath "$geminiDir\mcp_config.json" -DisplayName "gemini/mcp_config.json"

if ($missedSecrets.Count -gt 0) {
    Write-Host "[!] Found $($missedSecrets.Count) potential secret(s) in active local files:" -ForegroundColor Red
    foreach ($s in $missedSecrets) {
        Write-Host "    - $($s.Location) [Key: $($s.Key), Length: $($s.Length), Preview: $($s.Preview)]" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [OK] No unmasked secrets detected in local config files." -ForegroundColor Green
}

if ($CheckBitwarden) {
    Write-Host "`n--- 3. Verifying Bitwarden Vault Secrets ---" -ForegroundColor Cyan
    $sessionKey = Ensure-BitwardenSession
    if ($sessionKey) {
        try {
            $bwItem = bw get item $SecretItemName --session $sessionKey 2>$null | ConvertFrom-Json
            Write-Host "    [OK] Found Bitwarden item '$SecretItemName'." -ForegroundColor Green
            $keysInBw = @()
            if ($bwItem.fields) {
                foreach ($f in $bwItem.fields) { if ($f.name) { $keysInBw += $f.name } }
            }
            if ($bwItem.notes) {
                $trimmed = $bwItem.notes.Trim()
                if ($trimmed.StartsWith("{") -and $trimmed.EndsWith("}")) {
                    $jsonNotes = $trimmed | ConvertFrom-Json
                    foreach ($prop in $jsonNotes.PSObject.Properties) { $keysInBw += $prop.Name }
                }
            }
            Write-Host "    Vault contains $($keysInBw.Count) secret key(s): $($keysInBw -join ', ')" -ForegroundColor Gray
        } catch {
            Write-Host "    [-] Bitwarden item '$SecretItemName' not found or could not be read." -ForegroundColor Yellow
        }
    }
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
if ($hasDiffs) {
    Write-Host "Summary: Diffs detected ($($diffSummary -join ', '))" -ForegroundColor Yellow
} else {
    Write-Host "Summary: Local environment is fully in sync with repository." -ForegroundColor Green
}
Write-Host "=====================================================`n" -ForegroundColor Cyan
