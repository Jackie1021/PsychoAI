# 🎨 Profile Card 极致美化与功能完善计划

## 📋 需求分析

### 核心目标
打造一个**极致美观**且**高度可定制**的个人资料卡片系统，类似实体名片的数字化呈现。

### 功能需求

#### 1. UI 设计要求 ✨
- **极致美观**: 遵循现有 UI 风格（Cormorant Garamond 字体 + 优雅配色）
- **高度可定制**: 
  - 多种卡片皮肤/主题
  - 自定义背景（渐变/图片/纯色）
  - 灵活布局（上下/左右/卡片式）
  - 自定义背景图片上传
  
#### 2. 功能需求 🎯
- **编辑功能**: 完整的编辑器（拖拽排序、实时预览）
- **预览功能**: 所见即所得的预览
- **访问控制**: 
  - 与订阅系统关联
  - 用户可自定义查看权限
  - 部分内容锁定（类似小红书收藏锁）
- **多入口访问**: Post 界面 + Match 界面点击头像

#### 3. 可展示内容 📝
- ✅ 个人头像
- ✅ 用户名 + 会员徽章
- ✅ 个人简介
- ✅ 高亮特征标签
- ✅ 精选帖子（瀑布流展示）
- ✅ Match 记录（精选展示）
- ✅ 统计数据（粉丝/关注/帖子数）
- ✅ 社交链接
- ✅ 自定义装饰元素

---

## 🏗️ 技术架构

### 1. 数据模型扩展

```dart
class ProfileCardTheme {
  final String id;
  final String name;
  final ThemeStyle style; // minimalist, elegant, vibrant, etc.
  final CardLayout layout; // vertical, horizontal, card
  final BackgroundType backgroundType; // gradient, image, solid
  final List<Color>? gradientColors;
  final String? backgroundImageUrl;
  final Color? solidColor;
  final bool isPremium; // 高级主题需要会员
}

class ProfileCardLayout {
  final List<CardSection> sections;
  final Map<String, bool> sectionVisibility;
  final Map<String, int> sectionOrder;
}

enum CardSection {
  header,        // 头像 + 基本信息
  bio,           // 个人简介
  traits,        // 特征标签
  stats,         // 统计数据
  featuredPosts, // 精选帖子
  matches,       // Match 记录
  social,        // 社交链接
}

class ProfileCardCustomization {
  final ProfileCardTheme theme;
  final ProfileCardLayout layout;
  final Map<CardSection, SectionStyle> sectionStyles;
}
```

### 2. 权限控制模型

```dart
class ProfileCardAccessControl {
  final bool requireSubscription;  // 查看需要订阅
  final AccessLevel defaultAccess;  // 默认访问级别
  final Map<CardSection, AccessLevel> sectionAccess; // 各部分访问控制
  final List<String> whitelistUserIds; // 白名单
  final List<String> blacklistUserIds; // 黑名单
}

enum AccessLevel {
  public,        // 公开
  friendsOnly,   // 仅好友
  subscribersOnly, // 仅订阅者
  private,       // 私密
}
```

---

## 🎨 UI 设计方案

### 主题库 (6种预设)

#### 1. **Minimalist** (极简)
- 纯白背景
- 简洁线条分隔
- 大留白设计
- 黑白配色

#### 2. **Elegant** (优雅) - 默认
- 渐变背景 (淡紫→淡粉)
- Cormorant Garamond 字体
- 金色装饰线
- 优雅阴影效果

#### 3. **Vibrant** (活力)
- 鲜艳渐变
- 圆角卡片
- 动态阴影
- 彩色标签

#### 4. **Professional** (专业) 🔐 Premium
- 深色背景
- 商务风格
- 金属质感
- 高端装饰

#### 5. **Artistic** (艺术) 🔐 Premium
- 自定义背景图
- 毛玻璃效果
- 创意布局
- 艺术字体

#### 6. **Custom** (完全自定义) 🔐 Pro
- 所有参数可调
- 自由布局
- 高级动画
- 独家装饰元素

### 布局模式

