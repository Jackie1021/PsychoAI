# 用户资料卡片与隐私设置功能实现路线图

## 📋 项目概述

实现社交APP的核心功能：
1. **聊天页面顶部显示用户信息**（头像+ID）
2. **用户资料卡片系统**（ProfileCard - 类似小红书的简历卡片）
3. **完善的用户隐私设置页面**
4. **订阅解锁机制**（每日免费额度 + 订阅会员无限查看）
5. **对外公开主页**（展示部分posts、traits、match记录）

---

## 🎯 核心功能模块

### 模块 1: 新增数据模型 `ProfileCard`

**文件**: `lib/models/profile_card.dart`

```dart
class ProfileCard {
  final String uid;
  final String username;
  final String? avatarUrl;
  final String bio;
  final List<String> highlightedTraits;  // 精选特质（最多5个）
  final int postsCount;
  final int matchesCount;
  final List<String> featuredPostIds;    // 精选帖子ID（最多3个）
  final List<String> publicMatchIds;     // 公开的match记录ID（用户可选择）
  final ProfileCardPrivacySettings privacy;
  final DateTime lastUpdated;
  final MembershipTier membershipTier;
  
  // 统计信息
  final int viewCount;                   // 被查看次数
  final int likeCount;                   // 资料卡被点赞次数
}

class ProfileCardPrivacySettings {
  final bool showTraits;                // 是否显示特质
  final bool showPosts;                 // 是否显示帖子
  final bool showMatches;               // 是否显示match记录
  final bool showStats;                 // 是否显示统计数据
  final bool allowStranger访问;         // 是否允许陌生人查看
}
```

**Firestore 集合**:
- `profileCards/{uid}`: 存储用户的资料卡片
- 安全规则: 只有本人可写，读取受隐私设置控制

---

### 模块 2: 用户隐私设置扩展

**文件**: `lib/models/user_privacy_settings.dart`

```dart
class UserPrivacySettings {
  // 个人资料可见性
  final ProfileVisibility profileVisibility;     // public/friends/private
  final bool showAvatarToStrangers;
  final bool showBioToStrangers;
  final bool showTraitsToStrangers;
  
  // 内容可见性
  final PostVisibility defaultPostVisibility;
  final bool allowComments;
  final bool allowShare;
  
  // 交互设置
  final bool allowMessageFromStrangers;
  final bool allowMatchFromStrangers;
  
  // 资料卡设置
  final bool enableProfileCard;
  final bool profileCardRequiresSubscription;
  
  // 黑名单
  final List<String> blockedUserIds;
}

enum ProfileVisibility { public, friendsOnly, private }
enum PostVisibility { public, followers, private }
```

**Firestore 集合**:
- `users/{uid}/private/privacy_settings`: 私密配置
- 安全规则: 仅本人可读写

---

### 模块 3: 查看权限与订阅系统

**文件**: `lib/services/profile_card_service.dart`

```dart
class ProfileCardService {
  // 每日查看配额
  static const int FREE_VIEWS_PER_DAY = 3;
  
  // 检查是否可以查看资料卡
  Future<ViewPermission> checkViewPermission(String targetUserId);
  
  // 记录查看行为
  Future<void> recordView(String targetUserId);
  
  // 获取今日已使用的免费次数
  Future<int> getTodayUsedViews();
  
  // 订阅后无限查看
  Future<bool> hasActiveSubscription();
}

class ViewPermission {
  final bool canView;
  final ViewBlockReason? reason;
  final int remainingFreeViews;
}

enum ViewBlockReason {
  noSubscriptionAndQuotaExceeded,
  blockedByUser,
  privacyRestriction,
  userSuspended,
}
```

**Firestore 集合**:
- `profileCardViews/{uid}/daily/{date}`: 记录每日查看次数
- `profileCardViews/{uid}/history`: 查看历史记录

---

### 模块 4: UI 页面实现

#### 4.1 聊天页面顶部增强 
**文件**: `lib/pages/chat_page_new.dart`（修改）

```dart
AppBar(
  title: GestureDetector(
    onTap: () => _openProfileCard(otherUserId),
    child: Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(otherUser.avatarUrl),
          radius: 18,
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherUser.username),
            Text(
              '@${otherUser.uid.substring(0, 8)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    ),
  ),
)
```

