#!/bin/bash

set -e

echo "🔧 准备 Cloud Functions..."
cd /Users/chenjiaqi/Desktop/Business_idea/3_terminal/flutter_app-origin-shiwen/backend/functions

# 确保依赖都安装了
echo "📦 安装依赖..."
npm install --include=dev 2>&1 | grep -E "added|up to date" || true

# 编译 TypeScript
echo "🔨 编译 TypeScript..."
npm run build 2>&1

if [ ! -f "lib/index.js" ]; then
  echo "❌ 编译失败！lib/index.js 不存在"
  exit 1
fi

echo ""
echo "✅ 编译成功！"
echo "✅ 已生成: lib/index.js"
echo ""
echo "🧹 清理旧的 emulator 进程..."
pkill -f "firebase emulators:start" 2>/dev/null || true
pkill -f "java" 2>/dev/null || true
sleep 2

echo "🚀 启动 Firebase Emulator..."
echo ""
echo "等待 'All emulators ready!' 消息..."
echo ""
cd /Users/chenjiaqi/Desktop/Business_idea/3_terminal/flutter_app-origin-shiwen
firebase emulators:start --only=auth,firestore,storage,functions

