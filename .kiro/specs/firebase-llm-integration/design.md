# 设计文档

## 概述

本设计文档描述了如何将 LLM 驱动的匹配功能集成到 Flutter + Firebase 社交应用中。系统将使用 Firebase Emulator 进行本地开发，通过 `.env` 文件安全管理 API 密钥，并在启动时自动生成测试用户数据。

核心目标：
1. 在本地模拟器中运行 Cloud Functions，支持快速开发迭代
2. 安全存储 Gemini API 密钥，避免泄露到版本控制
3. 自动生成多样化的测试用户，确保匹配算法可测试性

## 架构

### 系统组件

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter 前端应用                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  FeatureSelectionPage (用户选择特征)                   │   │
│  │  MatchResultPage (显示匹配结果)                        │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  FirebaseApiService.getMatches()                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          ↓ HTTP Call
┌─────────────────────────────────────────────────────────────┐
│              Firebase Emulator (本地开发环境)                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Cloud Functions (http://localhost:5002)              │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │  getMatches() - 主匹配函数                       │  │   │
│  │  │  - 读取当前用户数据                              │  │   │
│  │  │  - 查询候选用户                                  │  │   │
│  │  │  - 调用 LLM 分析                                 │  │   │
│  │  │  - 保存结果到 Firestore                          │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  LLM Service (llm_service.ts)                         │   │
│  │  - 读取 .env 中的 GEMINI_API_KEY                      │   │
│  │  - 调用 Google Gemini API                             │   │
│  │  - 解析 JSON 响应                                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Firestore (http://localhost:8081)                    │   │
│  │  - users 集合 (用户数据)                               │   │
│  │  - matches/{uid}/candidates 集合 (匹配结果)           │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          ↑
┌─────────────────────────────────────────────────────────────┐
│              数据填充脚本 (启动时执行)                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  seed-test-users.js                                   │   │
│  │  - 生成 15 个测试用户                                  │   │
│  │  - 多样化的 traits 组合                                │   │
│  │  - 真实的 freeText 描述                                │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 数据流

1. **用户选择特征** → Flutter 前端收集用户的 traits 和 freeText
2. **调用匹配** → `FirebaseApiService.getMatches()` 调用 Cloud Function
3. **后端处理** → `getMatches` Cloud Function 执行匹配逻辑
4. **LLM 分析** → 对每个候选用户调用 Gemini API 生成分析
5. **保存结果** → 将匹配结果保存到 Firestore
6. **返回前端** → Flutter 应用从 Firestore 读取并显示结果

## 组件和接口

### 1. 环境配置管理

#### `.env` 文件结构
```bash
# backend/functions/.env
GEMINI_API_KEY=your_actual_api_key_here
```

#### `.gitignore` 更新
确保 `.env` 文件不被追踪：
```
backend/functions/.env
backend/functions/lib/
```

#### 环境变量加载
在 `llm_service.ts` 中：
```typescript
import * as dotenv from 'dotenv';
dotenv.config(); // 加载 .env 文件

function initializeLLM(): GenerativeModel {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "GEMINI_API_KEY 未配置。请在 backend/functions/.env 文件中设置。"
    );
  }
  // ... 初始化逻辑
}
```

### 2. 测试用户数据生成器

#### 用户特征池
基于 `feature_selection_page.dart` 中的特征：
```javascript
const AVAILABLE_TRAITS = [
  'storyteller',    // 讲故事的人
  'listener',       // 倾听者
  'dream log',      // 梦境记录者
  'night owl',      // 夜猫子
  'world builder',  // 世界构建者
  'observer',       // 观察者
  'mood board',     // 情绪板
  'writer',         // 写作者
  'sound hunt',     // 声音猎人
  'rituals',        // 仪式感
  'sketches',       // 素描者
];
```

#### 测试用户生成逻辑
```javascript
// backend/functions/seed-test-users.js
const admin = require('firebase-admin');

// 生成随机特征组合（每个用户 2-5 个特征）
function generateRandomTraits() {
  const count = Math.floor(Math.random() * 4) + 2; // 2-5 个特征
  const shuffled = [...AVAILABLE_TRAITS].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

// 生成真实的自由文本描述
function generateFreeText(traits) {
  const templates = [
    `我是一个${traits[0]}，喜欢在深夜${traits[1] || '思考'}。`,
    `热爱${traits[0]}和${traits[1] || '创作'}，寻找志同道合的朋友。`,
    `${traits[0]}是我的日常，${traits[1] || '探索'}是我的激情。`,
  ];
  return templates[Math.floor(Math.random() * templates.length)];
}

// 创建测试用户
async function seedTestUsers() {
  const db = admin.firestore();
  const usersRef = db.collection('users');
  
  const testUserIds = [];
  for (let i = 1; i <= 15; i++) {
    const uid = `test_user_${i}`;
    const traits = generateRandomTraits();
    
    const userData = {
      uid,
      username: `测试用户${i}`,
      traits,
      freeText: generateFreeText(traits),
      avatarUrl: `https://ui-avatars.com/api/?name=User${i}`,
      bio: generateFreeText(traits),
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
      isSuspended: false,
      reportCount: 0,
      followersCount: Math.floor(Math.random() * 100),
      followingCount: Math.floor(Math.random() * 100),
      postsCount: Math.floor(Math.random() * 50),
      followedBloggerIds: [],
      favoritedPostIds: [],
      likedPostIds: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    await usersRef.doc(uid).set(userData);
    testUserIds.push(uid);
  }
  
  console.log(`✅ 成功创建 ${testUserIds.length} 个测试用户`);
  return testUserIds;
}
```

### 3. Cloud Functions 配置

#### `package.json` 依赖更新
```json
{
  "dependencies": {
    "@google/generative-ai": "^0.1.3",
    "dotenv": "^16.3.1",
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0"
  }
}
```

#### TypeScript 编译配置
`tsconfig.json` 已存在，确保输出到 `lib/` 目录：
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "outDir": "lib",
    "rootDir": "src",
    "target": "es2017"
  }
}
```

