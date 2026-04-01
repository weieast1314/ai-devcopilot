---
name: requirement-parse
description: 统一解析需求信息为标准结构，支持多来源输入。
triggers:
  - 解析需求
  - 标准化需求
---

# Requirement Parse (需求解析)

这个技能用于将来自不同来源的需求信息统一解析为标准结构。

## 输入标准化

支持多种输入来源：
- **飞书文档**: 来自 `feishu-doc-fetch` 的文档内容
- **文字描述**: 来自 `requirement-extract` 的提取结果
- **Issue 链接**: 来自 `issue-fetch` 的 Issue 内容

## 输出标准化

```yaml
# 标准需求结构
source: feishu | text | issue
title: 需求标题
issue_id: Issue ID
type: feat | fix | hotfix | refactor
description: 英文简短描述
branch_name: 建议的分支名称
summary: 需求摘要
details: 详细需求内容（可选）
```

## 执行流程

### 步骤 1: 识别输入来源

```
来源类型:
- feishu: 飞书文档原始内容
- text: 已提取的结构化数据
- issue: Issue 内容
```

### 步骤 2: 统一解析

```
根据来源类型执行对应解析:
- feishu: 解析文档标题、提取 Issue ID、识别类型
- text: 直接使用传入的结构化数据
- issue: 解析 Issue 标题和描述
```

### 步骤 3: 生成分支名称

```
分支命名规则:
- feat/{issue_id}-{description}
- fix/{issue_id}-{description}
- refactor/{issue_id}-{description}

示例: feat/23181-user-login
```

### 步骤 4: 返回标准结构

```
--- 📋 需求解析结果 ---

来源: 飞书文档
标题: 用户登录
Issue: #23181
类型: feat
分支: feat/23181-user-login

📊 状态: 解析完成
⏭️  下一步: 创建开发分支
```

## 使用示例

**输入（来自飞书）**:
```markdown
# 用户登录

## 背景
#23181 客服系统需要智能分类能力...

## 需求描述
实现AI大模型客服问题自动分类...
```

**输出**:
```yaml
source: feishu
title: 用户登录
issue_id: 23181
type: feat
description: user-login
branch_name: feat/23181-user-login
summary: 实现AI大模型客服问题自动分类，自动识别用户问题类型并路由
```

## 相关技能

- [Input Detect](../input-detect/SKILL.md)
- [Requirement Extract](../requirement-extract/SKILL.md)
- [Feishu Doc Fetch](../../feishu/feishu-doc-fetch/SKILL.md)
