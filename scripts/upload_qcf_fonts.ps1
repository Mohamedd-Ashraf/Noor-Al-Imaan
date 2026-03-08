<#
.SYNOPSIS
    Uploads the 604 QCF page WOFF fonts to Firebase Hosting (or any chosen destination).

.DESCRIPTION
    The qcf_quran pub package bundles 51 MB of per-page WOFF fonts.  Our local fork
    leaves them out of the APK; instead the app downloads them on demand at runtime
    from the URL set in _qcfFontsBaseUrl (lib/main.dart).

    This script:
      1. Copies the 604 fonts from the pub cache into a staging folder.
      2. Optionally deploys them to Firebase Hosting under the /qcf_fonts/ path.

.REQUIREMENTS
    • Flutter SDK installed (used only to locate the pub cache root).
    • Firebase CLI installed and logged in:  npm install -g firebase-tools
    • firebase login   (run once)

.USAGE
    .\scripts\upload_qcf_fonts.ps1
    .\scripts\upload_qcf_fonts.ps1 -SkipDeploy   # only stage, don't run firebase deploy
    .\scripts\upload_qcf_fonts.ps1 -Verbose

.NOTES
    After running, set _qcfFontsBaseUrl in lib/main.dart to:
        "https://<YOUR_PROJECT_ID>.web.app/qcf_fonts"
#>

param(
    [switch] $SkipDeploy,
    [switch] $Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── 1. Locate the pub-cache source fonts ────────────────────────────────────
$pubCacheRoot = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\qcf_quran-0.0.5"
$fontSrc      = "$pubCacheRoot\assets\fonts\qcf4"

if (-not (Test-Path $fontSrc)) {
    Write-Error "Cannot find qcf_quran pub cache at: $fontSrc`nRun 'flutter pub add qcf_quran' once to populate it."
    exit 1
}

$fonts = Get-ChildItem $fontSrc -Filter "*.woff"
if ($fonts.Count -ne 604) {
    Write-Warning "Expected 604 WOFF files but found $($fonts.Count). Proceeding anyway."
}

# ── 2. Create staging folder inside firebase public dir ─────────────────────
$projectRoot = Split-Path $PSScriptRoot -Parent   # e.g. E:\Quraan\quraan
$stagingDir  = "$projectRoot\public\qcf_fonts"

Write-Host "Staging fonts to: $stagingDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $stagingDir | Out-Null

$copied = 0
foreach ($f in $fonts) {
    $dest = Join-Path $stagingDir $f.Name
    if (-not (Test-Path $dest)) {
        Copy-Item $f.FullName $dest
        $copied++
        if ($Verbose) { Write-Host "  Copied $($f.Name)" }
    }
}
Write-Host "Copied $copied new fonts ($(604 - $copied) already present)." -ForegroundColor Green

# ── 3. Deploy to Firebase Hosting ───────────────────────────────────────────
if ($SkipDeploy) {
    Write-Host "`n-SkipDeploy specified. Deployment skipped." -ForegroundColor Yellow
    Write-Host "To deploy manually:  firebase deploy --only hosting" -ForegroundColor Yellow
    exit 0
}

Write-Host "`nDeploying to Firebase Hosting..." -ForegroundColor Cyan

# Check firebase CLI is available
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Error "Firebase CLI not found. Install with: npm install -g firebase-tools"
    exit 1
}

Push-Location $projectRoot
try {
    firebase deploy --only hosting
}
finally {
    Pop-Location
}

Write-Host "`nDone! Set _qcfFontsBaseUrl in lib/main.dart to:" -ForegroundColor Green
Write-Host '    "https://<YOUR_PROJECT_ID>.web.app/qcf_fonts"' -ForegroundColor Yellow