### 4. 启动脚本改进

#### 新的 `START_BACKEND.sh`
```bash
#!/bin/bash
set -e

echo "🔧 准备 Cloud Functions..."
cd backend/functions

# 检查 .env 文件
if [ ! -f ".env" ]; then
  echo "⚠️  未找到 .env 文件"
  echo "📝 正在从 .env.example 创建 .env..."
  cp .env.example .env
  echo ""
  echo "❗ 请编辑 backend/functions/.env 文件，填入你的 GEMINI_API_KEY"
  echo "   获取 API Key: https://makersuite.google.com/app/apikey"
  echo ""
  read -p "按 Enter 继续（确保已配置 API Key）..."
fi

# 安装依赖
echo "📦 安装依赖..."
npm install

# 编译 TypeScript
echo "🔨 编译 TypeScript..."
npm run build

if [ ! -f "lib/index.js" ]; then
  echo "❌ 编译失败！lib/index.js 不存在"
  exit 1
fi

echo "✅ 编译成功！"

# 清理旧进程
echo "🧹 清理旧的 emulator 进程..."
pkill -f "firebase emulators:start" 2>/dev/null || true
sleep 2

# 启动模拟器
echo "🚀 启动 Firebase Emulator..."
cd ../..
firebase emulators:start --only=auth,firestore,storage,functions --import=./emulator-data --export-on-exit
```

### 5. 数据填充集成

#### 创建 Emulator 启动钩子
Firebase Emulator 支持在启动后执行脚本。我们将创建一个独立的填充脚本：

```javascript
// backend/functions/seed-emulator-data.js
const admin = require('firebase-admin');

// 初始化 Admin SDK 连接到模拟器
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9098';

admin.initializeApp({
  projectId: 'studio-291983403-af613',
});

// 导入填充函数
const { seedTestUsers } = require('./seed-test-users');

async function main() {
  console.log('🌱 开始填充测试数据...');
  
  try {
    // 检查是否已有测试用户
    const db = admin.firestore();
    const existingUsers = await db.collection('users')
      .where('uid', '>=', 'test_user_')
      .where('uid', '<', 'test_user_z')
      .limit(1)
      .get();
    
    if (!existingUsers.empty) {
      console.log('ℹ️  测试用户已存在，跳过填充');
      process.exit(0);
    }
    
    await seedTestUsers();
    console.log('✅ 数据填充完成');
    process.exit(0);
  } catch (error) {
    console.error('❌ 数据填充失败:', error);
    process.exit(1);
  }
}

main();
```

## 数据模型

### 用户数据结构（Firestore）

基于 `lib/models/user_data.dart` 和 `lib/models/base_user_data.dart`：

```typescript
interface UserDocument {
  uid: string;                    // 用户唯一标识
  username: string;               // 用户名
  traits: string[];               // 用户特征列表
  freeText: string;               // 自由文本描述
  avatarUrl?: string;             // 头像 URL
  bio?: string;                   // 个人简介（与 freeText 相同）
  lastActive: Timestamp;          // 最后活跃时间
  isSuspended: boolean;           // 是否被封禁
  reportCount: number;            // 被举报次数
  followersCount: number;         // 粉丝数
  followingCount: number;         // 关注数
  postsCount: number;             // 帖子数
  followedBloggerIds: string[];   // 关注的博主 ID 列表
  favoritedPostIds: string[];     // 收藏的帖子 ID 列表
  likedPostIds: string[];         // 点赞的帖子 ID 列表
  favoritedConversationIds: string[]; // 收藏的对话 ID 列表
  createdAt: Timestamp;           // 创建时间
}
```

### 匹配分析结构（Firestore）

基于 `lib/models/match_analysis.dart`：

```typescript
interface ScoredFeature {
  score: number;        // 0-100 的分数
  explanation: string;  // 解释文本
}

interface MatchDocument {
  id: string;                              // 匹配 ID
  userA: UserDocument;                     // 当前用户数据
  userB: UserDocument;                     // 匹配用户数据
  summary: string;                         // 一句话总结
  totalScore: number;                      // AI 生成的总分 (0-100)
  formulaScore: number;                    // 公式计算的分数 (0-1)
  finalScore: number;                      // 最终加权分数 (0-1)
  similarFeatures: Record<string, ScoredFeature>; // 相似特征详情
}
```

