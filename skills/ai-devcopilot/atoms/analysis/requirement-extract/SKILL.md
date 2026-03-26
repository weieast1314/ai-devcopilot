---
name: requirement-extract
description: 从文字描述中提取结构化需求信息。
triggers:
  - 提取需求
  - 解析描述
---

# Requirement Extract (需求提取)

这个技能用于从用户的文字描述中提取结构化的需求信息。

## 输入标准化

- **输入**: 用户的文字描述
- **格式**: 自然语言描述

## 输出标准化

```yaml
title: 需求标题
issue_id: Issue ID（如无则为空）
type: feat | fix | refactor | optimize
description: 英文简短描述（用于分支命名）
summary: 需求摘要
```

## 执行流程

### 步骤 1: 提取 Issue ID

```
匹配规则:
- #数字 格式: #23181
- [A-Z]+-\d+ 格式: PROJ-123
- 提取第一个匹配项
```

### 步骤 2: 识别需求类型

```
关键词匹配:
- feat: 新增、新增功能、开发、实现
- fix: 修复、bug、问题
- refactor: 重构、优化代码结构
- optimize: 优化、性能提升
```

### 步骤 3: 生成描述标识

```
规则:
1. 提取核心功能关键词
2. 转换为英文
3. 使用下划线连接
4. 全部小写

示例:
"用户登录" → "user-login"
```

### 步骤 4: 返回结构化信息

```
═══════════════════════════════════════════
📋 需求提取结果
═══════════════════════════════════════════

✓ Issue ID: 23181
✓ 类型: feat
✓ 描述: user-login
✓ 标题: 用户登录

📊 状态: 提取完成
⏭️  下一步: 创建开发分支
```

## 使用示例

**输入**:
```
#23181 需要做一个用户登录，能够自动识别用户问题类型并路由到对应客服
```

**输出**:
```yaml
title: 用户登录
issue_id: 23181
type: feat
description: user-login
summary: 实现AI大模型客服问题自动分类，自动识别用户问题类型并路由
```

**输入**:
```
修复用户登录时的token过期问题
```

**输出**:
```yaml
title: 修复用户登录token过期问题
issue_id: null
type: fix
description: fix_login_token
summary: 修复用户登录时token过期导致的问题
```

## 相关技能

- [Input Detect](../input-detect/SKILL.md)
- [Requirement Parse](../requirement-parse/SKILL.md)
