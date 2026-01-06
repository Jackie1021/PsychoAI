#!/bin/bash

# Backend Deployment Script
# This script builds and deploys the backend to Firebase

set -e  # Exit on error

echo "🚀 Starting backend deployment..."

# Navigate to functions directory
cd backend/functions

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "📦 Installing dependencies..."
  npm install
fi

# Build TypeScript
echo "🔨 Building TypeScript..."
npm run build

# Check if build was successful
if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  exit 1
fi

echo "✅ Build successful!"

# Ask user what to deploy
echo ""
echo "What would you like to deploy?"
echo "1) Functions only"
echo "2) Firestore rules only"
echo "3) Storage rules only"
echo "4) Everything (functions + rules + indexes)"
echo "5) Cancel"
read -p "Enter your choice (1-5): " choice

case $choice in
  1)
    echo "📤 Deploying functions..."
    cd ../..
    firebase deploy --only functions
    ;;
  2)
    echo "📤 Deploying Firestore rules..."
    cd ../..
    firebase deploy --only firestore:rules
    ;;
  3)
    echo "📤 Deploying Storage rules..."
    cd ../..
    firebase deploy --only storage
    ;;
  4)
    echo "📤 Deploying everything..."
    cd ../..
    firebase deploy --only functions,firestore,storage
    ;;
  5)
    echo "Cancelled."
    exit 0
    ;;
  *)
    echo "Invalid choice!"
    exit 1
    ;;
esac

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Check deployment logs: firebase functions:log"
echo "  2. Test with Flutter app"
echo "  3. Monitor in Firebase Console"