存储路径：`matches/{currentUserId}/candidates/{matchedUserId}`

## 错误处理

### 1. API 密钥缺失
```typescript
// llm_service.ts
if (!apiKey) {
  throw new functions.https.HttpsError(
    "failed-precondition",
    "GEMINI_API_KEY 未配置。请在 backend/functions/.env 文件中设置。\n" +
    "获取 API Key: https://makersuite.google.com/app/apikey"
  );
}
```

### 2. 用户文档不存在
```typescript
// index.ts - getMatches
if (!currentUserDoc.exists) {
  // 自动创建用户文档
  const userProfile = {
    uid,
    username: context.auth.token?.name || "User",
    traits: [],
    freeText: "",
    // ... 其他默认字段
  };
  await usersCollection.doc(uid).set(userProfile);
  currentUser = userProfile;
}
```

### 3. LLM 调用失败
```typescript
// index.ts - getMatches
const llmPromises = topCandidates.map(async (candidate) => {
  try {
    const llmResponse = await callAgent(prompt);
    return { ...llmResponse, userB: candidate.user };
  } catch (error) {
    functions.logger.error(`LLM 分析失败: ${candidate.user.uid}`, { error });
    return null; // 返回 null，继续处理其他候选人
  }
});

// 过滤掉失败的结果
const llmResults = (await Promise.all(llmPromises))
  .filter(result => result !== null);
```

### 4. 前端错误处理
```dart
// firebase_api_service.dart
try {
  await callable.call();
} on FirebaseFunctionsException catch (error) {
  if (error.code == 'not-found') {
    print('ℹ️ 用户不存在，尝试重新创建...');
    await _ensureUserDocument(uid);
    await callable.call(); // 重试
  } else if (error.code == 'failed-precondition') {
    print('❌ API 配置错误: ${error.message}');
    throw Exception('后端配置错误，请联系管理员');
  } else {
    rethrow;
  }
}
```

## 测试策略

### 1. 单元测试
- **LLM Service**: 测试 API 调用和 JSON 解析
- **数据生成器**: 验证生成的用户数据符合模型要求
- **匹配算法**: 测试公式计算的正确性

### 2. 集成测试
- **端到端流程**: 从 Flutter 调用到 Firestore 存储
- **模拟器测试**: 验证所有组件在模拟器中正常工作
- **错误场景**: 测试各种错误情况的处理

### 3. 手动测试清单
- [ ] 启动脚本正确编译和启动模拟器
- [ ] `.env` 文件缺失时显示清晰错误
- [ ] 测试用户自动创建（15 个用户）
- [ ] Flutter 应用可以调用 `getMatches`
- [ ] 匹配结果正确显示在 UI 中
- [ ] Emulator UI 可以查看 Firestore 数据
- [ ] 函数日志正确显示在控制台

## 开发工作流

### 初次设置
1. 克隆仓库
2. 复制 `.env.example` 到 `.env`
3. 在 `.env` 中填入 Gemini API Key
4. 运行 `./START_BACKEND.sh`
5. 在另一个终端运行 `flutter run -d chrome`

### 日常开发
1. 修改 TypeScript 代码
2. 运行 `npm run build` 重新编译
3. 模拟器会自动重新加载函数
4. 刷新 Flutter 应用测试

### 调试
- 查看 Emulator UI: `http://localhost:4001`
- 查看函数日志: 终端输出
- 查看 Firestore 数据: Emulator UI → Firestore 标签
- 测试函数: Emulator UI → Functions 标签

## 安全考虑

1. **API 密钥保护**
   - `.env` 文件在 `.gitignore` 中
   - 不在代码中硬编码密钥
   - 生产环境使用 Firebase Functions Config 或 Secret Manager

2. **用户数据隐私**
   - 测试用户使用虚拟数据
   - 不在日志中输出敏感信息
   - Firestore 规则限制数据访问

3. **速率限制**
   - LLM 调用限制为前 20 个候选人
   - 考虑添加用户级别的调用频率限制

## 性能优化

1. **并发处理**
   - 使用 `Promise.all` 并发调用 LLM
   - 最多同时处理 20 个候选人

2. **缓存策略**
   - 匹配结果存储在 Firestore 中
   - 前端可以读取缓存结果避免重复计算

3. **数据库优化**
   - 为 `users` 集合的 `traits` 字段创建索引
   - 限制查询结果数量

## 未来扩展

1. **增量匹配**: 只分析新用户，不重复分析已有匹配
2. **匹配历史**: 记录用户的匹配历史和反馈
3. **个性化权重**: 根据用户反馈调整匹配算法权重
4. **实时更新**: 使用 Firestore 监听器实时更新匹配结果
5. **A/B 测试**: 测试不同的 LLM prompt 和权重配置
