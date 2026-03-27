# AI DevCopilot 团队常见问题 FAQ

---

## 安装与配置

### Q1: 安装脚本运行失败怎么办？

优先按下面顺序排查：

1. **确认脚本可执行**
   ```bash
   chmod +x install.sh quick-install.sh
   ```

2. **先做只读校验**
   ```bash
   ./install.sh -e claude --validate-only -y
   ```
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor claude -ValidateOnly -Yes
   ```

3. **确认目标编辑器已安装并至少运行过一次**
   ```bash
   ls ~/.claude/
   ls ~/.codebuddy/
   ls ~/.opencode/
   ```

4. **确认网络正常**
   - 重新执行安装
   - 如公司网络有限制，先切换网络或配置代理后再试

---

### Q2: Skills 安装后未生效怎么办？

建议按下面顺序检查：

1. 完全关闭并重启 AI 编辑器
2. 检查 `${EDITOR_HOME}/skills/ai-devcopilot/` 是否存在
3. 如果是 Claude，再检查 `${EDITOR_HOME}/skills/` 下的一级入口是否已创建
4. 重新执行安装脚本

常用检查命令：

```bash
ls ~/.claude/skills/ai-devcopilot/
ls ~/.codebuddy/skills/ai-devcopilot/
ls ~/.opencode/skills/ai-devcopilot/
```

```bash
ls -la ~/.claude/skills/
```

说明：Claude 只扫描 `${EDITOR_HOME}/skills/` 的一级子目录，所以安装脚本会自动创建一级入口。

---

### Q3: Windows 下安装成功了，但 Claude 还是没加载怎么办？

请依次检查：

1. 重新执行 PowerShell 安装器
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor claude -Yes
   ```

2. 完全关闭并重启 Claude
3. 检查 `~/.claude/skills/ai-devcopilot/` 是否存在
4. 如果目录链接创建失败，尝试使用管理员权限打开 PowerShell 后重试

---

### Q4: 全局配置和项目配置分别放什么？

建议这样分层：

- `~/.ai-devcopilot/env.sh`
  - Jenkins URL / 用户名 / Token
  - Nacos 地址
  - 飞书 App ID / Secret
  - 所有项目共享的敏感配置

- `.ai-devcopilot/env.sh`
  - Jenkins Job 名称
  - 与当前仓库绑定的项目参数
  - 可随项目提交的非敏感配置

---

### Q5: 如何配置 Jenkins API Token？

步骤如下：

1. 登录 Jenkins
2. 点击右上角头像 → 设置
3. 打开 **API Token**
4. 新建 Token
5. 填到 `~/.ai-devcopilot/env.sh` 的 `JENKINS_API_TOKEN`

---

### Q6: 如何配置飞书文档读取能力？

你需要同时准备两部分：

1. 在飞书开放平台获取 `App ID` 与 `App Secret`
2. 把它们配置到：
   - `~/.ai-devcopilot/env.sh`
   - 对应编辑器的 `mcp.json`

如果当前环境没有飞书 MCP，通常仍可退回到网页抓取或手动粘贴需求正文。

---

## 使用问题

### Q7: 输入命令后 AI 没有响应怎么办？

先检查三件事：

1. 你用的是不是当前推荐输入，例如：
   - `开始开发` / `/dev`
   - `进入计划模式`
   - `验证代码`
   - `代码交付`
2. Skills 是否已经正确安装并被编辑器加载
3. 是否刚刚修改过安装内容但没有重启编辑器

> 说明：旧文档里可能会出现 `/dev-flow`、`完成分支`、`/finish-branch`。当前统一推荐使用 `/dev` 与 `代码交付`。

---

### Q8: 为什么 AI 停在计划阶段不继续改代码？

这是标准流程要求，不是异常。

计划生成后，AI 应暂停，等待你明确回复：

```text
确认计划，开始执行
```

如果是热修复，则应回复：

```text
确认修复，开始执行
```

---

