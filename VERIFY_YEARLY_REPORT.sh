#!/bin/bash

echo "========================================"
echo "Yearly Report Page - Verification Script"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Not in Flutter project root${NC}"
    exit 1
fi

echo "📁 Checking files..."

# Check new model files
FILES=(
    "lib/models/chat_history_summary.dart"
    "lib/models/yearly_ai_analysis.dart"
    "lib/pages/yearly_report_page.dart"
    "lib/services/api_service.dart"
    "lib/services/firebase_api_service.dart"
    "lib/services/fake_api_service.dart"
    "lib/providers/chat_provider.dart"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $file"
    else
        echo -e "${RED}❌${NC} $file (MISSING)"
    fi
done

echo ""
echo "📋 Checking documentation..."

DOCS=(
    "YEARLY_REPORT_REDESIGN_COMPLETE.md"
    "YEARLY_REPORT_QUICK_START.md"
    "IMPLEMENTATION_SUMMARY_YEARLY_REPORT.txt"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}✅${NC} $doc"
    else
        echo -e "${YELLOW}⚠️${NC} $doc (optional)"
    fi
done

echo ""
echo "🔍 Checking code completeness..."

# Check for TODOs
TODO_COUNT=$(grep -r "TODO\|FIXME\|XXX" lib/pages/yearly_report_page.dart 2>/dev/null | wc -l)
if [ $TODO_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅${NC} No TODO/FIXME/XXX found"
else
    echo -e "${YELLOW}⚠️${NC} Found $TODO_COUNT TODO/FIXME/XXX markers"
fi

# Check for placeholder text
PLACEHOLDER_COUNT=$(grep -r "placeholder\|PLACEHOLDER" lib/pages/yearly_report_page.dart 2>/dev/null | wc -l)
if [ $PLACEHOLDER_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅${NC} No placeholders found"
else
    echo -e "${RED}❌${NC} Found $PLACEHOLDER_COUNT placeholder markers"
fi

echo ""
echo "📊 Code statistics..."

if [ -f "lib/pages/yearly_report_page.dart" ]; then
    LINES=$(wc -l < lib/pages/yearly_report_page.dart)
    echo "  • Yearly Report Page: $LINES lines"
fi

if [ -f "lib/models/chat_history_summary.dart" ]; then
    LINES=$(wc -l < lib/models/chat_history_summary.dart)
    echo "  • Chat History Summary: $LINES lines"
fi

if [ -f "lib/models/yearly_ai_analysis.dart" ]; then
    LINES=$(wc -l < lib/models/yearly_ai_analysis.dart)
    echo "  • Yearly AI Analysis: $LINES lines"
fi

echo ""
echo "🧪 Running Flutter analysis..."
flutter analyze lib/pages/yearly_report_page.dart --no-fatal-infos 2>&1 | grep -E "(error|warning)" | head -5

echo ""
echo "✨ Verification complete!"
echo ""
echo "Next steps:"
echo "  1. Run: flutter pub get"
echo "  2. Run: flutter run -d chrome"
echo "  3. Navigate to Yearly Report page"
echo "  4. Test all three tabs"
echo "  5. Review documentation files"
echo ""
echo "========================================"
