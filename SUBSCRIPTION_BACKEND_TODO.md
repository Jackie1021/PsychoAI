# 订阅功能后端完善 - 技术路线

## 📋 现状分析

### 已实现功能
1. ✅ 前端订阅页面 (`subscribe_page.dart`)
2. ✅ 用户数据模型包含会员字段 (`user_data.dart`)
3. ✅ 会员服务类 (`membership_service.dart`)
4. ✅ 后端会员处理器 (`membership_handler.ts`)
5. ✅ Post页面有会员检查逻辑

### 存在的问题
1. ❌ **订阅状态更新不同步**：前端订阅后，后端数据未正确更新
2. ❌ **Firebase API Service 缺少会员更新方法**：`updateUser` 方法不更新会员字段
3. ❌ **Post页面权限检查可能过时**：状态刷新不及时
4. ❌ **后端用户创建时缺少会员默认值**：新用户缺少 `membershipTier` 字段
5. ❌ **Cloud Function 调用缺失**：前端未调用后端的 `upgradeMembership` 函数

---

## 🎯 实施方案

### Phase 1: 后端数据模型完善 ✅
**目标**：确保所有用户文档包含会员字段

#### 1.1 修复用户创建函数
- 📁 文件：`backend/functions/src/user_handler.ts`
- 🔧 修改：`onUserCreated` 函数添加会员默认字段
```typescript
membershipTier: "free",
membershipExpiry: null,
subscriptionId: null,
```

#### 1.2 修复会员更新函数
- 📁 文件：`backend/functions/src/membership_handler.ts`
- ✅ 已实现：`upgradeMembership` 和 `cancelMembership`
- 🔍 检查：确保返回完整的用户数据

---

### Phase 2: Firebase API Service 集成 ✅
**目标**：前端能调用后端会员服务

#### 2.1 添加会员管理方法到 API Service
- 📁 文件：`lib/services/api_service.dart`
- 🔧 添加方法：
```dart
Future<void> upgradeMembership({
  required MembershipTier tier,
  required int durationDays,
  String? subscriptionId,
});

Future<void> cancelMembership();
```

#### 2.2 实现 Firebase API Service
- 📁 文件：`lib/services/firebase_api_service.dart`
- 🔧 实现：调用 Cloud Functions
```dart
final callable = _functions.httpsCallable('upgradeMembership');
await callable.call({
  'tier': tier.name,
  'durationDays': durationDays,
  'subscriptionId': subscriptionId,
});
```

#### 2.3 修复 updateUser 方法
- 📁 文件：`lib/services/firebase_api_service.dart`
- 🔧 修改：`updateUser` 方法包含会员字段
```dart
'membershipTier': user.membershipTier.name,
'membershipExpiry': user.membershipExpiry != null 
    ? Timestamp.fromDate(user.membershipExpiry!) 
    : null,
'subscriptionId': user.subscriptionId,
```

---

### Phase 3: 前端订阅流程优化 ✅
**目标**：订阅成功后立即更新状态

#### 3.1 修改订阅页面
- 📁 文件：`lib/pages/subscribe_page.dart`
- 🔧 修改：使用 Cloud Function 而非直接更新
```dart
final apiService = locator<ApiService>();
await apiService.upgradeMembership(
  tier: selectedPlan.tier,
  durationDays: 30,
  subscriptionId: subscriptionId,
);
```

#### 3.2 优化 Post 页面状态刷新
- 📁 文件：`lib/pages/post_page.dart`
- 🔧 改进：订阅回调后刷新用户状态
- ✅ 已实现：`.then((result) => _loadCurrentUser())`

---

### Phase 4: 数据一致性保证 ✅
**目标**：确保前后端数据一致

#### 4.1 用户数据映射完善
- 📁 文件：`lib/services/firebase_api_service.dart`
- 🔧 检查：`_mapUserData` 方法正确解析会员字段
```dart
MembershipTier tier = MembershipTier.free;
if (data.containsKey('membershipTier')) {
  tier = MembershipTier.values.firstWhere(
    (e) => e.name == data['membershipTier'],
    orElse: () => MembershipTier.free,
  );
}
```

#### 4.2 添加会员状态缓存
- 使用 Provider 或 Riverpod 管理全局会员状态
- 订阅后通知所有监听的页面

---

### Phase 5: Post 解锁功能集成 ✅
**目标**：Premium用户无限制解锁

#### 5.1 Post 页面权限检查
- 📁 文件：`lib/pages/post_page.dart`
- ✅ 已实现：
  - `isPremiumUser = _membershipTier != MembershipTier.free`
  - 免费用户：3次/天限制
  - 付费用户：无限制

#### 5.2 右上角功能解锁
- 检查当前实现的"右上角功能"
- 根据 `isPremiumUser` 显示/隐藏

---

## 🔧 具体修改清单

### 必须修改的文件

1. **backend/functions/src/user_handler.ts**
   - 添加会员默认字段到 `onUserCreated`

2. **backend/functions/src/membership_handler.ts**
   - 确认 `upgradeMembership` 返回完整数据
   - 添加错误处理

3. **lib/services/api_service.dart**
   - 添加 `upgradeMembership` 接口
   - 添加 `cancelMembership` 接口

4. **lib/services/firebase_api_service.dart**
   - 实现 `upgradeMembership` 方法
   - 实现 `cancelMembership` 方法
   - 修复 `updateUser` 包含会员字段
   - 确认 `_mapUserData` 正确解析会员字段

5. **lib/pages/subscribe_page.dart**
   - 使用 Cloud Function 替代直接更新
   - 优化错误处理

6. **lib/pages/post_page.dart**
   - 确认状态刷新逻辑
   - 添加调试日志

---

## 🧪 测试计划

### 单元测试
1. 测试用户创建时的默认会员状态
2. 测试会员升级流程
3. 测试会员过期检查

### 集成测试
1. 新用户注册 → 检查默认 Free 状态
2. 订阅 Premium → 检查状态更新
3. Post 页面 → 检查解锁功能
4. 会员过期 → 检查自动降级

### E2E 测试
1. 完整订阅流程
2. 跨页面状态同步
3. 刷新后状态保持

---

## 📊 数据库字段规范

### users 集合
```json
{
  "uid": "string",
  "username": "string",
  "membershipTier": "free|premium|pro",
  "membershipExpiry": "Timestamp | null",
  "subscriptionId": "string | null",
  "lastActive": "Timestamp"
}
```

### users/{uid}/subscriptions 子集合
```json
{
  "tier": "premium",
  "startDate": "Timestamp",
  "expiryDate": "Timestamp",
  "subscriptionId": "sub_xxx",
  "status": "active|cancelled|expired",
  "durationDays": 30
}
```

---

## 🚀 实施顺序

1. ✅ **Phase 1**: 后端数据模型（10分钟）
2. ✅ **Phase 2**: API Service 集成（20分钟）
3. ✅ **Phase 3**: 前端订阅流程（15分钟）
4. ✅ **Phase 4**: 数据一致性（10分钟）
5. ✅ **Phase 5**: 测试验证（15分钟）

**预计总时间**: 70分钟

---

## 📝 注意事项

1. **向后兼容**：已有用户数据迁移脚本
2. **错误处理**：所有网络调用需 try-catch
3. **日志记录**：关键步骤添加 print 调试
4. **安全性**：Cloud Functions 认证检查
5. **性能**：缓存会员状态，减少查询

---

## 🎉 预期结果

- ✅ 用户订阅后立即生效
- ✅ Post 页面权限正确显示
- ✅ 会员状态跨页面同步
- ✅ 数据库数据完整一致
- ✅ 错误友好提示
