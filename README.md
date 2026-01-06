# Psycho - AI-Powered Social Matching App

一个使用Flutter开发的AI驱动社交匹配应用，支持真实的LLM评估和智能匹配。

## 🚀 快速开始

### 前置要求
- Flutter SDK (3.9.2+)
- Node.js (18+)
- Firebase CLI
- Google AI Studio API Key

### 管理firebase
```bash
firebase init emulators
```

### 运行脚本
```bash
chmod +x . SEED_DATA.sh
chmod +x . START_BACKEND.sh

# Terminal 1 运行firebase模拟器（数据+函数+储存）
./START_BACKEND.sh
# Terminal 2 创建虚拟用户（匹配+发帖+评论）
./SEED_DATA.sh
# Terminal 2 运行flutter
flutter run -d chrome
```

### RoadMap
[ ]
