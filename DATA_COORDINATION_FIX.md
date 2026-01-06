# Data Coordination Fix - Profile & Post Pages

## 问题分析

之前的报错是由于 `getLikedPosts` 和 `getFavoritedPosts` 函数在处理用户的点赞和收藏列表时，遇到了无效的 post ID（null、undefined 或空字符串），导致 Firestore 查询失败。

错误信息：
```
Cannot read properties of undefined (reading 'documentId')
```

## 修复内容

### 1. 后端修复 (backend/functions/src/post_handler.ts)

#### getLikedPosts 函数
- 添加了对 `likedPostIds` 数组的过滤，移除无效 ID
- 确保只查询有效的 post ID

```typescript
const rawLikedPostIds = userData?.likedPostIds || [];
const likedPostIds = rawLikedPostIds.filter(
  (id: any) => id && typeof id === 'string' && id.trim().length > 0
);
```

#### getFavoritedPosts 函数
- 同样添加了对 `favoritedPostIds` 数组的过滤
- 防止查询无效的 document ID

### 2. 前端修复 - Profile Page (lib/pages/profile_page.dart)

#### 新增功能
1. **点赞处理函数** `_handleLikeToggle(Post post)`
   - 调用 API 切换点赞状态
   - 自动重新加载当前 section 数据
   - 同步更新用户数据中的 likedPostIds

2. **收藏处理函数** `_handleFavoriteToggle(Post post)`
   - 调用 API 切换收藏状态
   - 自动重新加载当前 section 数据
   - 同步更新用户数据中的 favoritedPostIds

3. **改进 _loadSectionData 函数**
   - 在加载 section 数据时同时刷新用户数据
   - 确保 liked/favorited 数组与服务器保持同步

4. **更新 _PostCard 组件**
   - 添加 `onLike` 和 `onFavorite` 回调
   - 点赞/收藏按钮变为可交互
   - 显示实时的点赞/收藏状态（填充/空心图标）

### 3. 前端修复 - Post Page (lib/pages/post_page.dart)

#### 数据同步改进
- 在 `_handleLikeToggle` 后调用 `_loadCurrentUser()` 刷新用户数据
- 在 `_handleFavoriteToggle` 后调用 `_loadCurrentUser()` 刷新用户数据
- 确保用户的 likedPostIds 和 favoritedPostIds 数组实时更新

## 数据流程

### 点赞流程
1. 用户点击点赞按钮
2. 调用 `likePost` Cloud Function
3. 更新 Firestore:
   - posts/{postId}.likeCount ±1
   - posts/{postId}/likes/{userId} 创建/删除
   - users/{userId}.likedPostIds arrayUnion/arrayRemove
4. 前端更新本地 post 对象
5. 刷新用户数据，同步 likedPostIds 数组
6. 如在 profile 页面，重新加载当前 section

### 收藏流程
1. 用户点击收藏按钮
2. 调用 `toggleFavoritePost` Cloud Function
3. 更新 Firestore:
   - posts/{postId}.favoriteCount ±1
   - posts/{postId}/favorites/{userId} 创建/删除
   - users/{userId}.favoritedPostIds arrayUnion/arrayRemove
4. 前端更新本地 post 对象
5. 刷新用户数据，同步 favoritedPostIds 数组
6. 如在 profile 页面，重新加载当前 section

## 跨页面数据同步

### 场景 1: Post Page → Profile Page
- 用户在 Post Page 点赞/收藏
- 切换到 Profile Page
- Profile Page 加载时自动获取最新的用户数据
- likedPostIds 和 favoritedPostIds 已经同步

### 场景 2: Profile Page 内操作
- 用户在 "Liked" 或 "Favorited" tab
- 点击取消点赞/收藏
- 立即重新加载该 section
- post 从列表中移除（如果完全取消）
- 用户数据同步更新

### 场景 3: 订阅状态同步
- 用户数据模型包含 membershipTier、membershipExpiry、subscriptionId
- 每次加载页面时获取最新用户数据
- hasActiveMembership 计算属性自动判断订阅是否有效
- effectiveTier 返回实际可用的会员等级

## 测试建议

1. **点赞功能测试**
   - 在 Post Page 点赞帖子
   - 切换到 Profile Page → Liked tab
   - 确认帖子出现在列表中
   - 取消点赞，确认帖子从列表移除

2. **收藏功能测试**
   - 在 Post Page 收藏帖子
   - 切换到 Profile Page → Favorited tab
   - 确认帖子出现在列表中
   - 取消收藏，确认帖子从列表移除

3. **跨页面同步测试**
   - 在一个页面操作后
   - 切换到另一个页面
   - 确认数据已同步

4. **订阅状态测试**
   - 购买订阅
   - 刷新页面确认会员徽章显示
   - 检查 Profile Page 的会员标识
   - 验证 Post Page 的解锁功能

## 注意事项

1. **避免重复刷新**
   - 只在必要时刷新用户数据
   - profile_page 在 section 切换时会自动刷新

2. **错误处理**
   - 所有 API 调用都有 try-catch
   - 失败时显示 SnackBar 提示用户

3. **性能优化**
   - getLikedPosts/getFavoritedPosts 使用批量查询（每批10个）
   - 过滤无效 ID 减少查询错误

4. **UI 反馈**
   - 点赞/收藏状态用图标颜色区分
   - 数字实时更新
   - 操作有加载提示

## 未来改进方向

1. **实时监听**
   - 使用 Firestore streams 监听用户数据变化
   - 自动同步而不需要手动刷新

2. **本地缓存**
   - 缓存用户的 liked/favorited 列表
   - 减少网络请求

3. **乐观更新**
   - 先更新 UI，后台同步数据
   - 失败时回滚

4. **批量操作**
   - 支持批量点赞/收藏
   - 提高效率