```
┌─────────────────────────────────┐
│  Vertical Layout (竖版)          │
├─────────────────────────────────┤
│  ┌───────────────────────────┐  │
│  │       [Avatar]            │  │
│  │     Username + Badge      │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │      Bio & Traits         │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │        Stats              │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │    Featured Posts         │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  Horizontal Layout (横版)        │
├─────────────────────────────────┤
│ [Avatar]  │  Bio & Info         │
│           │  ─────────────────  │
│           │  Stats & Traits     │
│           │  ─────────────────  │
│           │  Featured Content   │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  Card Layout (卡片式)            │
├─────────────────────────────────┤
│  ┌──────┐ ┌──────┐ ┌──────┐    │
│  │Header│ │Stats │ │Posts │    │
│  └──────┘ └──────┘ └──────┘    │
│  ┌─────────────────────────┐   │
│  │      Bio & Traits       │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

---

## 🛠️ 实施步骤

### Phase 1: 数据模型与服务层 (Day 1)
- [ ] 扩展 ProfileCard 模型
- [ ] 添加主题和布局模型
- [ ] 扩展 ProfileCardService
- [ ] 添加背景图片上传服务

### Phase 2: 编辑器 UI (Day 2-3)
- [ ] 创建 ProfileCardEditorPage
- [ ] 主题选择器
- [ ] 布局编辑器
- [ ] 背景自定义工具
- [ ] 内容编辑面板
- [ ] 实时预览

### Phase 3: 展示页面优化 (Day 3-4)
- [ ] 重构 ProfileCardPage
- [ ] 实现多主题渲染
- [ ] 添加动画效果
- [ ] 权限控制 UI
- [ ] 订阅提示集成

### Phase 4: 多入口集成 (Day 4)
- [ ] Post 页面集成
- [ ] Match 页面集成
- [ ] 权限检查逻辑
- [ ] 加载状态优化

### Phase 5: 高级功能 (Day 5)
- [ ] 拖拽排序
- [ ] 锁定/解锁动画
- [ ] 分享功能
- [ ] 统计分析

---

## 📐 详细设计

### 编辑器界面结构

```
┌───────────────────────────────────────────────┐
│  Profile Card Editor          [Preview] [Save] │
├───────────────────────────────────────────────┤
│                                                │
│  ┌─────────┐  ┌──────────────────────────┐   │
│  │ Sidebar │  │    Live Preview          │   │
│  │         │  │                          │   │
│  │ Themes  │  │    [Card Display]        │   │
│  │ Layout  │  │                          │   │
│  │ Content │  │                          │   │
│  │ Privacy │  │                          │   │
│  │         │  │                          │   │
│  └─────────┘  └──────────────────────────┘   │
│                                                │
└───────────────────────────────────────────────┘
```

### 主题选择器

```dart
class ThemeSelector extends StatelessWidget {
  final List<ProfileCardTheme> themes;
  final ProfileCardTheme selectedTheme;
  final Function(ProfileCardTheme) onThemeSelected;
  
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        return ThemePreviewCard(
          theme: theme,
          isSelected: theme.id == selectedTheme.id,
          isPremium: theme.isPremium,
          onTap: () => onThemeSelected(theme),
        );
      },
    );
  }
}
```

### 内容编辑面板

```dart
class ContentEditPanel extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section Toggle
        SectionToggle(
          sections: CardSection.values,
          visibility: sectionVisibility,
          onToggle: (section, visible) {},
        ),
        
        // Section Editor
        if (selectedSection == CardSection.featuredPosts)
          FeaturedPostsEditor(
            posts: userPosts,
            selected: featuredPostIds,
            onSelectionChanged: (ids) {},
          ),
          
        if (selectedSection == CardSection.matches)
          MatchRecordsEditor(
            matches: userMatches,
            selected: publicMatchIds,
            onSelectionChanged: (ids) {},
          ),
      ],
    );
  }
}
```

---

## 🔐 权限控制实现

### 查看权限矩阵

| 用户类型 | 公开内容 | 部分锁定内容 | 完全私密内容 |
|---------|---------|-------------|-------------|
| 游客    | ✅ 可见  | 🔒 需订阅    | ❌ 不可见    |
| Free 用户 | ✅ 可见 | 🔒 3次/天   | ❌ 不可见    |
| Premium | ✅ 可见 | ✅ 无限制    | ⚠️ 看设置    |
| 好友    | ✅ 可见 | ✅ 无限制    | ✅ 可见      |
| 被拉黑  | ❌ 不可见 | ❌ 不可见   | ❌ 不可见    |

### 锁定UI设计

```dart
class LockedSection extends StatelessWidget {
  final CardSection section;
  final bool isLocked;
  
