#!/bin/bash

echo "🔄 Updating Firestore security rules..."

# Deploy Firestore rules
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo "✅ Firestore rules updated successfully!"
    echo ""
    echo "📋 Changes applied:"
    echo "  1. Added yearlyAnalyses subcollection access rules"
    echo "  2. Fixed conversations create validation"
    echo ""
    echo "🧪 Test these scenarios:"
    echo "  - Generate AI Analysis in Yearly Report"
    echo "  - Start Chat from Match History"
    echo "  - View cached AI analyses"
else
    echo "❌ Failed to update rules"
    exit 1
fi
