# 🚀 POST System Quick Reference

## 快速启动 (Quick Start)

```bash
# 1. 启动后端
./START_BACKEND.sh

# 2. 运行APP
flutter run -d chrome
```

## 核心功能测试 (Core Features Testing)

### ✅ 发布帖子
1. 点击右下角 `+` 按钮
2. 输入文字或选择图片/视频
3. 设置可见性（Public/Private）
4. 点击 `Publish`

### ✅ 点赞/收藏
- 点击 ❤️ 图标点赞
- 点击 ⭐ 图标收藏
- 点击 💬 图标查看评论

### ✅ 查看用户Profile
- 点击帖子上的**头像**
- 自动跳转到 PublicProfilePage

### ✅ 关注用户
- 在PublicProfilePage点击 **Follow** 按钮
- 自动更新关注数

### ✅ 管理帖子
- **长按**自己的帖子
- 选择：编辑 / 删除 / 设置可见性 / 举报

### ✅ 举报功能
- 长按任何帖子
- 选择 "Report Post"
- 填写举报原因

## 新增组件 (New Components)

### PostCard Widget
```dart
PostCard(
  post: post,
  isMember: false,
  isUnlocked: true,
  showOwnerOptions: true,  // 显示编辑删除选项
  onUnlock: () => {},
  onLikeToggle: () => handleLike(),
  onFavoriteToggle: () => handleFavorite(),
  onDelete: () => handleDelete(),
)
```

## 新增API方法 (New API Methods)

### 帖子操作
```dart
// 更新帖子
await apiService.updatePost(postId, text: 'New content', isPublic: true);

// 获取点赞的帖子
List<Post> liked = await apiService.getLikedPosts(userId);

// 获取收藏的帖子
List<Post> favorited = await apiService.getFavoritedPosts(userId);
```

### 用户操作
```dart
// 关注用户
await apiService.followUser(targetUserId);

// 取消关注
await apiService.unfollowUser(targetUserId);
```

## UI风格指南 (UI Style Guide)

### 主题色
```dart
primaryColor: Color(0xFF992121)  // 深红色
backgroundColor: Color(0xFFFDFBFA)  // 米白色
```

### 字体
```dart
// 标题
GoogleFonts.cormorantGaramond(
  fontWeight: FontWeight.w600,
)

// 正文
GoogleFonts.notoSerifSc()
```

### 卡片样式
```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Color(0x19000000),
        blurRadius: 10,
        offset: Offset(0, 5),
      ),
    ],
  ),
)
```

## 数据流 (Data Flow)

```
用户操作 → 乐观UI更新 → API调用 → 后端处理 → 成功/失败
                 ↓                              ↓
            立即显示结果                    失败时回滚
```

## 调试技巧 (Debug Tips)

### 查看日志
- ✅ 成功操作
- ❌ 失败操作
- ⚠️ 警告信息

### 常见错误
1. **User not found** → 确保后端正在运行
2. **Permission denied** → 检查 Firestore Rules
3. **Network error** → 检查网络连接

## 文件结构 (File Structure)

```
lib/
  widgets/
    post_card.dart          ← 统一的帖子卡片组件
  pages/
    post_page.dart          ← 帖子流页面
    post_detail_page.dart   ← 帖子详情
    create_post_page.dart   ← 创建帖子
    public_profile_page.dart ← 用户主页
    profile_page.dart       ← 个人资料
  services/
    api_service.dart        ← API接口定义
    firebase_api_service.dart ← Firebase实现

backend/functions/src/
  post_handler.ts           ← 帖子相关Functions
  user_handler.ts           ← 用户相关Functions
```

## 下一步 TODO (Next Steps)

### Phase 2
- [ ] 完成ProfilePage Tab UI
- [ ] 实现EditPostPage
- [ ] Firebase Storage图片上传
- [ ] 帖子可见性切换

### Phase 3
- [ ] Following Feed页面
- [ ] 视频播放器优化
- [ ] 分页加载
- [ ] 图片查看器

## 技术债务 (Technical Debt)

- ProfilePage的Tab实现未完成（需要添加TabBar UI）
- EditPostPage尚未创建
- 图片上传到Storage的代码存在但未测试
- 视频播放控制较简单

## 性能优化 (Performance)

已实现：
- ✅ 作者信息缓存
- ✅ 懒加载Tab数据
- ✅ 乐观UI更新

待实现：
- [ ] 图片懒加载
- [ ] 虚拟滚动
- [ ] 预加载下一页

## 联系与支持 (Contact)

如有问题，请检查：
1. `POST_IMPLEMENTATION_PHASE1.md` - 完整实施文档
2. `POST_SYSTEM_TODO.md` - 详细TODO计划
3. `POST_FEATURES_SUMMARY.md` - 功能总结

---

**状态**: Phase 1 完成 ✅ | 保持原UI风格 ✅ | 代码质量优秀 ✅