  Widget build(BuildContext context) {
    if (!isLocked) {
      return _buildContent();
    }
    
    return Stack(
      children: [
        // Blurred content
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: _buildContent(),
          ),
        ),
        
        // Lock overlay
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 48, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Subscribe to unlock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _showSubscriptionDialog(),
                child: Text('Upgrade Now'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

## 🎯 关键功能实现

### 1. 拖拽排序

```dart
class SectionReorderList extends StatefulWidget {
  final List<CardSection> sections;
  final Function(List<CardSection>) onReorder;
  
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = sections.removeAt(oldIndex);
          sections.insert(newIndex, item);
        });
        widget.onReorder(sections);
      },
      children: sections.map((section) {
        return ListTile(
          key: ValueKey(section),
          leading: Icon(_getIconForSection(section)),
          title: Text(_getTitleForSection(section)),
          trailing: Icon(Icons.drag_handle),
        );
      }).toList(),
    );
  }
}
```

### 2. 背景图片上传

```dart
class BackgroundImageUploader extends StatelessWidget {
  final String? currentImageUrl;
  final Function(String) onImageUploaded;
  
  Future<void> _pickAndUploadImage() async {
    // Pick image
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image == null) return;
    
    // Upload to Firebase Storage
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_card_backgrounds')
        .child('${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
    await ref.putFile(File(image.path));
    final url = await ref.getDownloadURL();
    
    onImageUploaded(url);
  }
}
```

### 3. 实时预览

```dart
class LivePreviewPane extends StatelessWidget {
  final ProfileCard profileCard;
  final ProfileCardCustomization customization;
  
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Preview content
            SingleChildScrollView(
              child: ProfileCardRenderer(
                profileCard: profileCard,
                customization: customization,
                isPreview: true,
              ),
            ),
            
            // Device frame overlay
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildDeviceSwitch(),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📱 多入口访问实现

### Post 页面集成

```dart
// In PostCard widget
GestureDetector(
  onTap: () async {
    // Check permission
    final permission = await profileCardService
        .checkViewPermission(post.authorId);
    
    if (!permission.canView) {
      if (permission.requiresSubscription) {
        showSubscriptionPrompt(context);
      } else {
        showPermissionDeniedDialog(context);
      }
      return;
    }
    
    // Navigate to profile card
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileCardPage(
          userId: post.authorId,
          source: 'post', // Track source
        ),
      ),
    );
  },
  child: CircleAvatar(
    backgroundImage: NetworkImage(post.authorAvatarUrl),
  ),
)
```

### Match 页面集成

```dart
// In MatchCard widget
InkWell(
  onTap: () => _viewProfileCard(match.userB.uid),
  child: Column(
    children: [
      CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(match.userB.avatarUrl),
      ),
      SizedBox(height: 8),
      Text(match.userB.username),
      if (hasViewedCard)
        Icon(Icons.check_circle, size: 16, color: Colors.green),
    ],
  ),
)
```

---

## 🚀 性能优化

### 1. 图片优化
- 背景图压缩到合理大小
- 使用缓存策略
- 渐进式加载

### 2. 渲染优化
- 使用 RepaintBoundary 隔离重绘
- 懒加载精选内容
- 虚拟滚动优化

### 3. 数据优化
- 本地缓存常用主题
- 预加载关键内容
- 分页加载历史记录

---

## ✅ 验收标准

### 功能完整性
- [ ] 6种主题全部实现
- [ ] 编辑器所有功能可用
- [ ] 预览与实际一致
- [ ] 权限控制正确
- [ ] 多入口访问正常

### UI 美观度
- [ ] 视觉效果精致
- [ ] 动画流畅自然
- [ ] 响应式适配
- [ ] 无明显性能问题

### 用户体验
- [ ] 编辑流程直观
- [ ] 加载速度快
- [ ] 错误提示友好
- [ ] 操作反馈及时

---

## 📊 成功指标

- **编辑完成率**: > 80% 用户完成卡片自定义
- **分享率**: > 30% 用户分享自己的卡片
- **订阅转化**: 解锁内容带来 15%+ 订阅转化
- **访问深度**: 平均浏览 3+ 个资料卡片

---

## 🎁 额外亮点

1. **动态效果**: 视差滚动、悬浮动画
2. **互动元素**: 点赞、评论、分享
3. **社交传播**: 生成精美分享图
4. **数据洞察**: 访问统计、热力图
5. **AI 推荐**: 智能推荐主题和布局

---

准备开始实施！🚀
