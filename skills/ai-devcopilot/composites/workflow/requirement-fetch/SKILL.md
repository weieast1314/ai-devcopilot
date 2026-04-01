---
name: requirement-fetch
description: 多来源需求获取。支持飞书文档、文字描述等多种输入，统一输出标准化需求信息。
triggers:
  - 需求获取
  - /requirement-fetch
---

# Requirement Fetch (需求获取)

这是一个组合 Skill，用于从多种来源获取需求信息并统一输出标准化结构。

## 输入标准化

- **输入**: 用户提供的任意内容
- **格式**: 飞书链接、文字描述、Issue 链接等

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

## 组合的原子 Skill

| 步骤 | Skill | 说明 |
|------|-------|------|
| 1 | `input-detect` | 检测输入类型 |
| 2a | `feishu-doc-fetch` | 飞书链接 → 获取文档内容 |
| 2b | `requirement-extract` | 文字描述 → 提取需求信息 |
| 3 | `requirement-parse` | 统一解析为标准结构 |

## 执行流程

```
┌─────────────────────────────────────────────────────────────┐
│               Requirement Fetch Flow                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  用户输入                                                     │
│      │                                                       │
│      ▼                                                       │
│  [input-detect] ──► 检测类型                                  │
│      │                                                       │
│      ├─► [feishu-doc] ──► [feishu-doc-fetch]                 │
│      │                              │                        │
│      └─► [text-desc] ──► [requirement-extract]               │
│                                     │                        │
│                                     ▼                        │
│                              [requirement-parse]              │
│                                     │                        │
│                                     ▼                        │
│                              标准化需求                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 阶段 1: 输入检测

调用 [Input Detect](../../../atoms/analysis/input-detect/SKILL.md) 识别输入类型。

```
--- 🔍 输入类型检测 ---

✓ 检测类型: 飞书文档 / 文字描述 / Issue 链接
✓ 路由目标: feishu-doc-fetch / requirement-extract

📊 进度: 1/3 (33%)
⏭️  下一步: 获取/提取需求内容
```

### 阶段 2: 需求获取（条件分支）

**分支 A: 飞书文档**

调用 [Feishu Doc Fetch](../../../atoms/feishu/feishu-doc-fetch/SKILL.md) 获取文档内容。

```
--- 📄 飞书文档获取 ---

✓ 文档类型: Wiki / Docx
✓ 文档标题: 用户登录
✓ 内容长度: 1,234 字符

📊 进度: 2/3 (67%)
⏭️  下一步: 解析需求
```

**分支 B: 文字描述**

调用 [Requirement Extract](../../../atoms/analysis/requirement-extract/SKILL.md) 提取需求信息。

```
--- 📋 需求提取 ---

✓ Issue ID: 23181
✓ 类型: feat
✓ 描述: user-login
✓ 标题: 用户登录

📊 进度: 2/3 (67%)
⏭️  下一步: 解析需求
```

### 阶段 3: 标准化需求

调用 [Requirement Parse](../../../atoms/analysis/requirement-parse/SKILL.md) 生成标准结构。

```
--- 📋 需求解析 ---

✓ 来源: 飞书文档 / 文字描述
✓ 标题: 用户登录
✓ Issue: #23181
✓ 类型: feat
✓ 分支: feat/23181-user-login

📊 进度: 3/3 (100%)
✅ 当前阶段已完成！
```

> **阶段引导**: 需求解析完成后必须使用 `ask_followup_question` 工具引导用户：
> ```
> 问题: "需求信息已提取并标准化，请选择下一步操作："
> 选项:
>   1. "继续 - 创建开发分支并开始开发（进入下一阶段）" (trigger: "继续")
>   2. "修改需求信息 - 调整标题、类型或分支名称建议" (trigger: "修改需求")
>   3. "取消流程 - 放弃当前需求处理" (trigger: "取消")
> ```

## 使用示例

**场景 1: 飞书文档**
```
输入: https://xxx.feishu.cn/wiki/wikcnABC123

输出:
  source: feishu
  title: 用户登录
  issue_id: 23181
  type: feat
  branch_name: feat/23181-user-login
```

**场景 2: 文字描述**
```
输入: #23181 需要做一个用户登录

输出:
  source: text
  title: 用户登录
  issue_id: 23181
  type: feat
  branch_name: feat/23181-user-login
```

## 相关技能

- [Input Detect](../../../atoms/analysis/input-detect/SKILL.md)
- [Feishu Doc Fetch](../../../atoms/feishu/feishu-doc-fetch/SKILL.md)
- [Requirement Extract](../../../atoms/analysis/requirement-extract/SKILL.md)
- [Requirement Parse](../../../atoms/analysis/requirement-parse/SKILL.md)
