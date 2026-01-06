# 调试日志指南 - 订阅与数据同步问题排查

## 🔍 已添加的调试日志

### 前端日志 (Flutter)

#### 1. post_page.dart - 用户加载
```
🔄 [POST_PAGE] Loading current user...
👤 [POST_PAGE] Firebase user found: {uid}
✅ [POST_PAGE] User data loaded: {username}
   - Membership: {tier}
   - Has active: {boolean}
   - Expiry: {timestamp}
   - Effective tier: {tier}
✅ [POST_PAGE] State updated with membership: {tier}
```

#### 2. post_page.dart - 点赞操作
```
❤️ [POST_PAGE] Like toggle for post: {postId}
   - Current isLiked: {boolean}
   - Current likes: {count}
🔄 [POST_PAGE] Calling likePost API...
✅ [POST_PAGE] API returned new like status: {boolean}
✅ [POST_PAGE] Updated post in list at index {index}
   - New isLiked: {boolean}
   - New likes: {count}
```

#### 3. post_page.dart - 收藏操作
```
⭐ [POST_PAGE] Favorite toggle for post: {postId}
   - Current isFavorited: {boolean}
   - Current favorites: {count}
🔄 [POST_PAGE] Calling toggleFavoritePost API...
✅ [POST_PAGE] API returned new favorite status: {boolean}
✅ [POST_PAGE] Updated post in list at index {index}
   - New isFavorited: {boolean}
   - New favorites: {count}
```

#### 4. profile_page.dart - 加载数据
```
📂 [PROFILE_PAGE] Loading section data: {section}
👤 [PROFILE_PAGE] Current user: {uid}
🔄 [PROFILE_PAGE] Fetching liked posts...
✅ [PROFILE_PAGE] Loaded {count} liked posts

🔄 [PROFILE_PAGE] Fetching favorited posts...
✅ [PROFILE_PAGE] Loaded {count} favorited posts
```

### 后端日志 (Cloud Functions)

#### 1. likePost函数
```
❤️ likePost called { postId, authUid }
👤 likePost: Processing { postId, uid }
🔍 likePost: Current state { postId, uid, isCurrentlyLiked, action }
🔄 likePost: Liking post... / Unliking post...
✅ likePost: Successfully liked/unliked { postId, uid }
```

#### 2. toggleFavoritePost函数
```
⭐ toggleFavoritePost called { postId, authUid }
👤 toggleFavoritePost: Processing { postId, uid }
🔍 toggleFavoritePost: Current state { postId, uid, isCurrentlyFavorited, action }
🔄 toggleFavoritePost: Favoriting/Unfavoriting post...
✅ toggleFavoritePost: Successfully favorited/unfavorited { postId, uid }
```

#### 3. getLikedPosts函数
```
🔵 getLikedPosts called { userId, authUid }
👤 getLikedPosts: Target user ID { targetUserId }
📋 getLikedPosts: Found liked posts { count, postIds }
🔄 getLikedPosts: Fetching batch {n} { batchSize, postIds }
✅ getLikedPosts: Batch fetched { found, expected }
✅ getLikedPosts: Returning posts { totalCount, postIds }
```

#### 4. getFavoritedPosts函数
```
🟡 getFavoritedPosts called { userId, authUid }
👤 getFavoritedPosts: Target user ID { targetUserId }
📋 getFavoritedPosts: Found favorited posts { count, postIds }
🔄 getFavoritedPosts: Fetching batch {n} { batchSize, postIds }
✅ getFavoritedPosts: Batch fetched { found, expected }
✅ getFavoritedPosts: Returning posts { totalCount, postIds }
```

---

## 🐛 常见问题诊断

### 问题1: getFavoritedPosts返回"INTERNAL"错误

**可能原因**:
1. 用户文档不存在
2. favoritedPostIds字段为空或格式错误
3. 帖子已被删除（status != "visible"）
4. Firestore查询权限问题

**查看日志关键点**:
```bash
# 1. 检查后端日志
# 查找: 🟡 getFavoritedPosts called
# 确认: userId是否正确

# 2. 查找: 📋 getFavoritedPosts: Found favorited posts
# 检查: count和postIds数组

# 3. 如果有❌错误，查看完整error message和stack
```

**调试步骤**:
```bash
# 步骤1: 打开Firebase Emulator UI
open http://localhost:4000

# 步骤2: 检查Firestore数据
Firestore → users → {your-uid}
  - 查看 favoritedPostIds 数组
  - 确认有post ID存在

# 步骤3: 检查posts集合
Firestore → posts → {postId}
  - 确认 status: "visible"
  - 确认文档存在

# 步骤4: 查看后端控制台日志
# 应该看到详细的调用过程
```

### 问题2: 订阅状态不同步

**查看日志**:
```
🔄 [POST_PAGE] Loading current user...
✅ [POST_PAGE] User data loaded: alice
   - Membership: free  ← 检查这里
   - Has active: false
   - Expiry: null
   - Effective tier: free
```

**可能原因**:
1. 订阅未正确保存到Firestore
2. membershipExpiry已过期
3. 页面未刷新

**解决步骤**:
1. 检查Firestore: `users/{uid}/membershipTier`
2. 检查Firestore: `users/{uid}/membershipExpiry`
3. 重新进入Post页面触发_loadCurrentUser()

### 问题3: 点赞后数据不更新

