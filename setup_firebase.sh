#!/bin/bash

# 🚀 Firebase Setup Script for Quraan App
# This script helps you set up Firebase for the Premium Update System

echo "================================================"
echo "  Firebase Setup for Quraan App Update System  "
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check if Firebase CLI is installed
echo -e "${YELLOW}Step 1: Checking Firebase CLI...${NC}"
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI is not installed.${NC}"
    echo "Install it with: npm install -g firebase-tools"
    echo "Then run this script again."
    exit 1
else
    echo -e "${GREEN}✅ Firebase CLI is installed${NC}"
fi

# Step 2: Login to Firebase
echo ""
echo -e "${YELLOW}Step 2: Logging in to Firebase...${NC}"
firebase login

# Step 3: Initialize Firebase
echo ""
echo -e "${YELLOW}Step 3: Initializing Firebase project...${NC}"
firebase init

echo ""
echo -e "${GREEN}✅ Firebase setup complete!${NC}"
echo ""
echo "================================================"
echo "  Next Steps:                                   "
echo "================================================"
echo ""
echo "1. Download google-services.json from Firebase Console"
echo "   Place it in: android/app/google-services.json"
echo ""
echo "2. Download GoogleService-Info.plist (for iOS)"
echo "   Place it in: ios/Runner/GoogleService-Info.plist"
echo ""
echo "3. Add Firebase Remote Config parameters:"
echo "   - Go to Firebase Console → Remote Config"
echo "   - Copy parameters from: firebase_remote_config_template.yaml"
echo ""
echo "4. Run: flutter pub get"
echo ""
echo "5. Test the app!"
echo ""
echo "For detailed guide, see: PREMIUM_UPDATE_GUIDE.md"
echo ""
