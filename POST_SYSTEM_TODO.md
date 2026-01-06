# 社交帖子系统完善计划 (POST System Enhancement Plan)

## 📋 当前问题总结 (Current Issues)

### 1. 数据库层面问题
- ❌ **用户文档不存在**: 发帖时找不到用户文档 (`no entity to update`)
- ❌ **Cloud Function 错误**: `createPost` 返回 INTERNAL 错误
- ❌ **Match 系统错误**: `getMatches` 找不到当前用户

### 2. 功能缺失
- ⚠️ 帖子编辑功能未实现
- ⚠️ 帖子可见性设置（public/private）未完全集成
- ⚠️ 点击头像跳转到用户Profile功能不完整
- ⚠️ Profile页面的帖子管理功能未完善
- ⚠️ 收藏/点赞的帖子展示功能未实现
- ⚠️ 关注用户的帖子feed未实现
- ⚠️ 帖子举报功能未完全集成到UI

### 3. UI/UX 问题
- ⚠️ 多个PostCard实现（post_page.dart 和 post_feed_page.dart）不一致
- ⚠️ 视频上传和播放功能不完整
- ⚠️ 图片上传到Firebase Storage未实现

---

## 🎯 实施计划 (Implementation Plan)

## 阶段 1: 修复核心数据库问题 (Phase 1: Fix Core Database Issues)

### 1.1 用户文档自动创建机制
**文件**: `backend/functions/src/user_handler.ts` (新建或完善)

**任务**:
- [ ] 创建 `ensureUserExists` Cloud Function
- [ ] 在首次登录时自动创建用户文档
- [ ] 包含所有必需字段: uid, username, avatarUrl, bio, traits, followedBloggerIds, likedPostIds, favoritedPostIds 等
- [ ] 更新 `createPost` 函数，在发帖前自动调用用户创建
- [ ] 更新 `getMatches` 函数，在匹配前检查用户文档

**数据模型**:
```typescript
interface UserDocument {
  uid: string;
  username: string;
  avatarUrl: string;
  bio: string;
  traits: string[];
  freeText: string;
  followedBloggerIds: string[];
  likedPostIds: string[];
  favoritedPostIds: string[];
  followersCount: number;
  followingCount: number;
  postsCount: number;
  lastActive: Timestamp;
  createdAt: Timestamp;
  isSuspended: boolean;
  reportCount: number;
  privacy: {
    visibility: 'public' | 'friends' | 'private';
  };
}
```

### 1.2 修复 createPost Cloud Function
**文件**: `backend/functions/src/post_handler.ts`

**任务**:
- [ ] 添加详细的错误日志
- [ ] 确保用户文档存在后再创建帖子
- [ ] 支持图片/视频上传到 Firebase Storage
- [ ] 返回完整的 post 对象（包含 postId）
- [ ] 更新用户的 postsCount

### 1.3 完善 Firebase Storage 图片/视频上传
**文件**: `lib/services/firebase_api_service.dart`

**任务**:
- [ ] 实现 `uploadMedia(File file, String userId, String postId)` 方法
- [ ] 支持图片压缩和视频转码（可选）
- [ ] 返回 Storage URL
- [ ] 在 createPost 时先上传媒体，再保存 URL

---

## 阶段 2: 完善帖子基础功能 (Phase 2: Complete Post Basic Features)

### 2.1 统一 PostCard 组件
**文件**: `lib/widgets/post_card.dart` (新建)

**任务**:
- [ ] 创建统一的 `PostCard` widget
- [ ] 支持显示文本、图片、视频
- [ ] 支持点赞、评论、收藏按钮
- [ ] 支持点击头像跳转到 PublicProfilePage
- [ ] 支持长按菜单（编辑、删除、举报、分享）
- [ ] 保持原有瀑布流 UI 风格
- [ ] 支持会员/非会员的模糊遮罩效果

**UI 设计要点**:
```dart
// 保留原有风格
- 圆角卡片 (borderRadius: 16)
- 渐变遮罩 (黑色透明渐变)
- 底部作者信息和交互按钮
- 支持不同尺寸的 mainAxisCellCount
```

### 2.2 实现帖子编辑功能
**文件**: `lib/pages/edit_post_page.dart` (新建)

**任务**:
- [ ] 创建 EditPostPage
- [ ] 复用 CreatePostPage 的 UI 组件
- [ ] 加载现有帖子内容
- [ ] 支持修改文本、媒体、可见性
- [ ] 调用 `updatePost` Cloud Function

**后端**: `backend/functions/src/post_handler.ts`
- [ ] 实现 `updatePost` Cloud Function
- [ ] 验证用户权限（只能编辑自己的帖子）
- [ ] 更新 Firestore 文档

### 2.3 完善帖子删除功能
**文件**: `lib/pages/profile_page.dart`, `post_detail_page.dart`

