---
name: code-verification
description: 代码验证。执行编译、测试和代码审查，生成验证报告。
triggers:
  - 代码验证
  - /code-verification
---

# Code Verification (代码验证)

这是一个组合 Skill，用于在提交前对代码进行完整验证，包括编译、测试和代码审查。

## 输入标准化

- **输入**: 当前分支（隐式）
- **验证类型**:
  - `compile` - 仅编译
  - `test` - 编译 + 测试
  - `full` - 编译 + 测试 + 审查

## 输出标准化

```yaml
compile_result: 编译结果
test_result: 测试结果
review_result: 审查结果
issues_found: 发现的问题列表
status: 通过 | 需修改
```

## 组合的原子 Skill

| 步骤 | Skill | 说明 |
|------|-------|------|
| 1 | `verification` | 编译与测试验证 |
| 2 | `code-review` | 代码审查 |

## 执行流程

```
┌─────────────────────────────────────────────────────────────┐
│               Code Verification Flow                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  当前分支                                                     │
│      │                                                       │
│      ▼                                                       │
│  [verification] ──► 编译 + 测试                               │
│      │                                                       │
│      ▼                                                       │
│  [code-review] ──► 代码审查                                   │
│      │                                                       │
│      ▼                                                       │
│  验证报告                                                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 阶段 1: 编译与测试

调用 [Verification](../../../atoms/verification/verification/SKILL.md) 执行编译和测试。

```
--- ✅ 代码验证 ---

项目类型: Maven (Spring Boot)

[1/2] 编译验证
      $ mvn compile -DskipTests -q
      ✓ ai-api 编译成功
      ✓ ai-service 编译成功

[2/2] 测试验证
      $ mvn test -q
      ✓ 运行 15 个测试
      ✓ 全部通过

📊 进度: 1/2 (50%)
⏭️  下一步: 代码审查
```

### 阶段 2: 代码审查

调用 [Code Review](../../../atoms/review/code-review/SKILL.md) 审查代码变更。

```
--- 🔍 代码审查 ---

审查范围: feat/23181-user-login
变更文件: 5 个

[1/3] 安全检查
      ✓ 无问题

[2/3] 代码规范
      ✓ 无问题

[3/3] 性能检查
      ⚠ 低: AiCallLogMapper.xml:23
            INSERT 语句未使用批量插入

📊 进度: 2/2 (100%)
✅ 当前阶段已完成！

--- 📋 代码验证 - 已完成 ---

编译结果: ✓ 通过
测试结果: ✓ 通过
审查结果: ⚠ 1 个建议优化

📌 说明:
   - 验证基本通过
   - 有 1 个低优先级建议
   - 可进入交付阶段
```

> **阶段引导**: 验证完成后必须使用 `ask_followup_question` 工具引导用户：
> ```
> 问题: "代码验证已完成，请选择下一步操作："
> 选项:
>   1. "继续 - 代码交付（提交、推送、部署）" (trigger: "继续")
>   2. "查看验证详情 - 查看编译、测试和审查的具体结果" (trigger: "查看详情")
>   3. "修复问题后重新验证 - 先修复发现的问题，再重新验证" (trigger: "修复问题")
>   4. "取消流程 - 放弃后续交付" (trigger: "取消")
> ```

## 使用示例

**场景: 完整验证**
```
输入: 当前分支 feat/23181-user-login

输出:
  compile_result: 通过
  test_result: 通过
  review_result: 1 个建议优化
  status: 通过
```

**场景: 验证失败**
```
输入: 当前分支 feat/23182-bug-fix

输出:
  compile_result: 通过
  test_result: 失败 (2 个测试未通过)
  review_result: 跳过
  status: 需修改
```

## 相关技能

- [Verification](../../../atoms/verification/verification/SKILL.md)
- [Code Review](../../../atoms/review/code-review/SKILL.md)
- [Code Delivery](../code-delivery/SKILL.md)
