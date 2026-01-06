#!/bin/bash

# Simple script to seed data into running emulator
# Make sure emulators are already running before executing this

set -e

echo "🌱 Seeding emulator with test data..."
echo ""
echo "⚠️  Make sure Firebase emulators are running first!"
echo "   (Run ./START_BACKEND.sh in another terminal)"
echo ""

# Check if emulators are running
if ! curl -s http://localhost:4001 > /dev/null 2>&1; then
  echo "❌ Emulators not running! Please start them first with:"
  echo "   ./START_BACKEND.sh"
  exit 1
fi

echo "✅ Emulators detected"
echo ""

# Install dependencies if needed
cd scripts
if [ ! -d "node_modules" ]; then
  echo "📦 Installing dependencies..."
  npm install --silent
fi

# Run seed
echo "🌱 Creating test users and posts..."
npm run seed

echo ""
echo "✨ Done! Test accounts created:"
echo "   - alice@test.com / test123456"
echo "   - bob@test.com / test123456"
echo "   - charlie@test.com / test123456"
echo "   - diana@test.com / test123456"
echo "   - eve@test.com / test123456"
echo "   - frank@test.com / test123456"
echo ""
