# 数据持久化说明

## 📂 数据保存情况

您的所有虚拟数据已经**保存在项目中**，包括：

### ✅ 已保存的数据
- **20个测试用户** (Auth + Firestore)
- **35个精美社区帖子** (包含图片和丰富内容)
- **207个匹配关系** (基于用户特征的智能匹配)
- **完整的用户档案** (头像、特征、自我介绍等)

### 📁 数据存储位置
- `./emulator-data/` - Firebase模拟器数据导出
- `./backend/functions/` - 数据生成脚本

## 🔄 重启后恢复数据

### 方法1: 自动恢复（推荐）
您的 `START_BACKEND.sh` 脚本已经配置为自动导入数据：

```bash
./START_BACKEND.sh
```

启动时会检查 `./emulator-data/` 目录，如果存在则自动导入所有数据。

### 方法2: 手动重新生成数据
如果数据丢失，运行数据重建脚本：

```bash
# 1. 启动后端模拟器
./START_BACKEND.sh

# 2. 在新终端中重新生成数据
./SEED_DATA.sh
```

## 🔑 测试账号信息

### 主要测试账号
- `diana@test.com` / `password123`
- `iris@test.com` / `password123` 
- `bob@test.com` / `password123`
- `test@example.com` / `123456`

### 所有用户的通用密码
- **密码**: `password123`

## 📊 数据统计

- **用户数**: 20个
- **匹配关系**: 207个
- **社区帖子**: 35个
- **每个用户**: 8-12个匹配对象
- **每个帖子**: 包含高质量图片和深度内容

## 🔧 数据管理命令

### 导出当前数据
```bash
firebase emulators:export ./emulator-data --force
```

### 查看数据状态
```bash
# 检查用户数
curl "http://localhost:8081/v1/projects/psycho-dating-app/databases/(default)/documents/users"

# 检查帖子数
curl "http://localhost:8081/v1/projects/psycho-dating-app/databases/(default)/documents/posts"
```

## ⚡ 快速启动指南

1. **启动后端**: `./START_BACKEND.sh`
2. **启动前端**: `flutter run` 
3. **登录测试**: 使用 `diana@test.com` / `password123`

您的数据会在每次启动时自动恢复，无需额外操作！