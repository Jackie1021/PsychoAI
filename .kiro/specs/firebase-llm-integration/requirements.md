# 需求文档

## 简介

本规范定义了将 LLM 驱动的匹配功能集成到 Flutter + Firebase 社交匹配应用中的需求。系统必须支持使用 Firebase Emulator 进行本地开发、安全的 API 密钥管理，以及自动化测试数据生成，以实现高效的开发和测试工作流。

## 术语表

- **系统（System）**: 与 Flutter 前端集成的 Firebase Cloud Functions 后端服务
- **模拟器（Emulator）**: 用于本地开发和测试的 Firebase Local Emulator Suite
- **LLM 服务（LLM Service）**: 用于生成匹配分析的 Google Gemini AI 服务
- **测试用户池（Test User Pool）**: 具有多样化特征的合成用户配置文件集合，用于测试匹配算法
- **API 密钥（API Key）**: Google Gemini API 身份验证凭据
- **匹配候选人（Match Candidate）**: 与当前用户评估兼容性的用户配置文件

## 需求

### 需求 1: Cloud Functions 模拟器集成

**用户故事:** 作为开发者，我希望 Cloud Functions 在本地 Firebase Emulator 中运行，以便我可以在不部署到生产环境的情况下开发和测试匹配系统。

#### 验收标准

1. WHEN 开发者运行模拟器启动脚本时，THE 系统 SHALL 将 TypeScript Cloud Functions 编译为 JavaScript
2. WHEN 编译成功完成时，THE 系统 SHALL 启动启用了 functions 的 Firebase Emulator
3. WHEN Flutter 应用调用 `getMatches` 时，THE 系统 SHALL 将请求路由到本地模拟器端点
4. WHEN Cloud Function 在模拟器中执行时，THE 系统 SHALL 将函数调用和响应记录到模拟器控制台
5. WHERE 模拟器正在运行时，THE 系统 SHALL 使所有函数可在 `http://localhost:5002` 访问

### 需求 2: 安全的 API 密钥管理

**用户故事:** 作为开发者，我希望 API 密钥安全地存储在版本控制之外，以便敏感凭据不会在仓库中暴露。

#### 验收标准

1. THE 系统 SHALL 从 functions 目录中的 `.env` 文件读取 Gemini API 密钥
2. THE 系统 SHALL 在 `.gitignore` 中包含 `.env` 以防止版本控制跟踪
3. WHEN `.env` 文件缺失时，THE 系统 SHALL 提供带有设置说明的清晰错误消息
4. THE 系统 SHALL 提供带有占位符值的 `.env.example` 模板文件
5. WHEN Cloud Functions 初始化时，THE 系统 SHALL 在处理请求之前验证 API 密钥是否存在
6. WHERE 模拟器正在运行时，THE 系统 SHALL 自动从 `.env` 文件加载环境变量

### 需求 3: 自动化测试用户生成

**用户故事:** 作为开发者，我希望在模拟器启动时自动创建测试用户，以便我可以立即测试匹配功能而无需手动设置数据。

#### 验收标准

1. WHEN Firebase Emulator 启动时，THE 系统 SHALL 执行数据填充脚本
2. THE 系统 SHALL 创建 10 到 20 个具有多样化特征组合的测试用户配置文件
3. WHEN 创建测试用户时，THE 系统 SHALL 为每个用户分配来自可用特征列表的唯一特征组合
4. THE 系统 SHALL 为每个测试用户配置文件生成真实的自由文本描述
5. WHEN 创建测试用户时，THE 系统 SHALL 将它们存储在 Firestore 的 `users` 集合中
6. THE 系统 SHALL 确保测试用户数据包含所有必需字段：uid、username、traits、freeText、avatarUrl
7. IF 数据库中已存在测试用户，THE 系统 SHALL 跳过创建以避免重复
8. WHEN 填充完成时，THE 系统 SHALL 将创建的测试用户数量记录到控制台

### 需求 4: 匹配函数错误处理

**用户故事:** 作为用户，我希望在匹配失败时收到清晰的错误消息，以便我了解出了什么问题并可以采取纠正措施。

#### 验收标准

1. WHEN 用户文档不存在时，THE 系统 SHALL 自动创建默认用户配置文件
2. IF Gemini API 密钥缺失或无效，THE 系统 SHALL 返回指示配置问题的错误消息
3. WHEN LLM 服务对特定匹配候选人失败时，THE 系统 SHALL 继续处理其他候选人
4. THE 系统 SHALL 在某些匹配成功而其他匹配失败时返回部分结果
5. WHEN 所有匹配尝试都失败时，THE 系统 SHALL 向客户端返回描述性错误消息

### 需求 5: 开发工作流集成

**用户故事:** 作为开发者，我希望使用单个命令启动完整的开发环境，以便我可以快速开始测试。

#### 验收标准

1. THE 系统 SHALL 提供按顺序执行所有初始化步骤的启动脚本
2. WHEN 启动脚本运行时，THE 系统 SHALL 检查所需的依赖项并报告缺失的依赖项
3. THE 系统 SHALL 在启动模拟器之前编译 TypeScript 函数
4. WHEN 编译失败时，THE 系统 SHALL 显示错误消息并停止启动过程
5. THE 系统 SHALL 在模拟器准备就绪后填充测试数据
6. WHEN 环境准备就绪时，THE 系统 SHALL 显示模拟器 UI 和函数端点的连接 URL
