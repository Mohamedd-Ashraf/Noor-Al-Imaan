# ================================================
# Firebase Setup Script for Windows (PowerShell)
# Premium Update System for Quraan App
# ================================================

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Firebase Setup for Quraan App Update System  " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if Firebase CLI is installed
Write-Host "Step 1: Checking Firebase CLI..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version 2>&1
    Write-Host "✅ Firebase CLI is installed: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI is not installed." -ForegroundColor Red
    Write-Host "Install it with: npm install -g firebase-tools" -ForegroundColor Red
    Write-Host "Then run this script again." -ForegroundColor Red
    exit 1
}

# Step 2: Login to Firebase
Write-Host ""
Write-Host "Step 2: Logging in to Firebase..." -ForegroundColor Yellow
firebase login

# Step 3: Initialize Firebase (optional - for advanced users)
Write-Host ""
Write-Host "Do you want to initialize Firebase project? (Y/N)" -ForegroundColor Yellow
$response = Read-Host
if ($response -eq 'Y' -or $response -eq 'y') {
    firebase init
}

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Next Steps:                                   " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Download google-services.json from Firebase Console" -ForegroundColor White
Write-Host "   Place it in: android\app\google-services.json" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Download GoogleService-Info.plist (for iOS)" -ForegroundColor White
Write-Host "   Place it in: ios\Runner\GoogleService-Info.plist" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Add Firebase Remote Config parameters:" -ForegroundColor White
Write-Host "   - Go to Firebase Console → Remote Config" -ForegroundColor Gray
Write-Host "   - Copy parameters from: firebase_remote_config_template.yaml" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Run: flutter pub get" -ForegroundColor White
Write-Host ""
Write-Host "5. Test the app!" -ForegroundColor White
Write-Host ""
Write-Host "For detailed guide, see: PREMIUM_UPDATE_GUIDE.md" -ForegroundColor Cyan
Write-Host ""

# Open guide in browser
Write-Host "Open the premium guide now? (Y/N)" -ForegroundColor Yellow
$openGuide = Read-Host
if ($openGuide -eq 'Y' -or $openGuide -eq 'y') {
    Start-Process "PREMIUM_UPDATE_GUIDE.md"
}