**任务**:
- [ ] 在 PostCard 长按菜单添加删除选项
- [ ] 显示确认对话框
- [ ] 调用 `deletePost` API
- [ ] 从列表中移除已删除的帖子
- [ ] 更新用户的 postsCount

### 2.4 实现帖子可见性设置
**任务**:
- [ ] 在 CreatePostPage 和 EditPostPage 添加可见性选择器
- [ ] 选项: Public（所有人）, Private（仅自己）
- [ ] 在 Firebase 中保存 isPublic 字段
- [ ] ProfilePage 显示全部帖子（包括 private）
- [ ] PostFeedPage 只显示 public 帖子

---

## 阶段 3: 用户交互功能 (Phase 3: User Interaction Features)

### 3.1 点击头像跳转到用户 Profile
**文件**: 所有显示帖子的页面

**任务**:
- [ ] 在 PostCard 的头像上添加 GestureDetector
- [ ] 点击跳转到 `PublicProfilePage(userId: post.userId)`
- [ ] 在 PostDetailPage 的作者信息处添加点击跳转
- [ ] 在 CommentCard 的作者头像处添加点击跳转

### 3.2 完善 PublicProfilePage
**文件**: `lib/pages/public_profile_page.dart`

**任务**:
- [ ] 显示用户基本信息（头像、昵称、简介、关注/粉丝数）
- [ ] 显示用户的公开帖子（瀑布流布局）
- [ ] 添加关注/取消关注按钮
- [ ] 添加举报用户按钮
- [ ] 添加屏蔽用户按钮
- [ ] 如果是当前用户，显示"编辑资料"按钮

### 3.3 实现关注/取消关注功能
**后端**: `backend/functions/src/user_handler.ts`

**任务**:
- [ ] 实现 `followUser` Cloud Function
- [ ] 实现 `unfollowUser` Cloud Function
- [ ] 更新双方的 following/followers 集合
- [ ] 更新 followersCount 和 followingCount

**前端**: `lib/services/firebase_api_service.dart`
- [ ] 实现 `followUser(String targetUid)` 方法
- [ ] 实现 `unfollowUser(String targetUid)` 方法

### 3.4 完善评论功能
**任务**:
- [ ] 评论点赞功能（已有后端，需集成前端）
- [ ] 评论回复功能（显示层级关系）
- [ ] 评论举报功能
- [ ] 评论删除功能（仅作者可删除）

---

## 阶段 4: Profile 页面完善 (Phase 4: Profile Page Enhancement)

### 4.1 实现 Tab 切换功能
**文件**: `lib/pages/profile_page.dart`

**任务**:
- [ ] 添加 TabBar: "我的帖子", "点赞", "收藏"
- [ ] "我的帖子" Tab: 显示用户所有帖子（包括 private）
- [ ] "点赞" Tab: 从 `users/{uid}/likedPostIds` 获取并显示点赞的帖子
- [ ] "收藏" Tab: 从 `users/{uid}/favoritedPostIds` 获取并显示收藏的帖子

### 4.2 帖子管理功能
**任务**:
- [ ] 在"我的帖子"中，每个帖子右上角显示菜单按钮
- [ ] 菜单选项: 编辑、删除、设置可见性
- [ ] 长按帖子显示快捷菜单
- [ ] 批量删除功能（可选，后期实现）

### 4.3 获取点赞/收藏的帖子列表
**后端**: `backend/functions/src/post_handler.ts`

**任务**:
- [ ] 实现 `getLikedPosts` Cloud Function
- [ ] 实现 `getFavoritedPosts` Cloud Function
- [ ] 从用户的 likedPostIds/favoritedPostIds 批量获取帖子详情
- [ ] 过滤已删除的帖子

**前端**: `lib/services/firebase_api_service.dart`
- [ ] 实现 `getLikedPosts(String userId)` 方法
- [ ] 实现 `getFavoritedPosts(String userId)` 方法

---

## 阶段 5: 高级功能 (Phase 5: Advanced Features)

### 5.1 关注用户的帖子 Feed
**文件**: `lib/pages/following_feed_page.dart` (新建，可选)

**任务**:
- [ ] 创建"关注"Feed页面
- [ ] 从 `users/{uid}/followedBloggerIds` 获取关注列表
- [ ] 查询这些用户的最新帖子
- [ ] 按时间倒序排列
- [ ] 支持下拉刷新和分页加载

### 5.2 帖子举报功能集成
**文件**: 所有显示帖子的地方

**任务**:
- [ ] 在 PostCard 菜单中添加"举报"选项
- [ ] 使用已有的 `report_dialog.dart` 组件
- [ ] 调用 `report` API
- [ ] 显示举报成功提示

