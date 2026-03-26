---
name: code-delivery
description: 代码交付。执行提交、推送，并支持多种交付方式（Jenkins快速部署/合并部署/创建PR/跳过）。
triggers:
  - 代码交付
  - /code-delivery
---

# Code Delivery (代码交付)

这是一个组合 Skill，用于完成代码的提交、推送，并根据用户选择执行不同的交付方式。

## 输入标准化

- **输入**: 当前分支（隐式）
- **交付模式**:
  - `jenkins` - 快速模式：触发 Jenkins 部署当前分支到 dev 环境
  - `merge-deploy` - 常规模式：合并当前分支到 dev 并部署
  - `pr` - PR 模式：创建 Pull Request
  - `skip` - 跳过：仅提交推送，跳过部署

## 输出标准化

```yaml
commit_hash: 提交哈希
push_status: 推送状态
delivery_mode: 交付模式
delivery_result: 交付结果（Jenkins 链接 / PR 链接 / 跳过）
```

## 组合的原子 Skill

| 步骤 | Skill | 说明 |
|------|-------|------|
| 1 | Git 操作 | 提交和推送 |
| 2 | `jenkins-trigger` | Jenkins 部署（可选） |

## 执行流程

```
┌─────────────────────────────────────────────────────────────┐
│                Code Delivery Flow                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  当前分支                                                     │
│      │                                                       │
│      ▼                                                       │
│  [Git 提交推送] ──► 提交代码                                   │
│      │                                                       │
│      ├─► [jenkins] ──► [jenkins-trigger]                     │
│      │                                                       │
│      ├─► [merge-deploy] ──► [merge + jenkins-trigger]        │
│      │                                                       │
│      ├─► [pr] ──► [pr-create]                                │
│      │                                                       │
│      └─► [skip] ──► 完成                                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 阶段 1: Git 提交与推送

```
═══════════════════════════════════════════
📝 Git 操作
═══════════════════════════════════════════

[4/6] Git 提交推送
      
      📋 变更文件:
        M UserService.java
        M UserController.java
        A LoginRequest.java
      
      生成提交信息:
        feat(auth): 新增用户登录功能
      
      $ git add -A
      $ git commit -m "feat(auth): 新增用户登录功能"
      ✓ 提交完成: abc1234
      
      $ git push
      ✓ 推送完成

📊 进度: 4/6 (67%)
⏭️  下一步: 选择交付方式
```

### 阶段 2: 选择交付方式

```
═══════════════════════════════════════════
🚀 交付选择
═══════════════════════════════════════════

[5/6] 选择交付方式
```

> **阶段引导**: 必须使用 `ask_followup_question` 工具引导用户选择：
> ```
> 问题: "代码已推送完成，请选择下一步的交付方式："
> 选项:
>   1. "快速部署 - 直接部署当前分支到 dev 环境（适合快速验证）" (trigger: "快速部署")
>   2. "常规部署 - 先合并到 dev 分支，再部署（适合稳定发布）" (trigger: "常规部署")
>   3. "创建 Pull Request - 创建合并请求等待代码审核" (trigger: "创建PR")
>   4. "仅推送 - 已完成推送，无需其他操作" (trigger: "仅推送")
> ```

### 阶段 3: 执行交付（条件分支）

**分支 A: Jenkins 快速部署**

调用 [Jenkins Trigger](../../../atoms/devops/jenkins-trigger/SKILL.md) 触发部署。

```
═══════════════════════════════════════════
🚀 Jenkins 部署
═══════════════════════════════════════════

[6/6] Jenkins 部署
      
      ✓ 构建已触发
      监控链接: ${JENKINS_URL}/job/${JENKINS_JOB_DEV}/lastBuild/

📊 进度: 6/6 (100%)
✅ 当前阶段已完成！

═══════════════════════════════════════════
📋 交付摘要
═══════════════════════════════════════════

分支: feat/12345-user-login
提交: feat(auth): 新增用户登录功能
部署: Jenkins dev 环境已触发

✅ 代码交付完成！
```

**分支 B: 常规模式（合并到 dev 并部署）**

```
═══════════════════════════════════════════
🔀 合并并部署
═══════════════════════════════════════════

[6/6] 合并到 dev 并部署
      
      $ git checkout dev
      ✓ 已切换到 dev 分支
      
      $ git pull origin dev
      ✓ 已拉取最新代码
      
      $ git merge feat/12345-user-login --no-ff
      ✓ 已合并分支: feat/12345-user-login
      
      $ git push origin dev
      ✓ 已推送到远程 dev
      
      $ git checkout feat/12345-user-login
      ✓ 已切回原分支
      
      触发 Jenkins 部署...
      ✓ 构建已触发
      监控链接: ${JENKINS_URL}/job/${JENKINS_JOB_DEV}/lastBuild/

📊 进度: 6/6 (100%)
✅ 当前阶段已完成！

═══════════════════════════════════════════
📋 交付摘要
═══════════════════════════════════════════

源分支: feat/12345-user-login
目标分支: dev
合并状态: 已合并并推送
部署: Jenkins dev 环境已触发

✅ 代码交付完成！
```

**分支 C: 创建 PR**

```
═══════════════════════════════════════════
🔀 创建 PR
═══════════════════════════════════════════

[6/6] 创建 Pull Request
      
      ✓ PR 已创建
      链接: https://github.com/xxx/xxx/pull/123

📊 进度: 6/6 (100%)
✅ 当前阶段已完成！

═══════════════════════════════════════════
📋 交付摘要
═══════════════════════════════════════════

分支: feat/12345-user-login
提交: feat(auth): 新增用户登录功能
PR: #123 用户登录功能

✅ 代码交付完成！
```

**分支 D: 跳过部署**

```
═══════════════════════════════════════════
📋 交付摘要
═══════════════════════════════════════════

分支: feat/12345-user-login
提交: feat(auth): 新增用户登录功能
部署: 已跳过

✅ 代码推送完成！
```

## ⚠️ 执行规则

1. **环境变量**: 执行 Jenkins 部署前必须 `source ~/.ai-devcopilot/env.sh`
2. **项目配置检查**: 必须检查 `.ai-devcopilot/env.sh` 是否存在
3. **分步确认**: 每个阶段完成后使用 `ask_followup_question` 工具引导下一步
4. **智能检测**: 必须检测数据库/配置文件变更并提醒用户
5. **阶段引导**: 完成后必须引导用户选择下一步动作

> **阶段引导**: 交付完成后使用 `ask_followup_question` 工具：
> ```
> 问题: "代码交付已完成，请选择下一步操作："
> 选项:
>   1. "查看部署状态 - 查看 Jenkins 构建进度和日志" (trigger: "查看状态")
>   2. "更新项目记忆 - 记录本次开发的关键决策和变更" (trigger: "更新记忆")
>   3. "开始新需求 - 切换到新的开发任务" (trigger: "新需求")
>   4. "结束 - 完成当前会话" (trigger: "结束")
> ```

## 使用示例

**场景: Jenkins 部署**
```
输入: 
  当前分支: feat/12345-user-login
  交付模式: jenkins

输出:
  commit_hash: abc1234
  push_status: success
  delivery_mode: jenkins
  delivery_result: ${JENKINS_URL}/job/${JENKINS_JOB_DEV}/lastBuild/
```

## 相关技能

- [Jenkins Trigger](../../../atoms/devops/jenkins-trigger/SKILL.md)
- [Code Verification](../code-verification/SKILL.md)
- [Update Memory](../../../atoms/memory/update-memory/SKILL.md)
