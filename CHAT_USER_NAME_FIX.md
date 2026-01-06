# 🔧 Chat 用户名显示问题修复

## 问题描述

在 Yearly Report 页面和 Match Analysis 页面点击 "Start Chat" 后，聊天界面显示的用户名不正确：
- **预期**: 显示用户真实名称（如 "Bob"）
- **实际**: 显示为 "User@xxxx"（用户ID）

## 根本原因

有三个数据不一致的问题：

### 1. Firebase 字段名不一致
- **问题**: `createConversation` 从 Firebase 读取 `name` 和 `avatar` 字段
- **现实**: Firebase users 集合存储的是 `username` 和 `avatarUrl` 字段
- **结果**: 读不到数据，使用默认值 "User"

### 2. conversationId 生成不正确
- **问题**: `_startChat` 手动生成 conversationId: `${currentUserId}_${otherUserId}`
- **现实**: 应该使用 provider 返回的实际 conversation ID
- **结果**: 可能找不到对应的 conversation，或者创建重复的 conversation

### 3. Seed 脚本缺少字段
- **问题**: `seed_emulator.ts` 只创建 `username` 和 `avatarUrl` 字段
- **现实**: Chat 系统需要 `name` 和 `avatar` 字段
- **结果**: 测试用户的聊天记录显示不正确

## 修复方案

### 修复 1: firebase_chat_service.dart - 字段名兼容

**文件**: `lib/services/firebase_chat_service.dart`

**修改内容**:
```dart
// Before (只读取 name 和 avatar)
name: currentUserData['name'] ?? 'User',
avatar: currentUserData['avatar'],

// After (兼容两种字段名)
name: currentUserData['username'] ?? currentUserData['name'] ?? 'User',
avatar: currentUserData['avatarUrl'] ?? currentUserData['avatar'],
```

**作用**: 
- 优先读取 `username` 和 `avatarUrl`
- 如果不存在，fallback 到 `name` 和 `avatar`
- 最后才使用默认值 "User"

---

### 修复 2: firebase_api_service.dart - 双字段存储

**文件**: `lib/services/firebase_api_service.dart`

**修改内容**:
```dart
// 更新用户时同时写入两套字段
await _firestore.collection('users').doc(user.uid).set({
  'username': user.username,
  'name': user.username,              // 新增：chat 兼容
  'avatarUrl': user.avatarUrl,
  'avatar': user.avatarUrl,           // 新增：chat 兼容
  'bio': user.freeText,
  'freeText': user.freeText,
  'traits': user.traits,
  'lastActive': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
```

**作用**: 
- 保持向后兼容
- 新数据同时包含两套字段名
- 确保 chat 系统能正确读取

---

### 修复 3: yearly_report_page.dart - 使用正确的 conversationId

**文件**: `lib/pages/yearly_report_page.dart`

**修改前**:
```dart
void _startChat(MatchRecord record) async {
  final conversationId = '${currentUserId}_${record.matchedUserId}';
  
  await chatProvider.getOrCreateConversation(
    otherUserId: record.matchedUserId,
    matchId: record.id,
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => chat.ChatPage(
        conversationId: conversationId,  // ❌ 手动生成的ID
        otherUserId: record.matchedUserId,
        matchId: record.id,
      ),
    ),
  );
}
```

**修改后**:
```dart
void _startChat(MatchRecord record) async {
  try {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // ✅ 获取实际的 conversation ID
    final conversationId = await chatProvider.getOrCreateConversation(
      otherUserId: record.matchedUserId,
      matchId: record.id,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => chat.ChatPage(
            conversationId: conversationId,  // ✅ 使用正确的ID
            otherUserId: record.matchedUserId,
            matchId: record.id,
          ),
        ),
      );
    }
  } catch (e) {
    print('❌ Error starting chat: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e')),
      );
    }
  }
}
```

**作用**:
- 等待 `getOrCreateConversation` 返回
- 使用 provider 返回的实际 conversation ID
- 添加错误处理

---

### 修复 4: match_analysis_page.dart - 传递完整参数

**文件**: `lib/pages/match_analysis_page.dart`

**修改前**:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => ChatPage(conversationId: conversationId),
  ),
);
```

**修改后**:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => ChatPage(
      conversationId: conversationId,
      otherUserId: analysis.userB.uid,  // ✅ 添加
      matchId: analysis.id,              // ✅ 添加
    ),
  ),
);
```

**作用**:
- 传递完整的参数给 ChatPage
- 确保聊天界面能获取正确的用户信息

