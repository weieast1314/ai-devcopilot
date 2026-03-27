# AI DevCopilot 团队快速入门指南

> 目标：5 分钟完成安装，并掌握一套可直接上手的标准使用节奏。

---

## 适合谁看

如果你是下面这些场景，建议先看这份文档：
- 第一次安装 `AI DevCopilot`
- 刚加入团队，需要快速对齐使用方式
- 已经装过，但不知道该如何正确触发计划、执行、验证、交付

如果你需要更完整的说明，请继续查看 `README.md` 和 `TEAM-FAQ.md`。

---

## 前置条件

| 工具 | 版本要求 | 检查命令 |
|------|----------|----------|
| Git | 2.x+ | `git --version` |
| curl | 任意 | `curl --version` |
| PowerShell | 5.1+（Windows） | `$PSVersionTable.PSVersion` |
| Maven | 3.x+（如项目需要） | `mvn --version` |
| AI 编辑器 | Claude / CodeBuddy / OpenCode | - |

---

## 第一步：安装（1 分钟）

### 方式 A：快捷安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/weieast1314/ai-devcopilot/main/quick-install.sh | bash
cd ~/ai-devcopilot && ./install.sh
```

### 方式 B：手动安装（macOS / Linux）

```bash
git clone https://github.com/weieast1314/ai-devcopilot.git /tmp/ai-devcopilot
cd /tmp/ai-devcopilot
./install.sh -e codebuddy -y
```

### 方式 C：Windows（PowerShell）

```powershell
git clone https://github.com/weieast1314/ai-devcopilot.git $env:TEMP/ai-devcopilot
Set-Location $env:TEMP/ai-devcopilot
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor codebuddy -Yes
```

### 常用安装参数

| 场景 | Shell 安装器 | PowerShell 安装器 |
|------|--------------|-------------------|
| 指定编辑器 | `-e codebuddy` | `-Editor codebuddy` |
| 跳过交互 | `-y` | `-Yes` |
| 仅预览安装计划 | `--dry-run` | `-DryRun` |
| 仅校验安装目标 | `--validate-only` | `-ValidateOnly` |
| 安装全部编辑器 | `-e all` | `-Editor all` |

---

## 第二步：配置环境（2 分钟）

### 2.1 全局配置

编辑 `~/.ai-devcopilot/env.sh`：

```bash
# Jenkins 配置（按需）
export JENKINS_URL="http://your-jenkins-server:8080"
export JENKINS_USERNAME="your-name"
export JENKINS_API_TOKEN="your-token"

# Nacos 配置（按需）
export NACOS_SERVER_ADDR="your-nacos-server:8848"
export NACOS_NAMESPACE="dev"
export NACOS_GROUP="DEFAULT_GROUP"

# 飞书 MCP（可选）
export LARK_APP_ID="cli_xxx"
export LARK_APP_SECRET="xxx"
```

### 2.2 项目配置

在项目根目录创建 `.ai-devcopilot/env.sh`：

```bash
export JENKINS_JOB_DEV="your-project-dev"
export JENKINS_JOB_TEST="your-project-test"
```

说明：
- `~/.ai-devcopilot/env.sh` 是全局共享配置，不提交 Git
- `.ai-devcopilot/env.sh` 是项目配置，可随项目一起维护

---

## 第三步：重启编辑器（30 秒）

安装后请完全关闭并重新打开 AI 编辑器，确保新技能与配置被加载。

---

## 第四步：验证安装（30 秒）

在编辑器中任选一种说法：

```text
开始开发
```

```text
/dev
```

```text
热修复
```

如果 AI 开始进入标准开发流程或热修复流程，说明安装成功。

> 说明：旧文档中你可能见过 `/dev-flow`；当前统一推荐使用 `/dev` 或自然语言。

---

## 第五步：第一次正确使用（1 分钟）

### 场景 1：开始一个标准需求

```text
帮我实现这个需求：https://feishu.cn/wiki/xxx
```

或：

```text
#23181 需要新增用户登录功能
```

### 场景 2：先让 AI 出计划，不直接改代码

```text
进入计划模式
```

AI 应先输出计划，并等待你回复：

```text
确认计划，开始执行
```

### 场景 3：代码完成后做验证与交付

```text
验证代码
```

```text
代码交付
```

---

## 推荐协作节奏

团队内统一建议按下面节奏使用：

1. 先让 AI 进入计划模式，只输出计划，不直接改代码。
2. 阅读计划中的任务清单、执行边界、风险点和待确认事项。
3. 回复 `确认计划，开始执行` 后再进入实现。
4. 要求 AI 每完成一项就同步汇报：
   - 做了什么
   - 改了哪些文件
   - 验证结果是什么
   - 下一步做什么
5. 如果 AI 发现偏差或新增影响范围，先更新计划，再继续执行。

---

## 常用输入速查

| 目标 | 推荐输入 | 说明 |
|------|----------|------|
| 启动标准开发 | `开始开发` / `/dev` | 进入标准开发流 |
| 启动热修复 | `热修复` / `/hotfix` | 进入热修复流 |
| 生成计划 | `进入计划模式` | 先看方案再动代码 |
| 开始执行 | `确认计划，开始执行` | 按已确认计划改代码 |
| 验证代码 | `验证代码` | 先跑验证再决定是否交付 |
| 代码交付 | `代码交付` | 提交、推送、部署/PR |
| 代码审查 | `代码审查` | 查看规范性与风险 |

---

## 团队协作规范

### 分支命名

```text
feat/{issue-id}-{description}
fix/{issue-id}-{description}
hotfix/{issue-id}-{description}
refactor/{issue-id}-{description}
```

示例：
- `feat/23181-ai-classification`
- `fix/23182-null-pointer`
- `hotfix/23199-login-timeout`
- `refactor/23210-cleanup-auth-flow`

### 提交信息

```text
feat(scope): 新增功能描述
fix(scope): 修复问题描述
refactor(scope): 重构描述
chore(scope): 工具或脚本调整
```

示例：`feat(ai): 新增AI模型调用日志系统`

---

## 维护者自检命令

如果你在维护本仓库本身，可额外执行：

```bash
bash scripts/build-dist.sh
bash scripts/validate-dist.sh
bash scripts/check-registry.sh
bash scripts/check-install-targets.sh
bash scripts/smoke-dev-flow.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor all -ValidateOnly -Yes
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor all -DryRun -Yes
```

---

## 常见问题

### Q1: 安装后 Skills 没有生效？

- 完全退出并重启编辑器
- 检查 `${EDITOR_HOME}/skills/ai-devcopilot/` 是否存在
- 如果是 Claude，再检查 `${EDITOR_HOME}/skills/` 下的一级入口是否已创建

### Q2: 为什么 AI 停在计划阶段不继续？

这是预期行为。计划生成后，你需要明确回复：

```text
确认计划，开始执行
```

### Q3: 如何从中断处继续？

直接告诉 AI 当前状态，例如：

```text
继续刚才的任务：当前分支 feat/23181-login，计划已确认，继续执行 Service 和验证
```

更多问题请查看 `TEAM-FAQ.md`。

---

## 获取帮助

- 查看完整说明：`README.md`
- 查看排障手册：`TEAM-FAQ.md`
- 查看完整示例：`examples/full-workflow-example.md`
- 查看命令速查：`examples/quick-reference.md`

---

**最后更新**: 2026-03-27
