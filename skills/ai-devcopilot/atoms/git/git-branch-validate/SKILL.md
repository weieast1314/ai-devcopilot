---
name: git-branch-validate
description: 验证 Git 分支命名是否符合团队规范。
triggers:
  - 验证分支
  - 检查分支命名
  - branch validate
  - /git-branch-validate
---

# Git Branch Validate (分支命名验证)

这个技能用于验证当前分支名称是否符合团队的命名规范，并提供改进建议。

## 输入标准化

- **输入**: 可选的分支名称（默认当前分支）
- **自动获取**: 当前分支名

## 输出标准化

- **格式**: 验证结果 + 改进建议
- **内容**:
  - 分支类型识别
  - 规范性检查结果
  - 改进建议（如不符合规范）

## 分支命名规范

| 前缀 | 用途 | 示例 |
|------|------|------|
| `feat/` | 新功能开发 | `feat/23181-ai-classification` |
| `fix/` | Bug修复 | `fix/23182-login-token` |
| `hotfix/` | 紧急修复 | `hotfix/23183-security-patch` |
| `refactor/` | 代码重构 | `refactor/23184-query-optimization` |
| `docs/` | 文档更新 | `docs/update-usage-guide` |
| `chore/` | 工具或脚本维护 | `chore/update-ci` |

## 执行流程

### 步骤 1: 获取当前分支

```bash
CURRENT_BRANCH=$(git branch --show-current)
```

### 步骤 2: 解析分支名称

```
提取前缀: feat/fix/hotfix/refactor/docs/chore...
提取描述部分
```

### 步骤 3: 验证规范

```
═══════════════════════════════════════════
🌿 分支命名验证
═══════════════════════════════════════════

当前分支: feat/23181-ai-classification

检查项:
✓ 前缀有效: feat
✓ 格式正确: feat/23181-ai-classification
✓ 描述清晰: 23181-ai-classification
✓ 字符合法: 仅使用小写字母、数字、连字符

📊 状态: 验证通过
```

## 验证规则

### 规则 1: 前缀检查
```
有效前缀: feature, fix, bugfix, hotfix, release, refactor, docs
```

### 规则 2: 格式检查
```
格式: {prefix}/{description}
或: {prefix}/{issue-id}-{description}
```

### 规则 3: 字符检查
```
允许: 小写字母 (a-z), 数字 (0-9), 连字符 (-)
禁止: 大写字母、中文、特殊字符
```

## 使用示例

**符合规范**:
```
当前分支: feat/23181-ai-classification
✓ 分支命名符合规范
```

**不符合规范**:
```
当前分支: UserLoginFeature
✗ 前缀无效
✗ 格式错误: 缺少斜杠分隔符
✗ 包含大写字母

修改建议: git branch -m UserLoginFeature feat/user-login
```

## 相关技能

- [Git Branch Create](../git-branch-create/SKILL.md)
- [Requirement to Branch](../../../composites/workflow/requirement-to-branch/SKILL.md)
- [Code Delivery](../../../composites/workflow/code-delivery/SKILL.md)
