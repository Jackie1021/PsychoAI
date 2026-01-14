#!/bin/bash

echo "🌱 开始重新生成虚拟数据..."

cd backend/functions

# 设置环境变量
export FIRESTORE_EMULATOR_HOST="127.0.0.1:8081"
export FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9098"

echo "👥 创建测试用户..."
node create_rich_test_users.js

echo "📚 创建综合数据..."
node create_comprehensive_data.js

echo "🎯 生成匹配数据..."
node generate_all_matches.js

echo "🏘️ 创建社区帖子..."
node create_community_posts.js
node create_more_community_posts.js

echo "✅ 虚拟数据生成完成!"
echo ""
echo "📊 现在您拥有:"
echo "• 20个测试用户（密码: password123）"
echo "• 207个匹配关系"
echo "• 35个精美的社区帖子"
echo ""
echo "🔑 推荐测试登录："
echo "• diana@test.com / password123"
echo "• test@example.com / 123456"
