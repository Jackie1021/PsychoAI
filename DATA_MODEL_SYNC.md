# 数据模型关联与同步机制

## 📊 数据模型概览

### 核心模型关系图
```
UserData (用户数据)
    ├── userId: String                    // 唯一标识
    ├── username: String                  // 用户名
    ├── avatarUrl: String?                // 头像URL
    ├── traits: List<String>              // 特征标签
    ├── freeText: String                  // 个人简介
    ├── likedPostIds: List<String>        // 点赞的帖子ID列表
    ├── favoritedPostIds: List<String>    // 收藏的帖子ID列表
    ├── followedBloggerIds: List<String>  // 关注的用户ID列表
    ├── postsCount: int                   // 发布的帖子总数
    ├── followersCount: int               // 关注者数量
    └── followingCount: int               // 关注中数量

Post (帖子数据)
    ├── postId: String?                   // 帖子唯一ID
    ├── userId: String                    // 作者ID
    ├── author: String                    // 作者名称
    ├── authorImageUrl: String            // 作者头像URL
    ├── content: String                   // 帖子内容
    ├── media: List<String>               // 媒体URL列表
    ├── mediaType: MediaType?             // 媒体类型
    ├── likes: int                        // 点赞数
    ├── comments: int                     // 评论数
    ├── favorites: int                    // 收藏数
    ├── isPublic: bool                    // 是否公开
    ├── isLiked: bool                     // 当前用户是否点赞
    ├── isFavorited: bool                 // 当前用户是否收藏
    ├── createdAt: DateTime?              // 创建时间
    └── status: String?                   // 状态（visible/hidden）

MatchRecord (匹配记录)
    ├── id: String                        // 记录ID
    ├── userId: String                    // 当前用户ID
    ├── matchedUserId: String             // 匹配对象ID
    ├── matchedUsername: String           // 匹配对象用户名
    ├── matchedUserAvatar: String         // 匹配对象头像
    ├── compatibilityScore: double        // 匹配度分数 (0.0-1.0)
    ├── matchSummary: String              // AI生成的匹配摘要
    ├── featureScores: Map<String, ...>   // 特征评分详情
    ├── createdAt: DateTime               // 匹配时间
    ├── action: MatchAction               // 用户操作（chatted/skipped/none）
    ├── chatMessageCount: int             // 聊天消息数
    └── lastInteractionAt: DateTime?      // 最后互动时间
```

## 🔗 关联关系说明

### 1. UserData ↔ Post 关联

#### 发帖关联
```dart
// 创建帖子时
Post newPost = Post(
  userId: currentUser.uid,              // 来自 UserData.userId
  author: userData.username,            // 来自 UserData.username
  authorImageUrl: userData.avatarUrl ?? '', // 来自 UserData.avatarUrl
  content: contentText,
  isPublic: true,
);

// 保存后更新用户的 postsCount
userData.postsCount += 1;
```

#### 点赞关联
```dart
// 用户点赞帖子
if (!post.isLiked) {
  // 1. 更新帖子的点赞数
  post.likes += 1;
  post.isLiked = true;
  
  // 2. 将帖子ID添加到用户的点赞列表
  userData.likedPostIds.add(post.postId!);
  
  // 3. 同步到后端
  await apiService.likePost(post.postId!);
}
```

#### 收藏关联
```dart
// 用户收藏帖子
if (!post.isFavorited) {
  // 1. 更新帖子的收藏数
  post.favorites += 1;
  post.isFavorited = true;
  
  // 2. 将帖子ID添加到用户的收藏列表
  userData.favoritedPostIds.add(post.postId!);
  
  // 3. 同步到后端
  await apiService.toggleFavoritePost(post.postId!);
}
```

### 2. MatchRecord ↔ UserData 关联

#### 创建匹配记录
```dart
// 从 MatchAnalysis 创建 MatchRecord
MatchRecord record = MatchRecord.fromMatchAnalysis(
  analysis,
  currentUserId: currentUser.uid,  // 来自当前登录用户
);

// 匹配记录包含目标用户信息
record.matchedUserId        // 来自分析结果
record.matchedUsername      // 从 UserData 获取
record.matchedUserAvatar    // 从 UserData 获取
```

