# Lovelri — push all current changes to GitHub
# Right-click this file in File Explorer → "Run with PowerShell"
# (or open PowerShell, cd into the Lovelri folder, run: .\push.ps1)

$ErrorActionPreference = "Stop"

# Move into the script's folder so this works no matter how it's invoked
Set-Location -Path $PSScriptRoot

Write-Host ""
Write-Host "Lovelri → GitHub push" -ForegroundColor Cyan
Write-Host "──────────────────────────"

# Show what's about to be committed
Write-Host ""
Write-Host "Changes to be committed:" -ForegroundColor Yellow
git status --short

Write-Host ""
$msg = Read-Host "Commit message (press Enter for default)"
if ([string]::IsNullOrWhiteSpace($msg)) {
  $msg = "Update hub: bookings, leads, configurator with real ring photos, Sheets backend, redesigned Overview"
}

Write-Host ""
Write-Host "Staging files…" -ForegroundColor Cyan
git add .

Write-Host ""
Write-Host "Committing…" -ForegroundColor Cyan
git commit -m "$msg"

Write-Host ""
Write-Host "Pushing to origin…" -ForegroundColor Cyan
git push

Write-Host ""
Write-Host "✓ Done. Your repo at https://github.com/kairosennui/lovelri is up to date." -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
