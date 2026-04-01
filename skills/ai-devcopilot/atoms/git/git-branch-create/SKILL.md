---
name: git-branch-create
description: 创建符合规范的 Git 开发分支。
triggers:
  - 创建分支
  - 新建分支
  - /git-branch-create
---

# Git Branch Create (创建分支)

这个技能用于创建符合团队规范的 Git 开发分支。

## 输入标准化

```yaml
type: feat | fix | hotfix | refactor
issue_id: Issue ID（可选）
description: 英文简短描述
base_branch: 基分支（可选，默认当前分支）
```

## 输出标准化

```yaml
branch_name: 创建的分支名称
base_branch: 基分支
created_at: 创建时间
```

## 分支命名规范

| 类型 | 格式 | 示例 |
|------|------|------|
| feat | `feat/{issue_id}-{description}` | `feat/23181-user-login` |
| fix | `fix/{issue_id}-{description}` | `fix/23182-login_token` |
| refactor | `refactor/{issue_id}-{description}` | `refactor/23183-code_structure` |
| 无 Issue | `{type}/{description}` | `feat/user-login` |

## 执行流程

> ⚠️ **核心原则**：
> - **分支名称确定必须通过用户手动确认**
> - **AI 只能提供建议，绝不能直接决定分支策略**
> - **无论任何情况，都必须询问用户确认**

### 步骤 1: 检测已存在分支

在创建分支前，先检测是否存在相同 Issue ID 的分支：

```bash
# 查找已存在的相关分支
git branch -a | grep -E "(feat|fix|hotfix|refactor)/.*${issue_id}"
```

**检测结果处理（必须询问用户）**：

```
--- 🔍 分支检测 ---

当前需求 Issue: #23181
检测结果: 发现已存在相关分支
  - feat/23181-user-login
  - feat/23181-add_api

请选择分支策略：
1) 在现有分支继续开发 [需指定分支] - 继续在已存在的分支上开发
2) 创建新分支 - 创建一个新的分支进行开发
3) 切换到其他分支 - 切换到指定的其他分支

请选择 [1-3]:
```

> ⚠️ **强制要求**：即使检测到已存在相关分支，也**禁止**自动选择或跳过确认，必须使用 `ask_followup_question` 工具询问用户。

### 步骤 2: 确认基分支（必须询问用户）

> ⚠️ **强制要求**：此步骤必须使用 `ask_followup_question` 工具询问用户，不可自动选择或跳过。

```
--- 🌿 分支创建 ---

当前分支: main

请选择从哪个分支创建新分支：
1) 从 main 分支创建（默认稳定分支）[默认] - 推荐，适用于大多数标准开发
2) 从 当前 分支创建 - 基于当前所在的分支创建
3) 从 其他分支创建（手动输入） - 指定团队约定的基线分支名称
4) 不创建新分支，继续基于当前分支开发 - 适用于快速修复或小改动

请选择 [1-4]: 
```

**选项说明**：
| 选项 | 说明 | 适用场景 |
|------|------|----------|
| 1) main | 从默认稳定分支创建，推荐用于新功能开发 | 标准开发流程 |
| 2) 当前分支 | 从当前所在分支创建 | 延续当前工作 |
| 3) 其他分支 | 手动输入团队约定基线分支 | 特殊场景 |
| 4) 不创建 | 继续在当前分支开发 | 快速修复/小改动 |

### 步骤 3: 生成分支名称并确认（必须询问用户）

> ⚠️ **强制要求**：生成分支名称后，必须使用 `ask_followup_question` 工具询问用户确认或修改。

```
根据输入信息生成符合规范的分支名称:
- 类型: feat
- Issue: 23181
- 描述: user-login

→ 分支名称: feat/23181-user-login

请确认分支名称：
1) 确认使用此分支名称 [默认] - 使用生成的分支名称
2) 修改分支名称（手动输入） - 自定义分支名称
3) 重新生成（调整描述） - 调整描述后重新生成分支名称

请选择 [1-3]: 
```

**用户选择处理**：
| 选择 | 处理方式 |
|------|----------|
| 1) 确认 | 使用生成的分支名称，进入下一步 |
| 2) 修改 | 让用户输入新分支名称，校验格式后使用 |
| 3) 重新生成 | 让用户调整描述，重新生成分支名称 |

### 步骤 4: 创建分支

```bash
# 拉取最新代码
git fetch origin

# 创建并切换分支
git checkout -b feat/23181-user-login
```

### 步骤 5: 返回结果

```
--- 🌿 分支创建完成 ---

✓ 分支名称: feat/23181-user-login
✓ 基分支: main
✓ 创建时间: 2026-03-20 10:30:00

📊 状态: 分支已创建
⏭️  下一步: 开始开发
```

## 使用示例

**输入**:
```yaml
type: feat
issue_id: 23181
description: user-login
```

**输出**:
```
✓ 已创建分支: feat/23181-user-login
✓ 基于分支: main
```

## 相关技能

- [Git Branch Validate](../git-branch-validate/SKILL.md)
- [Requirement to Branch](../../../composites/workflow/requirement-to-branch/SKILL.md)
