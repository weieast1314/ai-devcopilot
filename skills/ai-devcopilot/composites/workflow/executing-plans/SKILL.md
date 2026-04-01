---
name: executing-plans
description: 执行计划。按照计划文档执行代码修改，逐项汇报进度。
triggers:
  - 执行计划
  - /executing-plans
---

# Executing Plans (执行计划)

这是一个组合 Skill，用于按照计划文档执行代码修改。

> **注意**: 本 Composite 是对原子 Skill `executing-plans` 的封装，用于 Pipeline 层编排。

## 输入标准化

- **输入**: 计划文档（由编辑器自动管理）
- **前置条件**: 用户已明确确认当前计划可以开始执行

## 输出标准化

```yaml
completed_tasks: 已完成任务列表
pending_tasks: 待完成任务列表
modified_files: 修改的文件列表
verification_result: 每项任务的验证结果
status: 执行状态
```

## 组合的原子 Skill

| 步骤 | Skill | 说明 |
|------|-------|------|
| 1 | `executing-plans` (atom) | 按计划执行代码修改 |

## 执行流程

```
┌─────────────────────────────────────────────────────────────┐
│                Executing Plans Flow                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  计划文档                                                     │
│      │                                                       │
│      ▼                                                       │
│  [executing-plans atom] ──► 逐任务执行                         │
│      │                                                       │
│      ▼                                                       │
│  完成的任务列表                                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 执行阶段

调用 [Executing Plans Atom](../../../atoms/planning/executing-plans/SKILL.md) 执行计划。

```
--- 📋 计划执行 ---

任务总数: 5
已完成: 0
待执行: 5

执行边界:
- 仅执行当前计划中的任务
- 未经确认不新增计划外修改
- 如发现偏差，先更新计划再继续

📊 进度: 0%
⏭️  下一步: 开始执行第 1 个任务
```

### 逐项汇报

```
[1/5] 创建 Entity/POJO
      ✓ 已完成
      ✓ 修改文件: AiClassificationEntity.java
      ✓ 验证结果: 编译通过
      ⏭️ 下一步: 创建 Mapper/Repository

[2/5] 创建 Mapper/Repository
      ✓ 已完成
      ✓ 修改文件: AiClassificationMapper.java
      ✓ 验证结果: 编译通过
      ⏭️ 下一步: 创建 Service
...

[5/5] 创建 Controller
      ✓ 已完成
      ✓ 修改文件: AiClassificationController.java
      ✓ 验证结果: 接口检查通过

📊 进度: 5/5 (100%)
✅ 当前阶段已完成！

--- 📋 计划执行 - 已完成 ---

修改文件:
  - AiClassificationEntity.java
  - AiClassificationMapper.java
  - AiClassificationService.java
  - AiClassificationController.java

📌 说明:
   - 所有计划内任务已完成
   - 可进入验证与交付阶段
```

> **阶段引导**: 所有任务执行完成后必须使用 `ask_followup_question` 工具引导用户：
> ```
> 问题: "计划中的所有任务已执行完成，请选择下一步操作："
> 选项:
>   1. "继续 - 验证与交付（编译、测试、代码审查）" (trigger: "继续")
>   2. "查看修改详情 - 查看修改的文件列表和具体改动" (trigger: "查看修改")
>   3. "继续开发其他功能 - 在当前分支继续添加新功能" (trigger: "继续开发")
>   4. "取消流程 - 放弃后续验证和交付" (trigger: "取消")
> ```

## 执行规则

1. **按顺序执行**: 严格按照计划中的任务顺序。
2. **只执行计划内事项**: 未经确认不得加入计划外修改。
3. **状态同步**: 每完成一个任务，立即更新计划文档中的状态。
4. **逐项汇报**: 每完成一个任务，必须汇报完成情况、修改文件、验证结果和下一步。
5. **偏差先改计划**: 遇到范围变化或方案偏差时，先更新计划再继续执行。
6. **错误处理**: 遇到问题暂停，并明确说明阻塞原因与处理建议。
7. **完成询问下一步**: 所有任务执行完成后，必须询问用户是否进入下一阶段。

## 相关技能

- [Executing Plans Atom](../../../atoms/planning/executing-plans/SKILL.md)
- [Writing Plans](../../../atoms/planning/writing-plans/SKILL.md)
- [Code Verification](../code-verification/SKILL.md)
