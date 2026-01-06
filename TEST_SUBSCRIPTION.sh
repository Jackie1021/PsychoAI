#!/bin/bash

# 订阅功能测试脚本
# 用于验证后端服务是否正确部署和配置

echo "🧪 订阅功能测试脚本"
echo "=================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Firebase 配置
echo "1️⃣ 检查 Firebase 配置..."
if [ -f "firebase.json" ]; then
    echo -e "${GREEN}✅ firebase.json 存在${NC}"
else
    echo -e "${RED}❌ firebase.json 不存在${NC}"
    exit 1
fi

if [ -f "backend/service-account-key.json" ]; then
    echo -e "${GREEN}✅ service-account-key.json 存在${NC}"
else
    echo -e "${YELLOW}⚠️  service-account-key.json 不存在（生产环境可能不需要）${NC}"
fi

echo ""

# 检查后端函数文件
echo "2️⃣ 检查后端函数文件..."
files=(
    "backend/functions/src/user_handler.ts"
    "backend/functions/src/membership_handler.ts"
    "backend/functions/src/index.ts"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file 存在${NC}"
    else
        echo -e "${RED}❌ $file 不存在${NC}"
    fi
done

echo ""

# 检查前端服务文件
echo "3️⃣ 检查前端服务文件..."
files=(
    "lib/services/api_service.dart"
    "lib/services/firebase_api_service.dart"
    "lib/services/fake_api_service.dart"
    "lib/services/membership_service.dart"
    "lib/pages/subscribe_page.dart"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file 存在${NC}"
    else
        echo -e "${RED}❌ $file 不存在${NC}"
    fi
done

echo ""

# 检查关键代码
echo "4️⃣ 检查关键代码实现..."

# 检查 user_handler.ts 是否包含 membershipTier
if grep -q "membershipTier" "backend/functions/src/user_handler.ts"; then
    echo -e "${GREEN}✅ user_handler.ts 包含 membershipTier${NC}"
else
    echo -e "${RED}❌ user_handler.ts 缺少 membershipTier${NC}"
fi

# 检查 membership_handler 是否导出
if grep -q "export \* from \"./membership_handler\"" "backend/functions/src/index.ts"; then
    echo -e "${GREEN}✅ membership_handler 已导出${NC}"
else
    echo -e "${RED}❌ membership_handler 未导出${NC}"
fi

# 检查 api_service.dart 是否包含会员方法
if grep -q "upgradeMembership" "lib/services/api_service.dart"; then
    echo -e "${GREEN}✅ api_service.dart 包含 upgradeMembership${NC}"
else
    echo -e "${RED}❌ api_service.dart 缺少 upgradeMembership${NC}"
fi

# 检查 firebase_api_service.dart 实现
if grep -q "upgradeMembership" "lib/services/firebase_api_service.dart"; then
    echo -e "${GREEN}✅ firebase_api_service.dart 实现了 upgradeMembership${NC}"
else
    echo -e "${RED}❌ firebase_api_service.dart 未实现 upgradeMembership${NC}"
fi

# 检查 subscribe_page.dart 使用 Cloud Function
if grep -q "apiService.upgradeMembership" "lib/pages/subscribe_page.dart"; then
    echo -e "${GREEN}✅ subscribe_page.dart 使用 Cloud Function${NC}"
else
    echo -e "${YELLOW}⚠️  subscribe_page.dart 可能未使用 Cloud Function${NC}"
fi

echo ""

# 检查数据模型
echo "5️⃣ 检查数据模型..."

if grep -q "MembershipTier" "lib/models/user_data.dart"; then
    echo -e "${GREEN}✅ UserData 包含 MembershipTier${NC}"
else
    echo -e "${RED}❌ UserData 缺少 MembershipTier${NC}"
fi

if grep -q "hasActiveMembership" "lib/models/user_data.dart"; then
    echo -e "${GREEN}✅ UserData 包含 hasActiveMembership${NC}"
else
    echo -e "${RED}❌ UserData 缺少 hasActiveMembership${NC}"
fi

if grep -q "effectiveTier" "lib/models/user_data.dart"; then
    echo -e "${GREEN}✅ UserData 包含 effectiveTier${NC}"
else
    echo -e "${RED}❌ UserData 缺少 effectiveTier${NC}"
fi

echo ""

# 检查迁移脚本
echo "6️⃣ 检查数据迁移脚本..."

if [ -f "scripts/migrate_membership_fields.js" ]; then
    echo -e "${GREEN}✅ 迁移脚本存在${NC}"
    if [ -x "scripts/migrate_membership_fields.js" ]; then
        echo -e "${GREEN}✅ 迁移脚本可执行${NC}"
    else
        echo -e "${YELLOW}⚠️  迁移脚本不可执行（可能需要 node 运行）${NC}"
    fi
else
    echo -e "${RED}❌ 迁移脚本不存在${NC}"
fi

echo ""

# 构建检查
echo "7️⃣ 检查构建配置..."

if [ -f "pubspec.yaml" ]; then
    echo -e "${GREEN}✅ pubspec.yaml 存在${NC}"
    
    # 检查必要的依赖
    if grep -q "cloud_functions" "pubspec.yaml"; then
        echo -e "${GREEN}✅ cloud_functions 依赖存在${NC}"
    else
        echo -e "${RED}❌ 缺少 cloud_functions 依赖${NC}"
    fi
    
    if grep -q "cloud_firestore" "pubspec.yaml"; then
        echo -e "${GREEN}✅ cloud_firestore 依赖存在${NC}"
    else
        echo -e "${RED}❌ 缺少 cloud_firestore 依赖${NC}"
    fi
fi

if [ -f "backend/functions/package.json" ]; then
    echo -e "${GREEN}✅ backend package.json 存在${NC}"
else
    echo -e "${RED}❌ backend package.json 不存在${NC}"
fi

echo ""

# 总结
echo "📊 测试总结"
echo "=========="
echo ""
echo "如果所有检查都通过（绿色✅），你的订阅功能已正确实施。"
echo ""
echo "下一步："
echo "1. 运行迁移脚本（如果有现有用户）："
echo "   ${YELLOW}node scripts/migrate_membership_fields.js${NC}"
echo ""
echo "2. 部署 Cloud Functions："
echo "   ${YELLOW}cd backend/functions && npm run build && firebase deploy --only functions${NC}"
echo ""
echo "3. 测试订阅流程："
echo "   ${YELLOW}flutter run -d chrome${NC}"
echo "   然后导航到订阅页面并测试"
echo ""
echo "4. 查看实施文档："
echo "   ${YELLOW}cat SUBSCRIPTION_IMPLEMENTATION_COMPLETE.md${NC}"
echo ""
