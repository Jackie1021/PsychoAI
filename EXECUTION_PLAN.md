# 🚀 执行计划 - Flutter + Firebase 社交匹配应用完整后端集成

## 📋 当前问题总结

### 1. 编译错误
- ❌ `fake_api_service.dart` 有语法错误和重复方法
- ❌ 缺少 `auth_page.dart` 
- ❌ Post 模型字段不匹配 (`mediaUrl` vs `media` 数组)
- ❌ Firebase emulator 初始化问题
- ❌ 各种 getter/setter 错误

### 2. 功能缺失
- ❌ 没有注册/登录页面
- ❌ 举报功能前端未实现
- ❌ 会员系统与 post 查看限制
- ❌ Post 创建后显示重复
- ❌ 用户个人页 post 未关联
- ❌ Match 历史记录未完善

### 3. 后端集成问题
- ❌ `fake_api_service` 需要完全替换为真实 Firebase 调用
- ❌ Cloud Functions 未正确初始化
- ❌ Gemini API 未配置

---

## 🎯 解决方案 - 分阶段执行

### Phase 1: 修复编译错误 ✅ 
**时间：立即**

1. ✅ 修复 Post 模型 - 统一使用 `media: List<String>` 替代 `mediaUrl`
2. ✅ 删除 `fake_api_service.dart` 中的重复方法
3. ✅ 创建 `auth_page.dart` - 登录/注册页面
4. ✅ 修复所有编译错误（getter/setter 问题）
5. ✅ 清理 post_page.dart 中的虚拟数据

---

### Phase 2: 后端 Cloud Functions 完善 ✅
**时间：紧接着**

#### 2.1 修复 Firebase Admin 初始化
```typescript
// index.ts - 确保在所有导入前初始化
import * as admin from 'firebase-admin';
admin.initializeApp();
```

#### 2.2 完善 Cloud Functions
- ✅ `onUserCreate` - 用户创建时初始化 Firestore 文档
- ✅ `onPostCreate` - Post 创建时更新用户 posts 数组
- ✅ `onReportCreate` - 举报触发器，自动处理审核队列
- ✅ `getMatches` - LLM 匹配算法（已有）
- ✅ `likePost` - 点赞处理
- ✅ `createPost` - 创建 post HTTP callable

#### 2.3 配置 Gemini API
```bash
cd backend/functions
echo "GEMINI_API_KEY=your_key_here" > .env
```

---

### Phase 3: 前端完全接入真实数据 ✅
**时间：Phase 2 完成后**

#### 3.1 移除 FakeApiService
- ✅ 删除所有 fake 逻辑
- ✅ `service_locator.dart` 只注册 `FirebaseApiService`

#### 3.2 完善 FirebaseApiService
```dart
class FirebaseApiService implements ApiService {
  // ✅ 直接连接 Firestore + Cloud Functions
  // ✅ 所有方法使用真实 Firebase SDK
  
  @override
  Future<List<Post>> getPublicPosts() async {
    // 从 Firestore /posts 集合读取
    // 过滤 status == 'visible'
    // 排除 blocked users
  }
  
  @override
  Future<void> createPost(Post post) async {
    // 写入 Firestore
    // 触发 onPostCreate Cloud Function
  }
  
  @override
  Future<void> report(...) async {
    // 写入 /reports 集合
    // 触发 onReportCreate
  }
}
```

#### 3.3 页面更新
- ✅ **post_page.dart** - 移除虚拟数据，使用 StreamBuilder
- ✅ **create_post_page.dart** - 上传到 Storage + Firestore
- ✅ **profile_page.dart** - 显示用户自己的 posts
- ✅ **post_detail_page.dart** - 添加举报按钮

---

### Phase 4: 核心功能实现 ✅
**时间：Phase 3 完成后**

#### 4.1 认证系统
```dart
// auth_page.dart
class AuthPage extends StatefulWidget {
  // ✅ 邮箱/密码注册
  // ✅ 登录
  // ✅ 跳转到 feature_selection_page
}
```

#### 4.2 会员系统与 Post 限制
```dart
class MembershipService {
  static const int FREE_DAILY_POSTS_LIMIT = 10;
  
  Future<bool> canViewPost() async {
    final user = getCurrentUser();
    if (user.isMember) return true;
    
    final viewedToday = await getViewCountToday(user.uid);
    return viewedToday < FREE_DAILY_POSTS_LIMIT;
  }
}
```