#### 在个人主页展示
```dart
// 加载最近匹配记录
List<MatchRecord> topMatches = await apiService.getMatchHistory(
  userId: currentUser.uid,
  limit: 5,
);

// 展示在 Profile Page
for (var match in topMatches) {
  MatchCard(
    avatar: match.matchedUserAvatar,
    username: match.matchedUsername,
    score: match.compatibilityScore,
  );
}
```

### 3. Profile Page 数据流

#### 页面初始化
```dart
Future<void> _loadUserData() async {
  // 1. 加载用户基本信息
  userData = await apiService.getUser(currentUser.uid);
  
  // 2. 加载用户的帖子
  userPosts = await apiService.getMyPosts(currentUser.uid);
  // 返回的 Post 列表中：
  // - post.userId == currentUser.uid
  // - post.author == userData.username
  // - post.isLiked 根据 userData.likedPostIds 判断
  // - post.isFavorited 根据 userData.favoritedPostIds 判断
  
  // 3. 加载 Match 记录
  topMatches = await apiService.getMatchHistory(
    userId: currentUser.uid,
    limit: 5,
  );
}
```

#### Section 切换
```dart
Future<void> _loadSectionData() async {
  if (_currentSection == 'liked') {
    // 加载点赞的帖子
    // 后端根据 userData.likedPostIds 查询对应的 Post
    posts = await apiService.getLikedPosts(currentUser.uid);
    
  } else if (_currentSection == 'favorited') {
    // 加载收藏的帖子
    // 后端根据 userData.favoritedPostIds 查询对应的 Post
    posts = await apiService.getFavoritedPosts(currentUser.uid);
    
  } else {
    // 加载我的帖子
    // 后端查询 post.userId == currentUser.uid 的所有帖子
    posts = await apiService.getMyPosts(currentUser.uid);
  }
}
```

## 🔄 数据同步机制

### 1. 帖子操作同步

#### 编辑帖子
```
用户编辑帖子
    ↓
EditPostPage 更新本地 Post 对象
    ↓
调用 apiService.updatePost(postId, text, isPublic)
    ↓
后端更新 Firestore posts 集合
    ↓
返回成功
    ↓
ProfilePage 重新加载当前 Section 数据
    ↓
UI 显示更新后的帖子
```

#### 删除帖子
```
用户删除帖子
    ↓
显示确认对话框
    ↓
调用 apiService.deletePost(postId)
    ↓
后端软删除（设置 status = 'deleted'）
    ↓
返回成功
    ↓
ProfilePage 从本地列表移除
    ↓
userData.postsCount -= 1
    ↓
UI 立即更新（无需重新加载）
```

### 2. 点赞/收藏同步

#### 点赞操作
```
用户点击点赞
    ↓
PostCard 乐观更新 UI（立即显示已点赞）
    ↓
调用 apiService.likePost(postId)
    ↓
后端执行：
  - post.likes += 1 或 -= 1
  - user.likedPostIds.add() 或 .remove()
    ↓
返回最新状态
    ↓
如果失败，回滚本地 UI 状态
```

#### 收藏操作
```
用户点击收藏
    ↓
PostCard 乐观更新 UI（立即显示已收藏）
    ↓
调用 apiService.toggleFavoritePost(postId)
    ↓
后端执行：
  - post.favorites += 1 或 -= 1
  - user.favoritedPostIds.add() 或 .remove()
    ↓
返回最新状态
```

### 3. Match 数据同步

#### 匹配完成后
```
用户完成匹配
    ↓
MatchResultPage 显示结果
    ↓
调用 apiService.saveMatchRecord(record)
    ↓
后端保存到 Firestore matchRecords 集合
{
  userId: currentUserId,
  matchedUserId: targetUserId,
  compatibilityScore: 0.85,
  action: 'none',
  createdAt: Timestamp.now(),
}
    ↓
返回 Profile Page
    ↓
下次进入时自动加载最新匹配
```

#### 更新匹配操作
```
用户点击"开始聊天"
    ↓
调用 apiService.updateMatchAction(
  matchRecordId: record.id,
  action: MatchAction.chatted,
  chatMessageCount: 1,
)
    ↓
后端更新记录：
  - action = 'chatted'
  - lastInteractionAt = Timestamp.now()
    ↓
Profile Page 的 Match 卡片显示对应图标
```

