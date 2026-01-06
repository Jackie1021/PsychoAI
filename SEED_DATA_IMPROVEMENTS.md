# SEED_DATA 改进说明

## ✅ 为什么改进 SEED_DATA 很重要

你的发现非常正确！`SEED_DATA.sh` 与我们解决的数据同步问题**直接相关**。

### 原问题回顾
之前的错误：
```
Cannot read properties of undefined (reading 'documentId')
```

**根本原因**：
- 用户的 `likedPostIds` 或 `favoritedPostIds` 数组中可能包含无效值（null、undefined、空字符串）
- 查询这些无效 ID 时 Firestore 报错

### 原 SEED_DATA 的问题

**旧版本**：
```javascript
likedPostIds: [],        // 空数组
favoritedPostIds: [],    // 空数组
```

**问题**：
1. ❌ 没有真实的测试数据
2. ❌ 无法测试点赞/收藏功能
3. ❌ 无法测试跨页面数据同步
4. ❌ Profile Page 的 Liked/Favorited tab 永远是空的

## 🎯 新版本的改进

### 1. 创建真实的交互数据

**新增函数** `createTestInteractions(users, postIds)`：

```javascript
async function createTestInteractions(users, postIds) {
  console.log('💫 Creating test interactions (likes/favorites)...');
  
  for (const user of users) {
    // 每个用户随机点赞 2-3 个帖子
    const numLikes = Math.floor(Math.random() * 2) + 2;
    // 每个用户随机收藏 1-2 个帖子
    const numFavorites = Math.floor(Math.random() * 2) + 1;
    
    // 随机选择帖子
    const postsToLike = [...postIds]
      .sort(() => Math.random() - 0.5)
      .slice(0, numLikes);
    
    const postsToFavorite = [...postIds]
      .sort(() => Math.random() - 0.5)
      .slice(0, numFavorites);
    
    // 创建 likes 子集合
    for (const postId of postsToLike) {
      await db.collection('posts').doc(postId)
        .collection('likes').doc(user.uid).set({
          likedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      await db.collection('posts').doc(postId).update({
        likeCount: admin.firestore.FieldValue.increment(1),
      });
    }
    
    // 创建 favorites 子集合（双向）
    for (const postId of postsToFavorite) {
      // posts/{postId}/favorites/{userId}
      await db.collection('posts').doc(postId)
        .collection('favorites').doc(user.uid).set({
          favoritedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      
      // users/{userId}/favorites/{postId}
      await db.collection('users').doc(user.uid)
        .collection('favorites').doc(postId).set({
          favoritedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      
      await db.collection('posts').doc(postId).update({
        favoriteCount: admin.firestore.FieldValue.increment(1),
      });
    }
    
    // 更新用户数组（确保只有有效 ID）
    await db.collection('users').doc(user.uid).update({
      likedPostIds: postsToLike.filter(id => id && id.trim().length > 0),
      favoritedPostIds: postsToFavorite.filter(id => id && id.trim().length > 0),
    });
  }
}
```

### 2. 数据完整性保证

**关键改进**：
```javascript
// 确保返回 post IDs
const postRef = await db.collection('posts').add(postData);
createdPostIds.push(postRef.id);

// 过滤无效 ID
likedPostIds: postsToLike.filter(id => id && id.trim().length > 0),
favoritedPostIds: postsToFavorite.filter(id => id && id.trim().length > 0),
```

### 3. 完整的数据关系

**创建的数据结构**：

```
users/{userId}
  ├── likedPostIds: [postId1, postId2, ...]      // ✅ 有效的 post IDs
  ├── favoritedPostIds: [postId3, postId4, ...]  // ✅ 有效的 post IDs
  └── favorites/{postId}                          // ✅ 收藏子集合
      └── favoritedAt: timestamp

posts/{postId}
  ├── likeCount: 2                                // ✅ 点赞数
  ├── favoriteCount: 1                            // ✅ 收藏数
  ├── likes/{userId}                              // ✅ 点赞子集合
  │   └── likedAt: timestamp
  └── favorites/{userId}                          // ✅ 收藏子集合
      └── favoritedAt: timestamp
```

## 📊 测试数据示例

运行 `./SEED_DATA.sh` 后会创建：

```
👥 6 个测试用户
  - alice@test.com
  - bob@test.com
  - charlie@test.com
  - diana@test.com
  - eve@test.com
  - frank@test.com

📝 8-12 个帖子 (每个用户 1-2 个)

💫 交互数据
  - 每个用户点赞 2-3 个帖子
  - 每个用户收藏 1-2 个帖子
  - 所有 ID 都是有效的
  - 子集合和数组完全同步
```

## 🧪 现在可以测试的场景

### 1. Profile Page - Liked Tab
```
登录 alice@test.com
→ 进入 Profile Page
→ 点击 "Liked" tab
✅ 显示 2-3 个 Alice 点赞的帖子
```

### 2. Profile Page - Favorited Tab
```
登录 alice@test.com
→ 进入 Profile Page
→ 点击 "Favorited" tab
✅ 显示 1-2 个 Alice 收藏的帖子
```

### 3. Post Page - 查看状态
```
登录 alice@test.com
→ 进入 Post Page
✅ 已点赞的帖子显示红色 ❤️
✅ 已收藏的帖子显示黄色 ⭐
```

### 4. 取消点赞/收藏
```
在 Profile Page → Liked
→ 点击 ❤️ 取消点赞
✅ 帖子从列表中消失
✅ 切换到 Post Page，该帖子显示为未点赞
```

### 5. 跨页面同步
```
在 Post Page 点赞新帖子
→ 切换到 Profile Page → Liked
✅ 新点赞的帖子出现在列表中
```

## 🔧 与后端修复的配合

### 后端修复 (已完成)
```typescript
// backend/functions/src/post_handler.ts
const rawLikedPostIds = userData?.likedPostIds || [];
const likedPostIds = rawLikedPostIds.filter(
  (id: any) => id && typeof id === 'string' && id.trim().length > 0
);
```

### Seed 数据保证 (新增)
```javascript
// scripts/seed_emulator.js
likedPostIds: postsToLike.filter(id => id && id.trim().length > 0),
favoritedPostIds: postsToFavorite.filter(id => id && id.trim().length > 0),
```

**双重保护**：
1. ✅ Seed 确保写入的都是有效 ID
2. ✅ Backend 过滤掉任何无效 ID（防御性编程）

## 🚀 使用方法

### 重新生成测试数据

```bash
# 1. 确保后端运行
./START_BACKEND.sh

# 2. 等待几秒，然后清空并重新生成数据
./SEED_DATA.sh

# 3. 启动 Flutter 应用
flutter run -d chrome

# 4. 使用测试账号登录
# alice@test.com / test123456
```

### 验证数据

```bash
# 查看某个用户的数据
curl -s http://localhost:8081/v1/projects/studio-291983403-af613/databases/(default)/documents/users | jq

# 查看帖子数据
curl -s http://localhost:8081/v1/projects/studio-291983403-af613/databases/(default)/documents/posts | jq
```

## 📝 总结

改进 SEED_DATA 的原因：

1. ✅ **修复根源**：确保测试数据没有无效 ID
2. ✅ **真实场景**：提供可测试的点赞/收藏数据
3. ✅ **完整测试**：可以测试所有跨页面同步功能
4. ✅ **防止回退**：保证每次重置数据都是干净的
5. ✅ **开发效率**：快速验证功能是否正常

**结论**：你的观察非常准确，SEED_DATA 与我们的问题解决方案紧密相关，现在已经完全改进！
