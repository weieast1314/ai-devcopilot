---
name: requirement-to-branch
description: 需求转分支。接收标准化需求信息，创建符合规范的开发分支。
triggers:
  - 需求转分支
  - /requirement-to-branch
---

# Requirement to Branch (需求转分支)

这是一个组合 Skill，用于接收标准化需求信息并创建对应的开发分支。

> ⚠️ **核心原则**：
> - **分支名称确定必须通过用户手动确认**
> - **AI 只能提供建议，绝不能直接决定分支策略**
> - **无论任何情况，都必须询问用户确认**

## 输入标准化

```yaml
# 来自 requirement-fetch 的标准需求结构
source: feishu | text | issue
title: 需求标题
issue_id: Issue ID
type: feat | fix | refactor | optimize
description: 英文简短描述
branch_name: 建议的分支名称
summary: 需求摘要
```

## 输出标准化

```yaml
branch_name: 创建的分支名称
base_branch: 基分支
created_at: 创建时间
requirement: 原始需求信息（透传）
```

## 组合的原子 Skill

| 步骤 | Skill | 说明 |
|------|-------|------|
| 1 | `git-branch-create` | 创建开发分支 |
| 2 | `git-branch-validate` | 验证分支命名（可选） |

## 执行流程

```
┌─────────────────────────────────────────────────────────────┐
│             Requirement to Branch Flow                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  标准化需求                                                   │
│      │                                                       │
│      ▼                                                       │
│  [git-branch-create] ──► 检测已存在分支 ──► 必须询问用户确认   │
│      │                                                       │
│      ▼                                                       │
│  [git-branch-validate] ──► 验证命名（可选）                    │
│      │                                                       │
│      ▼                                                       │
│  分支信息 + 原始需求                                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

> ⚠️ **强制要求**：在 `git-branch-create` 执行过程中，每一步涉及分支决策的环节都必须通过 `ask_followup_question` 工具询问用户确认，禁止 AI 自行决定。

### 阶段 1: 创建分支

调用 [Git Branch Create](../../../atoms/git/git-branch-create/SKILL.md) 创建开发分支。

```
═══════════════════════════════════════════
🌿 分支创建
═══════════════════════════════════════════

需求信息:
  标题: 用户登录
  Issue: #23181
  类型: feat

正在创建分支...
✓ 分支名称: feat/23181-user-login
✓ 基分支: main

📊 进度: 1/2 (50%)
⏭️  下一步: 验证分支命名
```

### 阶段 2: 验证分支（可选）

调用 [Git Branch Validate](../../../atoms/git/git-branch-validate/SKILL.md) 验证分支命名。

```
═══════════════════════════════════════════
✅ 分支验证
═══════════════════════════════════════════

✓ 分支命名符合规范
✓ 格式: feat/{issue_id}-{description}

📊 进度: 2/2 (100%)
✅ 当前阶段已完成！

═══════════════════════════════════════════
📋 需求转分支 - 已完成
═══════════════════════════════════════════

分支: feat/23181-user-login
需求: 用户登录

📌 说明:
   - 分支已创建完成
   - 可继续进入"计划模式"生成执行计划
   - 计划生成后默认暂停，不会直接改代码
```

> **阶段引导**: 分支创建完成后必须使用 `ask_followup_question` 工具引导用户：
> ```
> 问题: "开发分支已创建完成，请选择下一步操作："
> 选项:
>   1. "继续 - 生成执行计划（进入计划模式）" (trigger: "继续")
>   2. "修改分支名称 - 删除当前分支并重新创建" (trigger: "修改分支")
>   3. "取消流程 - 删除分支并放弃本次开发" (trigger: "取消")
> ```

## 使用示例

**输入（来自 requirement-fetch）**:
```yaml
source: feishu
title: 用户登录
issue_id: 23181
type: feat
description: user-login
branch_name: feat/23181-user-login
```

**输出**:
```yaml
branch_name: feat/23181-user-login
base_branch: main
created_at: 2026-03-24 10:30:00
requirement:
  source: feishu
  title: 用户登录
  issue_id: 23181
  type: feat
```

## 与其他 Composites 的关系

- **上游**: [Requirement Fetch](../requirement-fetch/SKILL.md) - 提供标准化需求
- **下游**: [Writing Plans](../../../atoms/planning/writing-plans/SKILL.md) - 生成执行计划

## 相关技能

- [Git Branch Create](../../../atoms/git/git-branch-create/SKILL.md)
- [Git Branch Validate](../../../atoms/git/git-branch-validate/SKILL.md)
- [Requirement Fetch](../requirement-fetch/SKILL.md)