#### 4.3 举报系统
```dart
// widgets/report_dialog.dart
class ReportDialog extends StatefulWidget {
  // ✅ 举报理由选择
  // ✅ 详细描述
  // ✅ 证据上传（可选）
  // ✅ 提交到后端
}

// 后端自动处理
onReportCreate() {
  // reportCount++
  // if (reportCount >= 5) -> moderationQueue
  // if (reportCount >= 10) -> status = 'hidden'
}
```

#### 4.4 Match 历史记录
```dart
// profile_page.dart
void _loadMatchHistory() async {
  final matches = await apiService.getMatchHistory(currentUser.uid);
  // 显示 match 卡片列表
}
```

---

### Phase 5: 测试与优化 ✅
**时间：Phase 4 完成后**

#### 5.1 启动 Emulator
```bash
# 终端 1
cd backend/functions
npm run build
cd ../..
firebase emulators:start

# 终端 2
flutter run
```

#### 5.2 测试流程
1. ✅ 注册新用户 → 检查 Firestore `/users/{uid}`
2. ✅ 创建 post → 检查 `/posts/{postId}` 和用户 posts 数组
3. ✅ 点赞 → 检查 likeCount 更新
4. ✅ 举报 → 检查 `/reports` 和 reportCount
5. ✅ Match → 调用 LLM 获取匹配结果
6. ✅ 会员限制 → 非会员超过 10 个 posts 后弹窗

#### 5.3 修复已知 Bug
- ✅ Post 重复显示 → 检查 `createPost` 是否被调用两次
- ✅ 用户名未显示 → 确保 `onUserCreate` 正确初始化
- ✅ Post 未关联用户 → 修复 Firestore query

---

## 📂 文件修改清单

### 新增文件
- ✅ `lib/pages/auth_page.dart`
- ✅ `lib/widgets/report_dialog.dart`
- ✅ `backend/functions/.env`

### 修改文件
- ✅ `lib/models/post.dart` - 移除 mediaUrl，统一用 media
- ✅ `lib/services/firebase_api_service.dart` - 完整实现所有方法
- ✅ `lib/services/service_locator.dart` - 移除 fake
- ✅ `lib/services/membership_service.dart` - 添加限制逻辑
- ✅ `lib/pages/post_page.dart` - 移除虚拟数据
- ✅ `lib/pages/create_post_page.dart` - 真实上传
- ✅ `lib/pages/profile_page.dart` - 查询用户 posts
- ✅ `lib/pages/post_detail_page.dart` - 添加举报按钮
- ✅ `lib/main.dart` - 修复 emulator 配置
- ✅ `backend/functions/src/index.ts` - 确保 admin.initializeApp()
- ✅ `backend/functions/src/user_handler.ts` - 修复初始化
- ✅ `backend/functions/src/post_handler.ts` - 添加 onPostCreate

### 删除文件
- ✅ `lib/services/fake_api_service.dart` (或保留但不使用)

---

## 🔧 关键代码片段

### Firestore 数据结构

```javascript
/users/{uid}
{
  uid: string
  username: string
  avatarUrl: string
  bio: string
  interests: string[]
  posts: string[]  // postIds
  lastActive: timestamp
  isSuspended: bool
  reportCount: number
  viewedPostsToday: string[]  // for non-members
  isMember: bool
}

/posts/{postId}
{
  postId: string
  userId: string
  author: string
  authorImageUrl: string
  text: string
  media: string[]  // URLs from Storage
  mediaType: 'text' | 'image' | 'video'
  likeCount: number
  commentCount: number
  status: 'visible' | 'hidden' | 'removed'
  isPublic: bool
  createdAt: timestamp
}

/reports/{reportId}
{
  reporterId: string
  targetType: 'post' | 'user'
  targetId: string
  reasonCode: string
  detailsText: string
  evidence: string[]
  createdAt: timestamp
  processed: bool
}
```

---

## ✅ 完成标准

- [ ] `flutter run` 无编译错误
- [ ] Firebase Emulator 正常启动
- [ ] 用户可以注册/登录
- [ ] 用户可以创建 post（文本/图片）
- [ ] Post 正确显示在首页和个人页
- [ ] 点赞/收藏功能正常
- [ ] 举报功能可用
- [ ] 非会员用户有查看限制
- [ ] Match 功能调用 LLM
- [ ] 所有数据存储在 Firestore Emulator

---

## 🚀 开始执行

**现在开始 Phase 1：修复编译错误**