### 5.3 帖子搜索功能
**文件**: `lib/pages/post_search_page.dart` (新建，可选)

**任务**:
- [ ] 创建搜索页面
- [ ] 支持按关键词搜索帖子内容
- [ ] 支持按作者搜索
- [ ] 支持按标签搜索（如果有标签系统）
- [ ] 使用 Firestore 查询或 Algolia 搜索服务

### 5.4 帖子分享功能
**任务**:
- [ ] 在 PostCard 菜单中添加"分享"选项
- [ ] 支持分享到系统剪贴板
- [ ] 支持分享到社交媒体（可选）
- [ ] 生成帖子链接（需要 Deep Link 配置）

### 5.5 视频播放器优化
**文件**: `lib/widgets/video_player_widget.dart` (新建)

**任务**:
- [ ] 创建自定义视频播放器组件
- [ ] 支持播放/暂停、进度条、音量控制
- [ ] 支持全屏播放
- [ ] 在 PostCard 和 PostDetailPage 中使用
- [ ] 优化视频加载性能（预加载、缓存）

---

## 阶段 6: 性能优化和用户体验 (Phase 6: Performance & UX)

### 6.1 图片加载优化
**任务**:
- [ ] 使用 `cached_network_image` 包缓存网络图片
- [ ] 实现图片占位符和加载动画
- [ ] 支持图片点击查看大图
- [ ] 实现图片预加载

### 6.2 瀑布流性能优化
**任务**:
- [ ] 实现分页加载（Pagination）
- [ ] 使用 `ScrollController` 监听滚动，到底部时加载更多
- [ ] 添加"加载中"和"已加载全部"提示
- [ ] 优化渲染性能，避免不必要的 rebuild

### 6.3 离线支持
**任务**:
- [ ] 启用 Firestore 离线缓存
- [ ] 显示离线状态提示
- [ ] 离线时显示缓存的帖子
- [ ] 恢复在线时自动同步

### 6.4 错误处理和重试机制
**任务**:
- [ ] 统一错误提示 UI
- [ ] 网络错误时显示重试按钮
- [ ] 发帖失败时保存草稿
- [ ] 上传失败时支持重新上传

---

## 阶段 7: 测试和调试 (Phase 7: Testing & Debugging)

### 7.1 单元测试
**任务**:
- [ ] 测试 Post 模型的序列化/反序列化
- [ ] 测试 ApiService 的各个方法
- [ ] 测试 Cloud Functions

### 7.2 集成测试
**任务**:
- [ ] 测试发帖流程（创建、编辑、删除）
- [ ] 测试点赞、评论、收藏流程
- [ ] 测试关注/取消关注流程
- [ ] 测试举报流程

### 7.3 UI 测试
**任务**:
- [ ] 测试 PostCard 在不同屏幕尺寸下的显示
- [ ] 测试瀑布流布局
- [ ] 测试视频播放器
- [ ] 测试图片查看器

---

## 📊 数据模型完善

### Posts Collection
```firestore
posts/{postId}
  - postId: string
  - userId: string (作者 ID)
  - text: string (内容)
  - media: string[] (图片/视频 URL 数组)
  - mediaType: 'text' | 'image' | 'video'
  - isPublic: boolean
  - status: 'visible' | 'hidden' | 'removed'
  - likeCount: number
  - commentCount: number
  - favoriteCount: number
  - reportCount: number
  - createdAt: Timestamp
  - updatedAt: Timestamp
  
  // 子集合
  /likes/{userId}
    - likedAt: Timestamp
  
  /favorites/{userId}
    - favoritedAt: Timestamp
  
  /comments/{commentId}
    - userId: string
    - text: string
    - createdAt: Timestamp
    - likeCount: number
    /likes/{userId}
```

### Users Collection
```firestore
users/{userId}
  - uid: string
  - username: string
  - avatarUrl: string
  - bio: string
  - traits: string[]
  - freeText: string
  - followersCount: number
  - followingCount: number
  - postsCount: number
  - likedPostIds: string[] (冗余，用于快速查询)
  - favoritedPostIds: string[] (冗余，用于快速查询)
  - followedBloggerIds: string[] (冗余，用于快速查询)
  - lastActive: Timestamp
  - createdAt: Timestamp
  - isSuspended: boolean
  - reportCount: number
  - privacy: { visibility: string }
  
  // 子集合
  /following/{targetUserId}
    - followedAt: Timestamp
  
  /followers/{followerUserId}
    - followedAt: Timestamp
  
  /likes/{postId}
    - likedAt: Timestamp
  
  /favorites/{postId}
    - favoritedAt: Timestamp
  
  /blocks/{blockedUserId}
    - blockedAt: Timestamp
```

---

## 🔧 API 接口清单