---

### 修复 5: seed_emulator.ts - 添加兼容字段

**文件**: `scripts/seed_emulator.ts`

**修改内容**:
```typescript
const userProfile = {
  uid: authUser.uid,
  username: userData.username,
  name: userData.username,              // 新增：chat 兼容
  email: userData.email,
  avatarUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(userData.username)}`,
  avatar: `https://ui-avatars.com/api/?name=${encodeURIComponent(userData.username)}`,  // 新增：chat 兼容
  bio: userData.bio,
  traits: userData.traits,
  freeText: userData.freeText,
  // ... 其他字段
};
```

**作用**:
- 测试用户同时包含两套字段名
- 确保 chat 功能在测试环境下正常工作

---

## 验证步骤

### 1. 重新创建测试用户

```bash
# 清理并重新生成测试数据
./SEED_DATA.sh
```

### 2. 测试 Yearly Report Page

```bash
# 启动应用
flutter run -d chrome

# 操作步骤：
1. 登录测试账号（如 alice@test.com / test123456）
2. 创建一些 matches（从 Feature Selection 页面）
3. 导航到 Yearly Report 页面
4. 点击 Matches 标签
5. 展开一个 match 记录
6. 点击 "Start Chat" 按钮
7. 验证：
   ✓ 聊天界面顶部显示正确的用户名（如 "Bob"）
   ✓ 不显示 "User@xxxx"
   ✓ 显示用户头像
```

### 3. 测试 Match Analysis Page

```bash
# 操作步骤：
1. 从 Feature Selection 页面开始匹配
2. 在 Match Result 页面查看结果
3. 点击某个匹配卡片
4. 进入 Match Analysis 页面
5. 点击 "Start Chat" 按钮
6. 验证：
   ✓ 聊天界面显示正确用户名
   ✓ 可以正常发送消息
```

### 4. 验证数据结构

```bash
# 检查 Firestore 中的用户数据
# 在 Firebase Emulator UI (http://localhost:4001) 中：
1. 打开 Firestore 标签
2. 查看 users 集合
3. 选择任意一个用户文档
4. 验证字段：
   ✓ username: "Alice"
   ✓ name: "Alice"
   ✓ avatarUrl: "https://ui-avatars.com/..."
   ✓ avatar: "https://ui-avatars.com/..."
```

---

## 数据迁移（可选）

如果已有用户数据，需要迁移：

### 方案 A: 清空重建（推荐用于开发环境）

```bash
# 停止 emulator
# 删除 emulator 数据
rm -rf ~/.config/firebase/emulators/

# 重启并重新 seed
./START_BACKEND.sh
./SEED_DATA.sh
```

### 方案 B: 数据迁移脚本（生产环境）

创建迁移脚本 `scripts/migrate_user_fields.ts`:

```typescript
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

async function migrateUsers() {
  const users = await db.collection('users').get();
  
  for (const doc of users.docs) {
    const data = doc.data();
    
    await doc.ref.update({
      name: data.username || data.name || 'User',
      avatar: data.avatarUrl || data.avatar,
    });
    
    console.log(`✓ Migrated user: ${data.username}`);
  }
  
  console.log('✅ Migration complete');
}

migrateUsers();
```

---

## 检查清单

- [x] 修复 `firebase_chat_service.dart` 字段读取
- [x] 修复 `firebase_api_service.dart` 字段写入
- [x] 修复 `yearly_report_page.dart` conversationId 生成
- [x] 修复 `match_analysis_page.dart` 参数传递
- [x] 修复 `seed_emulator.ts` 测试数据生成
- [ ] 重新运行 `./SEED_DATA.sh` 生成测试数据
- [ ] 测试 Yearly Report 的 Start Chat
- [ ] 测试 Match Analysis 的 Start Chat
- [ ] 验证聊天界面显示正确用户名

---

## 总结

所有修复都已完成，主要改进：

1. **向后兼容**: 支持 `username`/`name` 和 `avatarUrl`/`avatar` 两种字段名
2. **正确 ID**: 使用 provider 返回的实际 conversation ID
3. **完整参数**: ChatPage 接收所有必要的参数
4. **测试数据**: Seed 脚本生成包含所有字段的测试用户

现在请重新运行 `./SEED_DATA.sh` 来生成新的测试数据，然后测试 Start Chat 功能！

---

*Last Updated: November 17, 2025*  
*Status: ✅ All Fixes Applied - Ready for Testing*