#### 4.2 资料卡片页面
**文件**: `lib/pages/profile_card_page.dart`（新建）

设计风格：
- 卡片式设计，毛玻璃效果
- 顶部：头像 + 用户名 + 会员标识
- 中部：精选特质（chips）+ bio
- 底部：精选帖子缩略图（横向滚动）
- 统计栏：posts/matches/followers
- 底部按钮：关注、私信、举报

参考颜色：
- 主色调：延续现有的 primary color
- 卡片背景：白色/浅色 + 阴影
- 会员标识：金色渐变

#### 4.3 隐私设置页面
**文件**: `lib/pages/privacy_settings_page.dart`（新建）

分组设置：
1. **资料可见性**
   - 谁可以看我的主页
   - 资料卡启用/禁用
   - 是否需要订阅才能查看资料卡

2. **内容隐私**
   - 帖子默认可见性
   - 是否允许评论/分享

3. **交互设置**
   - 陌生人能否发消息
   - 陌生人能否匹配

4. **黑名单管理**
   - 查看已屏蔽用户
   - 解除屏蔽

#### 4.4 用户设置页面扩展
**文件**: `lib/pages/edit_profile_page.dart`（修改）

新增入口：
- 管理资料卡
- 隐私设置
- 订阅管理
- 账号安全

#### 4.5 公开主页
**文件**: `lib/pages/public_profile_page.dart`（新建）

显示内容：
- 基本信息（头像、用户名、bio）
- 公开的特质
- 用户发布的帖子（瀑布流）
- 公开的match记录（需征得双方同意）
- 关注/粉丝统计

---

### 模块 5: 订阅解锁弹窗

**文件**: `lib/widgets/subscription_prompt_dialog.dart`（新建）

功能：
- 显示当前免费次数使用情况
- 展示订阅权益
- 跳转到订阅页面
- 优雅的动画效果

设计：
```
┌─────────────────────────────┐
│   🔒 解锁更多资料卡片        │
│                             │
│  今日免费次数: 0/3          │
│                             │
│  订阅会员享受:               │
│  ✓ 无限查看资料卡            │
│  ✓ 查看完整match历史         │
│  ✓ 高级筛选功能              │
│                             │
│  [立即订阅] [稍后再说]        │
└─────────────────────────────┘
```

---

### 模块 6: 后端 API & Cloud Functions

**文件**: `backend/functions/src/profileCard.ts`（新建）

```typescript
// 获取资料卡（带权限检查）
export const getProfileCard = functions.https.onCall(async (data, context) => {
  const { targetUserId } = data;
  const currentUserId = context.auth?.uid;
  
  // 1. 检查权限
  // 2. 检查订阅状态
  // 3. 检查今日配额
  // 4. 记录查看行为
  // 5. 返回资料卡数据
});

// 更新资料卡
export const updateProfileCard = functions.https.onCall(async (data, context) => {
  // 仅允许用户更新自己的资料卡
});

// 获取今日查看次数
export const getTodayViewCount = functions.https.onCall(async (data, context) => {
  // 返回今日已使用的查看次数
});
```

**Firestore 安全规则** (firestore.rules):