### Post APIs
- ✅ `createPost(Post post)` - 创建帖子
- 🔲 `updatePost(String postId, Map<String, dynamic> updates)` - 更新帖子
- ✅ `deletePost(String postId)` - 删除帖子（软删除）
- ✅ `getPublicPosts()` - 获取公开帖子列表
- ✅ `getMyPosts(String userId)` - 获取用户的所有帖子
- 🔲 `getLikedPosts(String userId)` - 获取用户点赞的帖子
- 🔲 `getFavoritedPosts(String userId)` - 获取用户收藏的帖子
- 🔲 `getFollowingFeed(String userId)` - 获取关注用户的帖子
- ✅ `likePost(String postId)` - 点赞/取消点赞
- ✅ `toggleFavoritePost(String postId)` - 收藏/取消收藏

### Comment APIs
- ✅ `streamComments(String postId)` - 实时获取评论
- ✅ `addComment({String postId, String text})` - 添加评论
- ✅ `deleteComment({String postId, String commentId})` - 删除评论
- ✅ `likeComment({String postId, String commentId})` - 点赞评论

### User APIs
- ✅ `getUser(String uid)` - 获取用户信息
- ✅ `updateUser(UserData user)` - 更新用户信息
- 🔲 `followUser(String targetUid)` - 关注用户
- 🔲 `unfollowUser(String targetUid)` - 取消关注用户
- ✅ `blockUser(String blockedUid)` - 屏蔽用户
- ✅ `unblockUser(String blockedUid)` - 取消屏蔽

### Report API
- ✅ `report({...})` - 举报帖子或用户

### Upload API
- 🔲 `uploadMedia(File file, String path)` - 上传图片/视频

---

## 🎨 UI 风格保持指南

### 颜色方案
- 主色: `Color(0xFF992121)` (深红色)
- 背景: `Color(0xFFFDFBFA)` (米白色)
- 文字: Google Fonts - Cormorant Garamond (标题), Noto Serif SC (正文)

### 组件风格
- 圆角: 12-16px
- 阴影: `BoxShadow(color: Color(0x19000000), blurRadius: 10, offset: Offset(0, 5))`
- 卡片: 带渐变遮罩的图片背景
- 按钮: 圆角20px，主色背景

### 动画
- 页面切换: 淡入淡出
- 按钮点击: 缩放效果
- 列表加载: 从底部滑入

---

## 📅 实施时间表

- **Week 1**: 阶段 1 - 修复核心数据库问题
- **Week 2**: 阶段 2 - 完善帖子基础功能
- **Week 3**: 阶段 3 - 用户交互功能
- **Week 4**: 阶段 4 - Profile 页面完善
- **Week 5**: 阶段 5 - 高级功能
- **Week 6**: 阶段 6 - 性能优化和用户体验
- **Week 7**: 阶段 7 - 测试和调试

---

## 🚀 优先级排序

### P0 - 必须立即修复
1. ✅ 用户文档自动创建机制
2. ✅ 修复 createPost Cloud Function
3. ✅ 统一 PostCard 组件

### P1 - 核心功能
4. ✅ 帖子编辑功能
5. ✅ 帖子删除功能
6. ✅ 点击头像跳转功能
7. ✅ 完善 PublicProfilePage
8. ✅ 关注/取消关注功能
9. ✅ Profile 页面 Tab 切换

### P2 - 重要功能
10. ✅ 图片/视频上传到 Storage
11. ✅ 获取点赞/收藏的帖子列表
12. ✅ 帖子举报功能集成
13. ✅ 评论完善

### P3 - 可选功能
14. ⚪ 关注用户的帖子 Feed
15. ⚪ 帖子搜索功能
16. ⚪ 帖子分享功能
17. ⚪ 视频播放器优化

### P4 - 优化
18. ⚪ 图片加载优化
19. ⚪ 瀑布流性能优化
20. ⚪ 离线支持
21. ⚪ 错误处理和重试机制

---

## 📝 开发注意事项

1. **保持原有 UI 风格**: 所有新增功能必须符合现有的设计语言
2. **数据一致性**: 修改数据时确保 Firestore 和本地状态同步
3. **错误处理**: 所有网络请求必须有完善的错误处理和用户提示
4. **性能考虑**: 避免一次性加载过多数据，使用分页和懒加载
5. **安全性**: 所有敏感操作必须通过 Cloud Functions 进行，不要在客户端直接操作
6. **测试驱动**: 先写测试，再实现功能
7. **代码复用**: 提取公共组件和方法，避免重复代码
8. **文档更新**: 每完成一个功能，更新相应的文档

---

## 🎯 下一步行动

立即开始 **阶段 1** 的实施：

1. 修复用户文档创建机制
2. 修复 createPost Cloud Function
3. 测试发帖流程

完成后继续 **阶段 2**，逐步完善所有功能。