**完整日志流程应该是**:
```
// 前端
❤️ [POST_PAGE] Like toggle for post: abc123
   - Current isLiked: false
   - Current likes: 5
🔄 [POST_PAGE] Calling likePost API...

// 后端
❤️ likePost called { postId: 'abc123', authUid: 'user123' }
👤 likePost: Processing { postId: 'abc123', uid: 'user123' }
🔍 likePost: Current state { isCurrentlyLiked: false, action: 'Like' }
🔄 likePost: Liking post...
✅ likePost: Successfully liked { postId: 'abc123', uid: 'user123' }

// 前端
✅ [POST_PAGE] API returned new like status: true
✅ [POST_PAGE] Updated post in list at index 2
   - New isLiked: true
   - New likes: 6
```

**如果中断**:
- 检查哪一步失败
- 查看❌错误信息
- 检查网络连接

---

## 📋 调试检查清单

### 启动时检查
- [ ] 后端正常运行 (`./START_BACKEND.sh`)
- [ ] 看到 "All emulators ready!"
- [ ] Flutter应用已连接到emulator
- [ ] 用户已登录

### 点赞/收藏操作检查
- [ ] 点击按钮后看到前端日志
- [ ] 后端收到API调用日志
- [ ] 操作成功完成（✅日志）
- [ ] UI立即更新
- [ ] Profile页面能看到更新

### 订阅状态检查
- [ ] 订阅成功后有成功提示
- [ ] 返回Post页面
- [ ] 看到"Loading current user"日志
- [ ] membershipTier正确显示
- [ ] Upgrade按钮隐藏（Premium/Pro）

---

## 🔧 手动验证数据

### 使用Firebase Emulator UI

```bash
# 1. 打开UI
open http://localhost:4000

# 2. 检查用户数据
Firestore → users → {your-uid}
{
  "likedPostIds": ["post1", "post2"],      ← 应该有数据
  "favoritedPostIds": ["post3"],           ← 应该有数据
  "membershipTier": "premium",             ← 检查等级
  "membershipExpiry": Timestamp(...),      ← 检查时间
  "hasActiveMembership": true              ← 计算字段
}

# 3. 检查子集合
users → {uid} → likes → {postId}
users → {uid} → favorites → {postId}

# 4. 检查帖子
posts → {postId}
{
  "likeCount": 10,       ← 应该匹配likes子集合数量
  "favoriteCount": 5,    ← 应该匹配favorites子集合数量
  "status": "visible"    ← 必须是visible
}
```

---

## 💡 快速诊断命令

### 查看后端实时日志
```bash
# 启动后端后，日志会实时显示在终端
# 关注这些emoji:
🔵 🟡 ❤️ ⭐  # API调用
✅           # 成功操作
❌           # 错误
⚠️           # 警告
```

### 查看前端日志
```bash
# Chrome开发者工具 → Console
# 或 VS Code → Debug Console

# 过滤日志:
# 输入: POST_PAGE
# 输入: PROFILE_PAGE
```

### 重建数据（清空测试）
```bash
# 1. 停止后端 (Ctrl+C)

# 2. 清空数据（可选）
# Firebase Emulator UI → Firestore → Clear all data

# 3. 重新启动
./START_BACKEND.sh

# 4. 运行种子数据（可选）
./SEED_DATA.sh

# 5. 重新启动前端
flutter run -d chrome
```

---

## 📱 实际测试流程

### 完整测试序列
```bash
# 1. 启动应用
./START_BACKEND.sh
flutter run -d chrome

# 2. 登录
alice@test.com / test123456

# 3. 测试点赞
打开Post页面
点击一个帖子的❤️
观察控制台:
  ✓ 看到前端日志
  ✓ 看到后端日志
  ✓ 图标变红
  ✓ 数字+1

# 4. 验证点赞同步
进入Profile页面
点击"Liked"标签
观察控制台:
  ✓ 看到📂 Loading section data
  ✓ 看到🔵 getLikedPosts called
  ✓ 看到✅ Loaded X liked posts
  ✓ 帖子显示在列表中

# 5. 测试收藏（同理）
回到Post页面
点击⭐
进入Profile → Favorites标签
验证数据同步

# 6. 测试订阅
进入Profile → 编辑 → Subscription
订阅Premium
观察控制台:
  ✓ 看到订阅成功提示
返回Post页面
观察控制台:
  ✓ 看到🔄 Loading current user
  ✓ 看到Membership: premium
  ✓ Upgrade按钮消失
```

---

## 🎯 常见错误代码

### firebase_functions/internal
**含义**: 后端函数执行失败
**查看**: 后端终端的完整错误栈
**常见原因**:
- Firestore查询失败
- 数据格式错误
- 权限不足

### firebase_functions/not-found
**含义**: 找不到指定资源
**检查**:
- 用户文档是否存在
- 帖子文档是否存在
- ID是否正确

### firebase_functions/unauthenticated
**含义**: 用户未认证
**解决**: 重新登录

---

## 📞 获取帮助

### 如果问题仍未解决

1. **收集日志**:
   - 完整的前端控制台日志
   - 完整的后端终端日志
   - Firestore数据截图

2. **描述问题**:
   - 操作步骤
   - 预期结果
   - 实际结果
   - 错误信息

3. **提供环境信息**:
   - Flutter版本
   - Node版本
   - 浏览器版本

---

**创建时间**: 2025-11-17  
**版本**: v1.0  
**状态**: ✅ 日志系统已部署