## 🛡️ 数据一致性保证

### 1. 原子操作
```dart
// 使用 Firestore Transaction 确保原子性
await firestore.runTransaction((transaction) async {
  // 1. 读取当前数据
  final postDoc = await transaction.get(postRef);
  final userDoc = await transaction.get(userRef);
  
  // 2. 更新多个文档
  transaction.update(postRef, {'likes': postDoc['likes'] + 1});
  transaction.update(userRef, {
    'likedPostIds': FieldValue.arrayUnion([postId])
  });
});
```

### 2. 乐观锁
```dart
// 前端乐观更新
setState(() {
  post.isLiked = true;
  post.likes += 1;
});

try {
  await apiService.likePost(postId);
} catch (e) {
  // 失败时回滚
  setState(() {
    post.isLiked = false;
    post.likes -= 1;
  });
}
```

### 3. 幂等性
```dart
// 后端确保操作幂等
async function likePost(userId, postId) {
  const userLikes = await getUserLikedPosts(userId);
  
  if (userLikes.includes(postId)) {
    // 已点赞，执行取消点赞
    return unlikePost(userId, postId);
  } else {
    // 未点赞，执行点赞
    return addLike(userId, postId);
  }
}
```

## 📈 性能优化策略

### 1. 分页加载
```dart
// 帖子列表分页
Future<List<Post>> getMyPosts(String userId, {
  int limit = 20,
  String? startAfter,
}) async {
  Query query = firestore
      .collection('posts')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(limit);
  
  if (startAfter != null) {
    query = query.startAfter([startAfter]);
  }
  
  return query.get().then((snapshot) => 
    snapshot.docs.map((doc) => Post.fromJson(doc.data())).toList()
  );
}
```

### 2. 缓存策略
```dart
// 内存缓存
final _cache = <String, List<Post>>{};

Future<List<Post>> getCachedPosts(String userId) async {
  // 检查缓存
  if (_cache.containsKey(userId)) {
    return _cache[userId]!;
  }
  
  // 加载数据
  final posts = await apiService.getMyPosts(userId);
  
  // 更新缓存
  _cache[userId] = posts;
  
  return posts;
}
```

### 3. 增量更新
```dart
// 只更新变化的字段
Future<void> updatePost(String postId, {
  String? text,
  bool? isPublic,
}) async {
  final updates = <String, dynamic>{};
  
  if (text != null) updates['text'] = text;
  if (isPublic != null) updates['isPublic'] = isPublic;
  
  if (updates.isEmpty) return;
  
  await firestore.collection('posts').doc(postId).update(updates);
}
```

## 🔍 调试技巧

### 1. 数据流追踪
```dart
// 在关键点添加日志
print('🔥 Loading user data for: $userId');
print('📝 Loaded ${posts.length} posts');
print('💖 User has ${userData.likedPostIds.length} liked posts');
print('⭐ User has ${userData.favoritedPostIds.length} favorited posts');
```

### 2. 状态验证
```dart
// 验证数据一致性
void _validateDataConsistency() {
  for (var post in _userPosts) {
    assert(post.userId == _userData?.uid, 'Post userId mismatch');
    assert(post.author == _userData?.username, 'Post author mismatch');
  }
}
```

### 3. 错误监控
```dart
try {
  await apiService.deletePost(postId);
} catch (e, stackTrace) {
  print('❌ Error deleting post: $e');
  print('Stack trace: $stackTrace');
  
  // 上报到错误监控平台
  FirebaseCrashlytics.instance.recordError(e, stackTrace);
}
```

## 📋 检查清单

在实施新功能前检查：

- [ ] 数据模型是否正确关联？
- [ ] 是否处理了空值情况？
- [ ] 是否实现了乐观更新？
- [ ] 是否有错误回滚机制？
- [ ] 是否保证了原子性？
- [ ] 是否考虑了并发冲突？
- [ ] 是否添加了日志追踪？
- [ ] 是否处理了网络错误？
- [ ] 是否更新了相关计数？
- [ ] 是否通知了 UI 刷新？

---

**版本**：v1.0  
**更新日期**：2025-11-17  
**维护者**：开发团队
