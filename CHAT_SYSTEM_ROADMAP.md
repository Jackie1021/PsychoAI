# 🚀 聊天系统完整实现路线图

## 📋 目录
1. [系统概述](#系统概述)
2. [数据模型设计](#数据模型设计)
3. [核心功能清单](#核心功能清单)
4. [技术架构](#技术架构)
5. [实施阶段](#实施阶段)
6. [安全与性能](#安全与性能)

---

## 系统概述

### 当前状态分析
- ✅ 已有基础聊天UI（ChatPage、ChatHistoryPage）
- ✅ 已有本地消息模型（Conversation、ChatMessage）
- ✅ 已有基础后端服务框架（chat_service.ts）
- ❌ **缺失**：真实Firebase持久化、消息同步、实时通信
- ❌ **缺失**：用户关系管理（关注/粉丝）
- ❌ **缺失**：对话框管理功能
- ❌ **缺失**：多媒体消息支持

### 设计理念
参考**小红书的临时对话框**模式：
- Match成功后自动创建对话
- 支持对话收藏/置顶
- 点击头像查看个人主页/帖子
- 轻量级互动（点赞、关注）
- 对话可删除但保留历史记录

---

## 数据模型设计

### 1. Conversations 集合
```
conversations/{conversationId}
├── id: string                      // 对话ID
├── participantIds: string[]        // [userId1, userId2]
├── participantInfo: {              // 参与者信息快照
│   userId1: {
│     name: string
│     avatar: string
│     bio: string
│   }
│   userId2: { ... }
├── }
├── type: string                    // "match" | "direct" | "group"
├── status: string                  // "active" | "archived" | "deleted"
├── createdAt: timestamp
├── updatedAt: timestamp
├── lastMessage: {                  // 最后一条消息快照
│   text: string
│   senderId: string
│   timestamp: timestamp
│   type: string                    // "text" | "image" | "audio"
├── }
├── unreadCount: {                  // 未读计数
│   userId1: number
│   userId2: number
├── }
├── metadata: {
│   matchId?: string                // 如果来自匹配
│   isFavorited: {                  // 收藏状态（各用户独立）
│     userId1: boolean
│     userId2: boolean
│   }
│   isPinned: {                     // 置顶状态
│     userId1: boolean
│     userId2: boolean
│   }
│   tags?: string[]                 // 自定义标签
├── }

messages (subcollection)
├── messages/{messageId}
│   ├── id: string
│   ├── senderId: string
│   ├── text?: string
│   ├── type: string                // "text" | "image" | "video" | "audio" | "system"
│   ├── mediaUrl?: string
│   ├── mediaMetadata?: {
│   │   width: number
│   │   height: number
│   │   duration?: number
│   │   thumbnailUrl?: string
│   ├── }
│   ├── replyTo?: {                 // 回复消息
│   │   messageId: string
│   │   text: string
│   │   senderId: string
│   ├── }
│   ├── status: string              // "sending" | "sent" | "delivered" | "read"
│   ├── reactions?: {               // 消息反应
│   │   userId: string              // emoji/like
│   ├── }
│   ├── isDeleted: boolean
│   ├── createdAt: timestamp
│   ├── updatedAt: timestamp
```

### 2. Users 集合扩展
```
users/{userId}
├── ... (existing fields)
├── chatSettings: {
│   allowMessagesFrom: string       // "everyone" | "following" | "matched"
│   showOnlineStatus: boolean
│   muteNotifications: boolean
├── }
├── lastSeen: timestamp
├── onlineStatus: string            // "online" | "away" | "offline"

following (subcollection)
├── following/{targetUserId}
│   ├── followedAt: timestamp
│   ├── isNotificationEnabled: boolean

followers (subcollection)
├── followers/{followerUserId}
│   ├── followedAt: timestamp

mutedConversations (subcollection)
├── mutedConversations/{conversationId}
│   ├── mutedAt: timestamp
│   ├── mutedUntil?: timestamp      // null = 永久静音
```

### 3. 消息通知队列
```
messageNotifications/{notificationId}
├── userId: string                  // 接收者
├── conversationId: string
├── senderId: string
├── messageText: string
├── timestamp: timestamp
├── isRead: boolean
├── type: string                    // "new_message" | "new_match"
```

---

## 核心功能清单

### Phase 1: 基础消息系统 ✨
#### 1.1 实时消息收发
- [x] Firebase Firestore实时监听
- [ ] 消息发送（文本）
- [ ] 消息接收
- [ ] 消息状态更新（已发送/已读）
- [ ] 消息排序与分页加载
- [ ] 断线重连处理
- [ ] 发送失败重试机制

#### 1.2 对话管理
- [ ] Match成功后自动创建对话
- [ ] 对话列表实时更新
- [ ] 未读消息计数
- [ ] 对话置顶功能
- [ ] 对话收藏/取消收藏
- [ ] 对话删除（软删除）
- [ ] 对话搜索功能
- [ ] 对话标签分类

#### 1.3 UI优化
- [ ] 消息气泡动画优化
- [ ] 输入框智能高度调整
- [ ] 滚动位置智能保持
- [ ] 加载更多历史消息
- [ ] 新消息到达提示
- [ ] 消息时间戳显示
- [ ] 输入状态指示器（"对方正在输入..."）

### Phase 2: 增强交互功能 🎯
#### 2.1 多媒体消息
- [ ] 图片发送与预览
- [ ] 图片压缩与上传（Firebase Storage）
- [ ] 视频发送（短视频）
- [ ] 语音消息录制与播放
- [ ] 文件传输（限制大小）
- [ ] 媒体消息缓存策略

#### 2.2 消息互动
- [ ] 长按消息菜单（复制/删除/回复）
- [ ] 消息引用回复
- [ ] 消息表情回应（❤️👍😂等）
- [ ] 消息撤回（2分钟内）
- [ ] 消息转发
- [ ] 消息多选模式

#### 2.3 用户关系整合
- [ ] 点击头像进入个人主页
- [ ] 个人主页显示用户帖子
- [ ] 关注/取消关注按钮
- [ ] 关注列表页面
- [ ] 粉丝列表页面
- [ ] 互相关注状态标识
- [ ] 屏蔽用户（不再匹配）

### Phase 3: 高级功能 🚀
#### 3.1 对话体验优化
- [ ] 对话背景自定义
- [ ] 消息字体大小调整
- [ ] 夜间模式适配
- [ ] 消息通知推送（FCM）
- [ ] 通知静音设置
- [ ] 免打扰模式
- [ ] 消息草稿保存

#### 3.2 智能功能
- [ ] 消息敏感词过滤
- [ ] 垃圾消息检测
- [ ] AI自动回复建议
- [ ] 消息搜索（全文检索）
- [ ] 聊天数据统计
- [ ] 聊天记录导出

#### 3.3 系统通知
- [ ] 系统消息类型（匹配成功、关注提醒）
- [ ] 消息中心页面
- [ ] 通知设置页面
- [ ] 消息免打扰时段
- [ ] 批量标记已读

### Phase 4: 性能与安全 🔒
#### 4.1 性能优化
- [ ] 消息分页加载策略
- [ ] 图片懒加载
- [ ] 消息缓存机制
- [ ] 离线消息队列
- [ ] 数据库索引优化
- [ ] CDN加速媒体访问

#### 4.2 安全控制
- [ ] 陌生人消息限制
- [ ] 消息举报功能
- [ ] 恶意用户自动封禁
- [ ] 消息加密（端到端）
- [ ] 敏感信息脱敏
- [ ] 审计日志记录

---

## 技术架构

### 前端架构 (Flutter)
```
lib/
├── models/
│   ├── conversation.dart          ✅ 已有（需扩展）
│   ├── message.dart               🆕 完整消息模型
│   ├── chat_participant.dart      🆕 参与者信息
│   └── notification.dart          🆕 通知模型
├── services/
│   ├── chat_service.dart          🆕 聊天核心服务
│   ├── message_service.dart       🆕 消息CRUD
│   ├── conversation_service.dart  🆕 对话管理
│   ├── media_service.dart         🆕 媒体上传/下载
│   ├── notification_service.dart  🆕 通知管理
│   └── realtime_service.dart      🆕 实时同步
├── pages/
│   ├── chat_page.dart             ✅ 已有（需重构）
│   ├── chat_history_page.dart     ✅ 已有（需增强）
│   ├── chat_detail_page.dart      🆕 对话详情设置
│   ├── message_search_page.dart   🆕 消息搜索
│   └── notifications_page.dart    🆕 通知中心
├── widgets/
│   ├── message_bubble.dart        🆕 消息气泡组件
│   ├── message_input_bar.dart     🆕 输入框组件
│   ├── conversation_tile.dart     🆕 对话列表项
│   ├── media_picker.dart          🆕 媒体选择器
│   ├── audio_recorder.dart        🆕 语音录制器
│   └── typing_indicator.dart      🆕 输入指示器
└── providers/
    ├── conversation_provider.dart ✅ 已有（需扩展）
    ├── message_provider.dart      🆕 消息状态管理
    └── chat_state_provider.dart   🆕 聊天全局状态
```

### 后端架构 (Firebase Functions)
```
backend/functions/src/
├── chat_service.ts                ✅ 已有（需扩展）
├── message_handler.ts             🆕 消息处理函数
├── conversation_handler.ts        🆕 对话管理函数
├── notification_handler.ts        🆕 通知推送
├── media_handler.ts               🆕 媒体处理
├── moderation_handler.ts          🆕 内容审核
└── triggers/
    ├── onMessageCreate.ts         🆕 新消息触发器
    ├── onConversationUpdate.ts    🆕 对话更新触发器
    └── onUserStatusChange.ts      🆕 用户状态变化
```

### Firebase配置
```yaml
Firestore:
  - conversations (collection)
  - messages (subcollection)
  - messageNotifications (collection)
  
Storage:
  - chat_media/{conversationId}/{messageId}/{filename}
  
Cloud Functions:
  - sendMessage (callable)
  - createConversation (callable)
  - getConversations (callable)
  - getMessages (callable)
  - markAsRead (callable)
  - deleteMessage (callable)
  - uploadChatMedia (callable)
  - sendNotification (trigger)
  
Security Rules:
  - 参与者才能读写对话
  - 消息只能由发送者删除
  - 媒体文件访问控制
```

---

## 实施阶段

### 🔷 Stage 1: 基础架构搭建（1-2天）
**目标**：建立完整的数据流和基础通信

#### 任务清单
1. **数据模型重构**
   - [ ] 创建完整的Message模型（支持多种类型）
   - [ ] 扩展Conversation模型（添加metadata、status等）
   - [ ] 创建ChatParticipant模型
   - [ ] 定义枚举类型（MessageType、MessageStatus等）

2. **服务层搭建**
   - [ ] ChatService：核心聊天服务抽象
   - [ ] FirebaseChatService：Firebase实现
   - [ ] ConversationRepository：对话CRUD
   - [ ] MessageRepository：消息CRUD

3. **后端Cloud Functions**
   - [ ] 完善sendMessage函数（支持多种消息类型）
   - [ ] 实现createConversation函数
   - [ ] 实现getMessages分页查询
   - [ ] 实现markMessagesAsRead函数
   - [ ] 添加onMessageCreate触发器（更新对话lastMessage）

4. **Firestore Rules更新**
   - [ ] 细化conversations访问规则
   - [ ] 添加messages子集合规则
   - [ ] 防止消息篡改规则

#### 验收标准
- ✅ 用户可以发送文本消息并实时接收
- ✅ 消息持久化到Firestore
- ✅ 对话列表实时更新
- ✅ 未读消息计数正确

---

### 🔷 Stage 2: UI增强与交互优化（2-3天）
**目标**：完善用户体验，达到可用状态

#### 任务清单
1. **ChatPage重构**
   - [ ] 使用StreamBuilder监听消息
   - [ ] 实现下拉加载历史消息
   - [ ] 优化消息列表性能（缓存、复用）
   - [ ] 添加消息状态指示（发送中/已读）
   - [ ] 实现消息长按菜单

2. **ChatHistoryPage增强**
   - [ ] 实时监听对话列表变化
   - [ ] 显示未读消息红点
   - [ ] 支持对话搜索
   - [ ] 支持对话滑动操作（置顶/删除）
   - [ ] 添加空状态提示

3. **用户关系整合**
   - [ ] 在ChatPage添加头像点击事件
   - [ ] 创建UserProfileSheet底部表单
   - [ ] 显示用户帖子网格
   - [ ] 添加关注/取消关注按钮
   - [ ] 实现关注列表页面

4. **Match流程整合**
   - [ ] Match成功后自动创建对话
   - [ ] 从MatchResultPage跳转到ChatPage
   - [ ] 在对话中显示Match来源标签

#### 验收标准
- ✅ 聊天界面流畅无卡顿
- ✅ 消息状态实时更新
- ✅ 可以查看对方主页和帖子
- ✅ 关注功能正常工作
- ✅ Match成功后可直接聊天

---

### 🔷 Stage 3: 多媒体支持（2-3天）
**目标**：支持图片、语音等富媒体消息

#### 任务清单
1. **图片消息**
   - [ ] 集成image_picker
   - [ ] 实现图片压缩（flutter_image_compress）
   - [ ] 上传到Firebase Storage
   - [ ] 生成缩略图
   - [ ] 实现图片预览（photo_view）
   - [ ] 添加图片保存功能

2. **语音消息**
   - [ ] 集成audio_recorder
   - [ ] 实现录音UI（按住说话）
   - [ ] 音频文件上传
   - [ ] 实现音频播放器
   - [ ] 显示音频波形/时长

3. **后端媒体处理**
   - [ ] uploadChatMedia Cloud Function
   - [ ] 图片自动压缩处理
   - [ ] 生成缩略图
   - [ ] 内容安全检测（Cloud Vision API）
   - [ ] 媒体文件访问令牌

4. **Storage Rules**
   - [ ] 限制文件大小和类型
   - [ ] 只有参与者可访问
   - [ ] 自动清理过期文件

#### 验收标准
- ✅ 可以发送图片并预览
- ✅ 可以录制和播放语音
- ✅ 媒体文件安全可控
- ✅ 上传进度可见

---

### 🔷 Stage 4: 高级功能与优化（3-4天）
**目标**：提升产品竞争力

#### 任务清单
1. **对话管理**
   - [ ] 对话置顶功能
   - [ ] 对话收藏/取消收藏
   - [ ] 对话删除确认
   - [ ] 对话标签系统
   - [ ] 对话设置页面（背景、通知）

2. **消息互动**
   - [ ] 消息引用回复
   - [ ] 消息表情反应
   - [ ] 消息撤回（限时）
   - [ ] 消息转发
   - [ ] 消息多选批量删除

3. **通知系统**
   - [ ] 集成FCM推送
   - [ ] 本地通知（flutter_local_notifications）
   - [ ] 通知点击跳转到对话
   - [ ] 通知设置页面
   - [ ] 免打扰模式

4. **搜索功能**
   - [ ] 对话搜索（用户名）
   - [ ] 消息全文搜索
   - [ ] 搜索历史记录
   - [ ] 搜索结果高亮

#### 验收标准
- ✅ 对话管理功能完整
- ✅ 消息互动丰富
- ✅ 通知及时准确
- ✅ 搜索快速有效

---

### 🔷 Stage 5: 性能与安全（持续优化）
**目标**：生产环境可用

#### 任务清单
1. **性能优化**
   - [ ] 实现消息虚拟滚动
   - [ ] 图片懒加载和缓存
   - [ ] 离线消息队列
   - [ ] 数据库复合索引
   - [ ] 减少不必要的监听

2. **安全加固**
   - [ ] 消息内容过滤
   - [ ] 举报功能
   - [ ] 频率限制（防刷屏）
   - [ ] 敏感词检测
   - [ ] 审计日志

3. **监控与分析**
   - [ ] 消息发送成功率
   - [ ] 平均响应延迟
   - [ ] 错误日志收集
   - [ ] 用户行为分析

#### 验收标准
- ✅ 高并发下稳定运行
- ✅ 恶意行为有效防范
- ✅ 关键指标可监控

---

## 安全与性能

### Security Rules 设计
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Conversations: 只有参与者可以访问
    match /conversations/{conversationId} {
      allow read: if request.auth != null 
        && request.auth.uid in resource.data.participantIds;
      
      allow create: if request.auth != null 
        && request.auth.uid in request.resource.data.participantIds;
      
      allow update: if request.auth != null 
        && request.auth.uid in resource.data.participantIds
        && request.auth.uid in request.resource.data.participantIds;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null 
          && request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
        
        allow create: if request.auth != null
          && request.auth.uid == request.resource.data.senderId
          && request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
        
        // 只能删除自己的消息
        allow delete: if request.auth != null
          && request.auth.uid == resource.data.senderId;
      }
    }
  }
}
```

### Storage Rules 设计
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /chat_media/{conversationId}/{messageId}/{filename} {
      // 只有对话参与者可以读取
      allow read: if request.auth != null
        && request.auth.uid in firestore.get(/databases/(default)/documents/conversations/$(conversationId)).data.participantIds;
      
      // 只有认证用户可以上传，大小限制10MB
      allow write: if request.auth != null
        && request.resource.size < 10 * 1024 * 1024
        && request.resource.contentType.matches('image/.*|audio/.*|video/.*');
    }
  }
}
```

### 性能优化策略

#### 1. Firestore优化
```javascript
// 创建复合索引
conversations
  - participantIds (array) + updatedAt (desc)
  - participantIds (array) + status + updatedAt (desc)

messages
  - conversationId + createdAt (desc)
  - senderId + createdAt (desc)
```

#### 2. 分页加载
```dart
// 每次加载20条消息
const int MESSAGE_PAGE_SIZE = 20;

// 使用游标分页
Query query = messagesRef
  .orderBy('createdAt', descending: true)
  .limit(MESSAGE_PAGE_SIZE);

if (lastDocument != null) {
  query = query.startAfterDocument(lastDocument);
}
```

#### 3. 消息缓存策略
```dart
// 使用Hive本地缓存
@HiveType(typeId: 1)
class CachedMessage {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String conversationId;
  
  @HiveField(2)
  String text;
  
  @HiveField(3)
  DateTime timestamp;
}

// 缓存最近100条消息
const int CACHE_SIZE = 100;
```

#### 4. 图片优化
```dart
// 压缩图片到最大800x800
Future<File> compressImage(File image) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    image.absolute.path,
    '${image.parent.path}/compressed_${image.path.split('/').last}',
    quality: 85,
    minWidth: 800,
    minHeight: 800,
  );
  return File(result!.path);
}

// 生成缩略图 200x200
Future<String> generateThumbnail(File image) async {
  final thumbnail = await FlutterImageCompress.compressAndGetFile(
    image.absolute.path,
    '${image.parent.path}/thumb_${image.path.split('/').last}',
    quality: 70,
    minWidth: 200,
    minHeight: 200,
  );
  // 上传并返回URL
  return await uploadToStorage(thumbnail);
}
```

---

## 📱 参考小红书特性

### 临时对话框模式
- ✅ Match后自动创建，无需手动添加好友
- ✅ 对话可以收藏变成"常用联系人"
- ✅ 非收藏对话7天无消息后自动归档
- ✅ 归档对话仍可搜索和恢复

### 轻量级社交
- ✅ 点击头像直接进入主页
- ✅ 主页展示帖子网格（类似Instagram）
- ✅ 支持关注/取消关注
- ✅ 显示互相关注状态
- ✅ 关注列表和粉丝列表

### 消息体验
- ✅ 输入框智能扩展（1-4行）
- ✅ 消息气泡圆角设计
- ✅ 消息时间戳智能显示（5分钟以上才显示）
- ✅ 图片消息自动适配尺寸
- ✅ 长按消息显示操作菜单

---

## 🎯 优先级排序

### P0 - 必须有（MVP）
1. 文本消息实时收发
2. 对话列表显示
3. Match成功创建对话
4. 基础消息UI
5. 用户头像点击查看主页

### P1 - 应该有（Beta）
1. 图片消息
2. 对话收藏/置顶
3. 未读消息提示
4. 消息状态显示
5. 关注功能
6. 消息搜索

### P2 - 可以有（V1.0）
1. 语音消息
2. 消息表情反应
3. 消息撤回
4. 通知推送
5. 对话设置
6. 消息转发

### P3 - 锦上添花（后续版本）
1. 视频消息
2. 消息加密
3. 消息翻译
4. AI智能回复建议
5. 聊天数据统计
6. 消息导出

---

## 📊 里程碑时间表

| 阶段 | 功能 | 预计时间 | 产出 |
|------|------|----------|------|
| Stage 1 | 基础架构 | 2天 | 可发送文本消息 |
| Stage 2 | UI增强 | 3天 | 完整聊天体验 |
| Stage 3 | 多媒体 | 3天 | 图片/语音消息 |
| Stage 4 | 高级功能 | 4天 | 对话管理/通知 |
| Stage 5 | 优化 | 持续 | 性能/安全 |

**总计：约2周完成MVP + Beta版本**

---

## 🔧 开发注意事项

### 1. Firebase Emulator配置
```bash
# 确保emulator包含以下服务
firebase emulators:start --only firestore,storage,functions

# 前端连接emulator
void connectToEmulator() {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

### 2. 测试数据生成
```dart
// 创建测试对话和消息
Future<void> seedChatData() async {
  final testUsers = ['user1', 'user2', 'user3'];
  
  for (var i = 0; i < testUsers.length; i++) {
    final conversationId = 'test_conv_$i';
    await FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .set({
        'participantIds': ['current_user_id', testUsers[i]],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': {
          'text': 'Hello from ${testUsers[i]}',
          'senderId': testUsers[i],
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
    
    // 添加10条测试消息
    for (var j = 0; j < 10; j++) {
      await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
          'text': 'Test message $j',
          'senderId': j % 2 == 0 ? 'current_user_id' : testUsers[i],
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'text',
          'status': 'sent',
        });
    }
  }
}
```

### 3. 错误处理最佳实践
```dart
Future<void> sendMessage(String text) async {
  try {
    // 1. 先本地展示（乐观更新）
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      senderId: currentUserId,
      status: MessageStatus.sending,
    );
    _addMessageToUI(tempMessage);
    
    // 2. 发送到服务器
    final result = await _chatService.sendMessage(conversationId, text);
    
    // 3. 更新消息状态
    _updateMessageStatus(tempMessage.id, MessageStatus.sent, result.id);
    
  } catch (e) {
    // 4. 失败时标记重试
    _updateMessageStatus(tempMessage.id, MessageStatus.failed);
    _showRetryOption(tempMessage);
  }
}
```

---

## ✅ 验收清单

### 功能验收
- [ ] 用户可以发送和接收文本消息
- [ ] 消息实时同步，无明显延迟
- [ ] 对话列表正确显示最新消息和时间
- [ ] 未读消息计数准确
- [ ] 图片可以发送、接收、预览
- [ ] 点击头像可以查看用户主页
- [ ] 关注/取消关注功能正常
- [ ] 对话可以收藏和置顶
- [ ] 消息搜索功能有效
- [ ] Match成功后自动创建对话

### 性能验收
- [ ] 消息列表滚动流畅（60fps）
- [ ] 首屏消息加载时间 < 1秒
- [ ] 图片加载使用渐进式显示
- [ ] 应用内存占用合理（< 200MB）
- [ ] 离线状态下可查看历史消息

### 安全验收
- [ ] 用户只能看到自己的对话
- [ ] 无法读取他人的消息
- [ ] 媒体文件访问受限
- [ ] 敏感词过滤生效
- [ ] 举报功能可用

---

## 📚 相关技术栈

### Flutter依赖
```yaml
dependencies:
  # Firebase
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  firebase_auth: ^4.15.3
  firebase_messaging: ^14.7.9
  
  # 状态管理
  provider: ^6.1.1
  riverpod: ^2.4.9 # 可选
  
  # 媒体处理
  image_picker: ^1.0.7
  flutter_image_compress: ^2.1.0
  photo_view: ^0.14.0
  cached_network_image: ^3.3.1
  
  # 音频
  audio_recorder: ^2.0.0
  just_audio: ^0.9.36
  
  # 通知
  flutter_local_notifications: ^16.3.0
  
  # UI组件
  intl: ^0.18.1 # 时间格式化
  timeago: ^3.6.0
  emoji_picker_flutter: ^1.6.3
  
  # 本地存储
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

### 推荐插件
- **dash_chat_2**: 开箱即用的聊天UI组件（可参考）
- **flutter_chat_ui**: 另一个聊天UI库
- **stream_chat_flutter**: 功能完整的聊天SDK（参考设计）

---

## 🎨 UI设计原则

### 保持现有风格
- 延续 Cormorant Garamond 字体
- 保持温暖的色调和圆角设计
- 动画流畅自然（Cubic贝塞尔曲线）
- 气泡设计带小尾巴
- 输入框圆角24px

### 色彩方案
```dart
// 消息气泡
final myMessageColor = profile.accent.withOpacity(0.9); // 用户主题色
final otherMessageColor = Colors.white;
final backgroundColor = Color(0xFFE2E0DE);

// 状态指示
final sendingColor = Colors.grey[400];
final sentColor = Colors.grey[600];
final readColor = profile.accent;

// 图标
final favoriteColor = Colors.amber;
final pinnedColor = Colors.blue[700];
```

---

## 🚀 快速开始

### 1. 克隆并安装依赖
```bash
cd /Users/wangshiwen/Desktop/workspace/flutter_app
flutter pub get
cd backend/functions
npm install
```

### 2. 启动Firebase Emulator
```bash
./START_BACKEND.sh
```

### 3. 运行应用
```bash
flutter run -d chrome
```

### 4. 生成测试数据
```bash
# 运行数据填充脚本
./SEED_CHAT_DATA.sh
```

---

## 📞 联系与支持

遇到问题请检查：
1. Firebase Emulator是否正常运行
2. Firestore Rules是否正确配置
3. 查看浏览器控制台错误信息
4. 查看Flutter日志输出

---

**祝开发顺利！🎉**

_最后更新：2025-11-16_
