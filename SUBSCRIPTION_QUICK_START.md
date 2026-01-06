# 订阅功能 - 快速启动指南

## 🚀 5分钟快速开始

### 前提条件
- ✅ Firebase 项目已配置
- ✅ Flutter 开发环境已设置
- ✅ 后端已运行（`./START_BACKEND.sh`）

---

## 📝 步骤

### 1. 部署后端函数（2分钟）

```bash
# 进入函数目录
cd backend/functions

# 构建 TypeScript
npm run build

# 部署 Cloud Functions
firebase deploy --only functions

# 或仅部署会员相关函数
firebase deploy --only functions:upgradeMembership,functions:cancelMembership,functions:checkMembershipExpiry
```

**预期输出**:
```
✔  functions[upgradeMembership(us-central1)] Successful update operation.
✔  functions[cancelMembership(us-central1)] Successful update operation.
✔  functions[checkMembershipExpiry(us-central1)] Successful update operation.
```

---

### 2. 迁移现有用户数据（1分钟）

⚠️ **仅在有现有用户时需要运行**

```bash
# 返回项目根目录
cd ../..

# 运行迁移脚本
node scripts/migrate_membership_fields.js
```

**预期输出**:
```
🔄 Starting membership fields migration...
📊 Found 10 users to check
✅ Queued user123 for update (Alice)
✅ Queued user456 for update (Bob)
...
💾 Committed final batch of 10 updates
✅ Migration completed successfully!
   - Updated: 10 users
   - Skipped: 0 users
```

---

### 3. 启动应用测试（2分钟）

```bash
# 启动 Flutter 应用
flutter run -d chrome
```

#### 测试流程：

##### A. 测试新用户（默认 Free）
1. 注册新账号
2. 查看个人资料 → 应显示 "Free" 会员
3. 进入 Post 页面 → 显示 "3次/天" 限制提示

##### B. 测试订阅流程
1. 点击右上角升级按钮或导航到订阅页面
2. 选择 "Premium" 套餐
3. 勾选"同意条款"
4. 点击"Subscribe"
5. 等待 2 秒模拟支付
6. 看到成功弹窗 ✅

##### C. 测试会员权限
1. 返回 Post 页面
2. 应该不再显示解锁限制
3. 可以无限解锁帖子
4. 右上角功能完全可用

---

## 🔍 验证检查清单

### 后端验证
```bash
# 查看 Cloud Functions 日志
firebase functions:log --only upgradeMembership

# 检查 Firestore 数据
# 在 Firebase Console > Firestore > users/{userId}
# 应该看到：
# - membershipTier: "premium"
# - membershipExpiry: Timestamp
# - subscriptionId: "sub_xxx"
```

### 前端验证
```dart
// 在 Flutter DevTools Console 查看日志
// 应该看到：
🔄 [SUBSCRIBE] Upgrading membership via Cloud Function...
✅ [SUBSCRIBE] Membership upgraded successfully
✅ [POST_PAGE] State updated with membership: premium
```

---

## 🐛 常见问题排查

### 问题 1: Cloud Function 调用失败

**症状**: 订阅时报错 "Failed to upgrade membership"

**检查**:
```bash
# 查看函数日志
firebase functions:log

# 确认函数已部署
firebase functions:list | grep membership
```

**解决**:
```bash
# 重新部署函数
cd backend/functions
npm run build
firebase deploy --only functions
```

---

### 问题 2: 状态未更新

**症状**: 订阅成功但 Post 页面仍显示限制

**检查**:
```dart
// 在 subscribe_page.dart 的 _subscribe 方法中添加日志
print('Current user tier: ${_currentUser?.membershipTier.name}');
print('Effective tier: ${_currentUser?.effectiveTier.name}');
```

**解决**:
1. 确保订阅后调用了 `_loadCurrentUser()`
2. 确保 Post 页面使用 `effectiveTier` 而不是 `membershipTier`
3. 重启应用重新加载数据

---

### 问题 3: 迁移脚本失败

**症状**: `Error: Could not load the default credentials`

**解决**:
```bash
# 下载 service account key
# Firebase Console > Project Settings > Service Accounts
# 点击 "Generate new private key"
# 保存为 backend/service-account-key.json

# 重新运行迁移
node scripts/migrate_membership_fields.js
```

---

## 📊 监控和维护

### 每日检查
```bash
# 查看订阅数量
# Firebase Console > Firestore
# 查询: users where membershipTier != 'free'
```

### 每周检查
```bash
# 查看会员过期情况
firebase functions:log --only checkMembershipExpiry

# 查看 Cloud Functions 使用量
# Firebase Console > Functions > Usage
```

### 每月检查
```bash
# 审计订阅记录
# Firestore > users/{userId}/subscriptions
# 检查 status 分布: active, cancelled, expired
```

---

## 🎯 下一步

### 立即可做
1. ✅ 测试完整订阅流程
2. ✅ 验证会员权限生效
3. ✅ 检查日志确认无错误

### 近期计划
1. 🔄 集成真实支付系统（Stripe/PayPal）
2. 🔄 添加订阅管理页面
3. 🔄 实现优惠码功能

### 长期规划
1. 📊 订阅数据分析仪表板
2. 🤖 自动化营销和提醒
3. 🌟 VIP 专属功能开发

---

## 📚 相关文档

- 📖 **技术路线**: `SUBSCRIPTION_BACKEND_TODO.md`
- 📖 **实施报告**: `SUBSCRIPTION_IMPLEMENTATION_COMPLETE.md`
- 📖 **测试脚本**: `TEST_SUBSCRIPTION.sh`
- 📖 **迁移脚本**: `scripts/migrate_membership_fields.js`

---

## 💡 提示

### 测试模式
开发时可以手动设置会员状态：
```bash
# Firebase Console > Firestore > users/{userId}
# 直接修改：
membershipTier: "premium"
membershipExpiry: (未来的时间戳)
```

### 快速重置
测试后重置用户状态：
```bash
# 设置为 free
membershipTier: "free"
membershipExpiry: null
subscriptionId: null
```

---

## ✅ 成功标志

当你看到以下情况时，说明订阅功能已正确运行：

1. ✅ 新用户默认为 Free tier
2. ✅ 订阅流程顺利完成
3. ✅ 会员状态立即生效
4. ✅ Post 页面权限正确显示
5. ✅ Firebase Console 数据完整
6. ✅ 日志无错误信息

---

🎉 **恭喜！你的订阅功能已就绪！**

如有问题，请查看 `SUBSCRIPTION_IMPLEMENTATION_COMPLETE.md` 的"调试指南"部分。
