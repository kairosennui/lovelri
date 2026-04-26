# Lovelri — move ring photos from Downloads into Lovelri/rings/
# Run by right-clicking this file in File Explorer and choosing "Run with PowerShell".
# If Windows blocks the script, open PowerShell and run:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\move-photos.ps1

$slugs = @(
  'sicily-lotus-ring','dolomites-ring','sicily-ring-marquise','hawaii-ring',
  'portland','mt-fuji-ring','thunder-bay-ring','switzerland','verona-ring',
  'sydney-ring','tahiti-ring','lake-como-ring','victoria','versailles',
  'ontario','madrid','vancouver','amalfi-coast','nara-ring','capri-ring',
  'england','osaka-ring','lab-diamonds-mississauga','kyoto','san-francisco-ring',
  'kingston','halifax','fiji-ring','lake-louise-ring','edmonton','florence',
  'burlington-ring','aspen-ring','whistler'
)

$src = Join-Path $env:USERPROFILE 'Downloads'
$dst = Join-Path $PSScriptRoot 'rings'

if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst | Out-Null }

$moved = 0
$missing = @()
foreach ($s in $slugs) {
  $candidate = Join-Path $src "$s.jpg"
  if (Test-Path $candidate) {
    Move-Item -Path $candidate -Destination (Join-Path $dst "$s.jpg") -Force
    $moved++
  } else {
    $missing += $s
  }
}

Write-Host ""
Write-Host "Moved $moved / $($slugs.Count) ring photos into rings/." -ForegroundColor Green
if ($missing.Count -gt 0) {
  Write-Host ""
  Write-Host "Not found in Downloads (re-download if needed):" -ForegroundColor Yellow
  $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}
Write-Host ""
Write-Host "Refresh index.html in your browser to see the new photos."
Read-Host "Press Enter to close"