```
// 资料卡集合
match /profileCards/{userId} {
  allow read: if request.auth != null && (
    // 本人可读
    request.auth.uid == userId ||
    // 公开设置且满足隐私条件
    (resource.data.privacy.allowStrangerAccess == true)
  );
  allow write: if request.auth != null && request.auth.uid == userId;
}

// 查看记录
match /profileCardViews/{userId}/daily/{date} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// 用户隐私设置
match /users/{userId}/private/privacy_settings {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

---

## 🚀 实施步骤

### 第一阶段：数据模型与基础服务 (Day 1-2)
1. ✅ 创建 `ProfileCard` 模型
2. ✅ 创建 `UserPrivacySettings` 模型
3. ✅ 实现 `ProfileCardService`
4. ✅ 更新 Firestore 安全规则
5. ✅ 编写后端 Cloud Functions

### 第二阶段：UI 页面实现 (Day 3-5)
1. ✅ 修改 `chat_page_new.dart` 添加头像和ID显示
2. ✅ 创建 `profile_card_page.dart`
3. ✅ 创建 `privacy_settings_page.dart`
4. ✅ 创建 `public_profile_page.dart`
5. ✅ 修改 `edit_profile_page.dart` 添加新入口
6. ✅ 创建订阅弹窗组件

### 第三阶段：订阅系统集成 (Day 6-7)
1. ✅ 实现每日配额追踪
2. ✅ 实现订阅状态检查
3. ✅ 集成支付系统（可选）
4. ✅ 测试权限控制逻辑

### 第四阶段：测试与优化 (Day 8-9)
1. ✅ 单元测试
2. ✅ 集成测试
3. ✅ UI/UX 优化
4. ✅ 性能优化（缓存、懒加载）

### 第五阶段：上线准备 (Day 10)
1. ✅ 文档编写
2. ✅ 数据库迁移脚本
3. ✅ 用户引导页面
4. ✅ 发布更新

---

## 🎨 UI 设计风格指南

基于现有代码的UI风格：
- **字体**: Google Fonts Cormorant Garamond (标题)
- **圆角**: 12-18px
- **阴影**: 轻微阴影，`blurRadius: 10, offset: Offset(0, 4)`
- **配色**: 
  - Primary: theme.primaryColor
  - 背景: 白色/浅灰
  - 文字: 深灰 (#3E2A2A)
  - 强调: 渐变或 primary color
- **动画**: 使用 `Curves.easeOutCubic`，250ms duration
- **间距**: 8/16/24/32 的倍数

---

## 📊 数据库结构总览

```
firestore/
├── users/{uid}
│   ├── (公开信息)
│   └── private/
│       └── privacy_settings
├── profileCards/{uid}
│   ├── uid
│   ├── username
│   ├── avatarUrl
│   ├── bio
│   ├── highlightedTraits[]
│   ├── featuredPostIds[]
│   ├── publicMatchIds[]
│   ├── privacy{}
│   └── stats{}
├── profileCardViews/{uid}
│   ├── daily/{date}
│   │   ├── count
│   │   └── viewedUserIds[]
│   └── history/{viewId}
│       ├── viewerUserId
│       ├── targetUserId
│       └── timestamp
└── conversations/{conversationId}
    └── (已有结构)
```

---

## 🔒 安全性考虑

1. **隐私优先**: 默认隐私设置为最严格
2. **配额控制**: 使用 Firestore 事务防止刷量
3. **防爬虫**: 添加 rate limiting
4. **敏感信息**: 不在客户端缓存隐私数据
5. **审计日志**: 记录所有查看行为
6. **举报机制**: 资料卡页面提供举报按钮

---

## 📈 性能优化

1. **懒加载**: 资料卡图片和帖子缩略图懒加载
2. **缓存策略**: 
   - 本地缓存已查看的资料卡（1小时）
   - 配额信息缓存（5分钟）
3. **分页加载**: 公开主页的帖子列表分页
4. **压缩图片**: 头像和缩略图使用压缩版本
5. **索引优化**: 为常用查询添加 Firestore 索引

---

## 🧪 测试清单

- [ ] 聊天页顶部点击头像打开资料卡
- [ ] 免费用户每日3次查看限制
- [ ] 订阅用户无限查看
- [ ] 隐私设置正确应用
- [ ] 被屏蔽用户无法查看
- [ ] 资料卡更新实时同步
- [ ] 配额重置（每日凌晨）
- [ ] 订阅弹窗正确显示
- [ ] 公开主页正确显示内容
- [ ] 多设备同步测试

---

## 📝 后续扩展功能

1. **资料卡模板**: 提供多种模板供用户选择
2. **资料卡点赞**: 允许用户为喜欢的资料卡点赞
3. **访客记录**: 查看谁看过我的资料卡（会员功能）
4. **资料卡分享**: 生成分享链接或图片
5. **资料卡动态**: 支持添加动态背景或视频
6. **认证标识**: 为认证用户添加特殊标识

---

## 🎉 完成标准

1. ✅ 所有UI页面按设计实现
2. ✅ 数据模型完整且符合规范
3. ✅ 权限控制逻辑正确无误
4. ✅ 订阅系统正常工作
5. ✅ 用户体验流畅，无卡顿
6. ✅ 所有测试用例通过
7. ✅ 代码注释清晰，文档完整

---

**预计总工期**: 10个工作日  
**风险点**: 订阅系统集成、权限控制复杂度  
**依赖**: Firebase、现有用户系统、聊天系统
