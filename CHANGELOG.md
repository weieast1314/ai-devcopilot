# 更新日志

本文档记录 AI DevCopilot 项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

**🌐 中文** | **[English](CHANGELOG_EN.md)**

## [未发布]

### 新增
- 完善开源项目文档结构
- 添加 MIT 开源许可证
- 添加贡献指南 (CONTRIBUTING.md)
- 添加行为准则 (CODE_OF_CONDUCT.md)
- 添加 GitHub Issue 和 PR 模板
- 完善 README.md，添加徽章和目录

## [1.3.0] - 2026-03-18

### 新增
- 完整的四阶段工作流：需求获取 → 方案设计 → 代码实现 → 一键交付
- 飞书文档集成，自动读取需求并创建分支
- 智能计划模式，自动生成实施方案
- Jenkins 自动部署集成
- 多编辑器支持（Claude、CodeBuddy、OpenCode）
- 双层配置架构，确保敏感信息安全
- 团队协作规范（分支命名、提交信息）
- 完整的安装脚本和配置模板

### 技能体系
- `entry-router`: 统一入口路由
- `requirement-fetch`: 多来源需求获取
- `requirement-to-branch`: 需求转分支
- `writing-plans`: 计划模式
- `executing-plans`: 计划执行
- `code-verification`: 代码验证
- `code-delivery`: 代码交付
- `jenkins-trigger`: Jenkins 部署触发
- `nacos-config`: Nacos 配置管理
- `code-review`: 代码审查

### 文档
- 详细的使用教程
- 团队快速入门指南
- 团队常见问题 FAQ
- 使用示例和快速参考

### 工具
- 安装脚本 (`install.sh`)
- 演示脚本 (`demo.sh`)
- 配置模板 (`env.sh.template`)
- 计划和 PR 模板

## [1.0.0] - 2026-03-13

### 新增
- 项目初始化
- 基础工作流框架
- 核心技能开发

---

## 版本说明

- **主版本号 (MAJOR)**: 不兼容的 API 变更
- **次版本号 (MINOR)**: 向下兼容的功能性新增
- **修订号 (PATCH)**: 向下兼容的问题修正

## 如何更新

```bash
# 拉取最新代码
cd /path/to/ai-devcopilot
git pull

# 重新安装
./install.sh -e claude -y

# 重启编辑器
```

---

**最后更新**: 2026-03-27