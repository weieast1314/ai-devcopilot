---
name: input-detect
description: 自动识别输入类型并路由到对应的处理流程。
triggers:
  - 自动识别
  - 输入检测
version: 1.1.0
---

# Input Detect (输入检测)

这个技能用于自动识别用户输入的类型，并路由到对应的处理流程。

> **重要**: 此 skill 是组合层 `requirement-fetch` 的内部组件，**不应被 AI 编辑器直接调用**。
> 用户输入应先经过 `entry-router` 路由到 Pipeline，再由 Pipeline 调用组合层。

## 输入标准化

- **输入**: 用户提供的任意内容（链接、文字描述等）
- **格式**: 无限制

## 输出标准化

- **类型**: `feishu-doc` | `feishu-wiki` | `text-description` | `issue-link` | `unknown`
- **原始内容**: 用户输入的原始内容
- **路由目标**: 应该调用的下一个 Skill（原子层）

## 支持的输入类型

| 类型 | 识别规则 | 路由到 |
|------|----------|--------|
| 飞书文档 | 包含 `feishu.cn/docx` | `feishu-doc-fetch` |
| 飞书 Wiki | 包含 `feishu.cn/wiki` | `feishu-doc-fetch` |
| 飞书其他 | 包含 `feishu.cn` | `feishu-doc-fetch` |
| 文字描述 | 不含链接，包含需求描述 | `requirement-extract` |
| Issue 链接 | 包含 `jira` 或 `github.com/issues` | `issue-fetch` |

## 执行流程

### 步骤 1: 检测输入类型

```
检测规则（按优先级）:
1. 是否包含 feishu.cn/docx → 飞书文档
2. 是否包含 feishu.cn/wiki → 飞书 Wiki
3. 是否包含 jira 或 github.com/issues → Issue 链接
4. 其他情况 → 文字描述
```

### 步骤 2: 返回识别结果

```
--- 🔍 输入类型检测 ---

✓ 检测类型: 飞书文档
✓ 路由目标: feishu-doc-fetch

📊 状态: 准备就绪
⏭️  下一步: 获取文档内容
```

## 使用示例

**示例 1：飞书链接**
```
输入: https://xxx.feishu.cn/wiki/wikcnABC123

输出:
  类型: feishu-wiki
  路由: feishu-doc-fetch
```

**示例 2：文字描述**
```
输入: #23181 需要做一个用户登录

输出:
  类型: text-description
  路由: requirement-extract
```

**示例 3：混合内容**
```
输入: 参考这个飞书文档实现新功能 https://xxx.feishu.cn/docx/ABC

输出:
  类型: feishu-doc
  路由: feishu-doc-fetch
  备注: 提取到飞书链接，忽略其他文字
```

## 相关技能

- [Feishu Doc Fetch](../../feishu/feishu-doc-fetch/SKILL.md)
- [Requirement Extract](../requirement-extract/SKILL.md)
