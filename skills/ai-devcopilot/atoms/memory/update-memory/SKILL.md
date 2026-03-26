---
name: update-memory
description: 在任务完成后更新项目记忆，记录关键决策和变更。
triggers:
  - 更新项目记忆
  - 记录决策
  - 更新记忆
  - /update-memory
---

# Update Memory (更新项目记忆)

这个技能用于在功能开发完成后，更新项目记忆系统，记录关键决策、架构变更和经验教训。

## 输入标准化

- **输入**:
  - 功能描述
  - 关键决策
  - 遇到的问题和解决方案
- **自动获取**: 分支名、提交历史、计划文档

## 输出标准化

- **格式**: Memory 文件
- **存储位置**: `.ai-devcopilot/memory/`
- **类型**:
  - `project_*.md` - 项目决策和里程碑
  - `feedback_*.md` - 经验教训
  - `reference_*.md` - 外部资源引用

## 执行流程

### 步骤 1: 收集信息

```
═══════════════════════════════════════════
📝 更新项目记忆
═══════════════════════════════════════════

[1/2] 收集信息
      ✓ 读取计划文档
      ✓ 分析提交历史
      ✓ 回顾开发过程
      
📊 进度: 1/2
```

### 步骤 2: 生成记忆

```
[2/2] 更新记忆
      ✓ 创建 project_ai_log_system.md
      ✓ 更新 MEMORY.md 索引

📊 状态: 记忆已更新
```

## 记忆类型

### Project Memory
记录项目重要决策和里程碑：

```markdown
---
name: project_ai_log_system
type: project
---

AI 调用日志系统采用异步写入 + 分表策略

**Why:** 日志量大，同步写入影响主流程性能
**How to apply:** 新增日志表时遵循分表规则
```

### Feedback Memory
记录经验教训：

```markdown
---
name: feedback_cache_config
type: feedback
---

Caffeine 缓存的 expireAfterWrite 不要设置过短

**Why:** 曾设置 1 分钟过期导致缓存穿透
**How to apply:** 建议 expireAfterWrite >= 5 分钟
```

### Reference Memory
记录外部资源引用：

```markdown
---
name: reference_jenkins_api
type: reference
---

Jenkins REST API 文档: ${JENKINS_URL}/api/
```

## 使用示例

**输入**:
```
更新项目记忆：完成了 AI 调用日志系统
```

**输出**:
```
✓ 创建 project_ai_log_system.md
✓ 更新 MEMORY.md 索引

记忆内容:
- 决策: 异步写入 + 分表策略
- 模块: ai-service/call-log
```

## 相关技能

- [Finish Branch](../../../composites/delivery-workflow/finish-branch/SKILL.md)
- [Writing Plans](../../planning/writing-plans/SKILL.md)