### Q9: 分支创建失败怎么办？

常见原因：

1. **当前工作区有未提交改动**
   ```bash
   git status
   git stash
   ```

2. **目标分支已存在**
   ```bash
   git branch -a
   ```

3. **远程仓库未配置或鉴权异常**
   ```bash
   git remote -v
   ```

4. **当前不在正确基分支上**
   - 标准开发通常从 `main/dev/uat` 等团队约定分支开始
   - 热修复通常从更接近生产的稳定分支开始

---

### Q10: Jenkins 部署触发了，但构建失败怎么办？

建议依次确认：

1. `.ai-devcopilot/env.sh` 中的 `JENKINS_JOB_DEV` 是否正确
2. 当前分支是否已成功推送
3. Jenkins 凭证是否有效
4. 项目本身是否已通过本地构建与测试

手动排查时可先输出关键变量：

```bash
source ~/.ai-devcopilot/env.sh
echo $JENKINS_URL
echo $JENKINS_USERNAME
echo $JENKINS_JOB_DEV
```

---

### Q11: 计划模式生成得不够准确怎么办？

推荐做法：

1. 补充更明确的需求上下文
2. 指出关键模块、表名、接口名
3. 让 AI 重新生成计划，而不是直接跳进实现
4. 在计划里明确“本次包含 / 本次不包含”

---

### Q12: 会话中断后怎么继续？

直接把当前状态告诉 AI，例如：

```text
继续刚才的任务：当前分支 feat/23181-login，计划已确认，已完成 Controller，继续执行 Service、验证和交付。
```

至少补充三类信息：
- 当前分支
- 计划是否已确认
- 已完成 / 未完成项

---

## 多项目 / 多编辑器 / 版本维护

### Q13: 多个项目如何共用配置？

推荐做法：
- 全局认证放 `~/.ai-devcopilot/env.sh`
- 每个项目单独维护 `.ai-devcopilot/env.sh`

这样多个项目可以共享认证，但各自维护自己的 Jenkins Job 等项目参数。

---

### Q14: 切换编辑器需要重新配置吗？

通常不需要重新填写全局配置。

你只需要重新执行安装脚本，把技能安装到新的编辑器目录：

```bash
./install.sh -e claude -y
./install.sh -e codebuddy -y
./install.sh -e opencode -y
```

PowerShell 版本：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor claude -Yes
```

---

### Q15: 如何更新 AI DevCopilot？

```bash
cd /path/to/ai-devcopilot
git pull
./install.sh -e claude -y
```

如果你同时维护多个编辑器，建议分别重装对应编辑器。

仓库维护者还可以追加执行：

```bash
bash scripts/build-dist.sh
bash scripts/validate-dist.sh
bash scripts/check-registry.sh
bash scripts/check-install-targets.sh
bash scripts/smoke-dev-flow.sh
```

---

### Q16: 如何回滚到旧版本？

如果新版本与当前环境不兼容，可回到仓库中的历史提交或 tag，再重新安装：

```bash
cd /path/to/ai-devcopilot
git checkout <tag-or-commit>
./install.sh -e claude -y
```

Windows：

```powershell
git checkout <tag-or-commit>
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor claude -Yes
```

---

## 高级定制

### Q17: 如何调整分支命名规范？

可修改 `${EDITOR_HOME}/skills/ai-devcopilot/atoms/git/git-branch-create/SKILL.md` 中的分支命名规则。

常见 `EDITOR_HOME`：
- `~/.claude`
- `~/.codebuddy`
- `~/.opencode`

---

### Q18: 如何调整验证命令？

可修改 `${EDITOR_HOME}/skills/ai-devcopilot/atoms/verification/verification/SKILL.md`，加入符合你项目的构建或测试命令。

---

## 联系支持

如遇到以上未覆盖的问题，请联系：
- AI DevCopilot 负责人：[填写]
- 内部群组：[填写]
- 反馈渠道：[填写]

---

**最后更新**: 2026-03-27
