# 贡献指南

感谢您对 AI DevCopilot 项目的关注！我们欢迎任何形式的贡献，包括但不限于代码、文档、问题报告和功能建议。

**🌐 中文** | **[English](CONTRIBUTING_EN.md)**

## 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
  - [报告问题](#报告问题)
  - [提交代码](#提交代码)
  - [改进文档](#改进文档)
- [开发环境设置](#开发环境设置)
- [代码规范](#代码规范)
- [提交信息规范](#提交信息规范)
- [分支管理](#分支管理)
- [Pull Request 流程](#pull-request-流程)
- [版本发布](#版本发布)

## 行为准则

本项目采用 [Contributor Covenant 行为准则](CODE_OF_CONDUCT.md)。参与本项目即表示您同意遵守该准则。

## 如何贡献

### 报告问题

如果您发现了 bug 或有功能建议，请通过以下方式提交：

1. **搜索现有 Issues**：确保您的问题尚未被报告
2. **创建新 Issue**：使用提供的 Issue 模板
3. **提供详细信息**：
   - 问题描述
   - 复现步骤
   - 预期行为 vs 实际行为
   - 环境信息（操作系统、编辑器版本等）
   - 相关日志或截图

### 提交代码

1. **Fork 项目**：点击项目右上角的 "Fork" 按钮
2. **克隆您的 Fork**：
   ```bash
   git clone https://github.com/your-username/ai-devcopilot.git
   cd ai-devcopilot
   ```
3. **创建特性分支**：
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **进行修改并测试**
5. **提交更改**：
   ```bash
   git add .
   git commit -m "feat: 添加新功能描述"
   ```
6. **推送到您的 Fork**：
   ```bash
   git push origin feature/your-feature-name
   ```
7. **创建 Pull Request**

### 改进文档

文档贡献同样重要！您可以通过以下方式改进文档：

- 修正拼写错误
- 添加使用示例
- 翻译文档
- 改进说明清晰度

## 开发环境设置

### 前置条件

| 工具 | 版本要求 | 安装说明 |
|------|----------|----------|
| Git | 2.x+ | [安装 Git](https://git-scm.com/book/zh/v2/%E8%B5%B7%E6%AD%A5-%E5%AE%89%E8%A3%85-Git) |
| Bash | 4.x+ | macOS/Linux 自带，用于 Shell 校验脚本 |
| PowerShell | 5.1+ | Windows 自带，用于 `install.ps1` |
| AI 编辑器 | Claude/CodeBuddy/OpenCode | 安装对应编辑器 |

### 本地开发

```bash
# 克隆项目
git clone https://github.com/your-username/ai-devcopilot.git
cd ai-devcopilot

# 安装到本地编辑器（开发模式）
./install.sh -e claude

# 生成并校验多编辑器产物
bash scripts/build-dist.sh
bash scripts/validate-dist.sh
bash scripts/check-registry.sh
bash scripts/check-install-targets.sh
bash scripts/smoke-dev-flow.sh

# 测试修改
# 编辑 skills 目录下的文件
# 重启编辑器测试
```

```powershell
# Windows 安装与校验
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor all -ValidateOnly -Yes
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor all -DryRun -Yes
```

## 代码规范

### Shell 脚本规范

1. **使用 ShellCheck**：确保脚本通过 ShellCheck 检查
   ```bash
   shellcheck install.sh
   ```

2. **遵循 Google Shell 风格指南**：
   - 使用 2 空格缩进
   - 函数使用小写字母和下划线
   - 变量使用大写字母和下划线
   - 添加注释说明复杂逻辑

3. **错误处理**：
   ```bash
   set -e  # 遇到错误立即退出
   set -u  # 使用未定义变量时报错
   set -o pipefail  # 管道命令失败时报错
   ```

### Skills 文档规范

1. **文件结构**：
   ```
   skills/ai-devcopilot/
   ├── atoms/
   │   └── category/
   │       └── skill-name/
   │           └── SKILL.md
   ├── composites/
   │   └── workflow-name/
   │       └── skill-name/
   │           └── SKILL.md
   └── pipelines/
       └── pipeline-name/
           └── SKILL.md
   ```

2. **SKILL.md 格式**：
   ```markdown
   # 技能名称
   
   ## 功能描述
   简要描述技能的功能
   
   ## 触发条件
   列出触发该技能的条件或命令
   
   ## 执行步骤
   1. 第一步
   2. 第二步
   ...
   
   ## 配置要求
   列出需要的配置项
   
   ## 示例
   提供使用示例
   ```

## 提交信息规范

我们遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/) 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 类型 (type)

- `feat`: 新功能
- `fix`: 修复问题
- `docs`: 文档更新
- `style`: 代码格式调整（不影响逻辑）
- `refactor`: 重构（既不是修复也不是新功能）
- `perf`: 性能优化
- `test`: 添加或修改测试
- `chore`: 构建过程或辅助工具的变动
- `ci`: CI 配置变更
- `revert`: 回滚提交

### 范围 (scope)

可选，表示影响范围：

- `install`: 安装脚本
- `skills`: 技能相关
- `config`: 配置相关
- `docs`: 文档相关

### 示例

```
feat(skills): 新增代码审查技能

- 添加 code-review 技能
- 支持自动代码风格检查
- 集成安全漏洞扫描

Closes #123
```

```
fix(install): 修复 macOS 安装路径问题

修复在 macOS 上使用 zsh 时路径解析错误的问题

Fixes #456
```

## 分支管理

### 分支命名规范

```
feature/{issue-id}-{description}   # 新功能
fix/{issue-id}-{description}       # Bug 修复
hotfix/{issue-id}-{description}    # 紧急修复
docs/{description}                 # 文档更新
refactor/{description}             # 重构
test/{description}                 # 测试相关
```

示例：
- `feature/123-add-docker-support`
- `fix/456-install-path-error`
- `docs/update-readme`

### 分支策略

- `main`: 稳定版本分支
- `develop`: 开发分支
- `feature/*`: 功能分支
- `fix/*`: 修复分支
- `hotfix/*`: 紧急修复分支

## Pull Request 流程

### PR 标题

使用与提交信息相同的格式：

```
feat(skills): 新增代码审查技能
```

### PR 描述

使用提供的 PR 模板，包含：

1. **变更描述**：简要说明本次变更
2. **变更类型**：新功能/修复/文档/重构等
3. **相关 Issue**：关联的 Issue 编号
4. **测试情况**：说明如何测试
5. **截图**：如有 UI 变更，提供截图
6. **检查清单**：确保完成所有检查项

### 代码审查

1. **审查者**：至少需要一名维护者审查
2. **自动化检查**：确保所有 CI 检查通过
3. **修改反馈**：根据审查意见进行修改
4. **合并**：审查通过后由维护者合并

## 版本发布

我们使用 [语义化版本](https://semver.org/lang/zh-CN/)：

- **主版本号 (MAJOR)**：不兼容的 API 变更
- **次版本号 (MINOR)**：向下兼容的功能性新增
- **修订号 (PATCH)**：向下兼容的问题修正

### 发布流程

1. 更新 `CHANGELOG.md`
2. 更新版本号（在 README.md 中）
3. 创建 Git 标签：
   ```bash
   git tag -a v1.4.0 -m "Release version 1.4.0"
   git push origin v1.4.0
   ```
4. 在 GitHub 上创建 Release

## 获取帮助

如果您在贡献过程中遇到问题，可以通过以下方式获取帮助：

- **Issues**：提交问题或建议
- **讨论区**：参与项目讨论
- **联系维护者**：直接联系项目维护者

## 致谢

感谢所有为 AI DevCopilot 项目做出贡献的人！

---

**最后更新**: 2026-03-20