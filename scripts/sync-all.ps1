# sync-all.ps1: Full synchronization pipeline (Git pull -> Diff & Secret Scan -> Backup & Commit -> Push)
param (
    [switch]$Force,
    [switch]$NoPush,
    [switch]$NoPrompt,
    [switch]$CheckBitwarden,
    [string]$CustomMessage
)

$ErrorActionPreference = "Stop"
$root = (Split-Path -Parent $PSScriptRoot)
$hostName = $env:COMPUTERNAME

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  T3 Sync: Full Synchronize Pipeline" -ForegroundColor Cyan
Write-Host "  Host: $hostName" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

# Step 1: Git Pull
Write-Host "`n[Step 1/4] Pulling latest changes from remote Git..." -ForegroundColor Cyan
Set-Location $root
try {
    git pull --rebase
} catch {
    Write-Warning "git pull encountered a notice or error. Check git status."
}

# Step 2: Environment Diff & Secret Check
Write-Host "`n[Step 2/4] Running Environment Diff and Secret Check..." -ForegroundColor Cyan
$diffParams = @{}
if ($CheckBitwarden) { $diffParams["CheckBitwarden"] = $true }
& "$PSScriptRoot\diff-env.ps1" @diffParams

# Step 3: Check whether to proceed with Backup
if (-not $Force -and -not $NoPrompt) {
    $confirm = Read-Host "Proceed with backup & commit for this host ($hostName)? (y/n)"
    if ($confirm -notmatch '^(y|yes)$') {
        Write-Host "Aborted by user. No backup performed." -ForegroundColor Yellow
        return
    }
}

# Step 4: Backup & Commit
Write-Host "`n[Step 3/4] Running Backup & Commit..." -ForegroundColor Cyan
$backupParams = @{ Commit = $true }
if ($CustomMessage) { $backupParams["Message"] = $CustomMessage }
if ($NoPrompt) { $backupParams["NoSecretPrompt"] = $true }

& "$PSScriptRoot\backup.ps1" @backupParams

# Step 5: Git Push
if (-not $NoPush) {
    Write-Host "`n[Step 4/4] Pushing changes to remote repository..." -ForegroundColor Cyan
    try {
        git push
        Write-Host "[OK] Successfully synced and pushed to remote Git!" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to push to remote. Please check network connection or git credentials."
    }
} else {
    Write-Host "`n[Step 4/4] Push skipped (-NoPush)." -ForegroundColor Yellow
}

Write-Host "`nAll operations completed successfully on $hostName!`n" -ForegroundColor Green
