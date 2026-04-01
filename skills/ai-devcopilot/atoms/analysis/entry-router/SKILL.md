---
name: entry-router
description: 顶层路由入口，判断用户输入应该触发哪个 Pipeline。
triggers:
  - feishu.cn/*
  - "*.feishu.cn/*"
  - 飞书文档
  - 飞书链接
  - 热修复
  - 紧急修复
  - 生产问题
  - 生产故障
  - 开始开发
  - /dev
  - /hotfix
  - 开发新功能
  - 新需求
  - 继续
  - 恢复流程
---

# Entry Router (入口路由)

这是所有用户输入的入口 skill，负责判断应该触发哪个 Pipeline。

## 核心职责

1. **统一入口**: 所有用户输入首先经过此 skill 进行路由判断
2. **Pipeline 匹配**: 根据输入内容匹配合适的 Pipeline trigger
3. **流程启动**: 触发正确的 Pipeline 开始执行
4. **流程恢复**: 检测是否存在未完成的流程，支持从断点恢复

## 路由规则

| 输入类型 | 识别规则 | 路由到 |
|----------|----------|--------|
| 流程恢复 | 包含 `继续`、`恢复流程` | 恢复未完成的流程 |
| 飞书链接 | 包含 `feishu.cn` | `dev-flow` Pipeline |
| 热修复请求 | 包含 `热修复`、`紧急修复`、`生产问题` | `hotfix-flow` Pipeline |
| 新需求描述 | 包含 `开发`、`新功能`、`新需求` | `dev-flow` Pipeline |
| 开发指令 | 包含 `/dev`、`开始开发` | `dev-flow` Pipeline |
| 热修复指令 | 包含 `/hotfix` | `hotfix-flow` Pipeline |
| 其他 | 默认 | `dev-flow` Pipeline |

## 执行流程

```
用户输入
    │
    ▼
┌─────────────────────────────────┐
│   检测流程状态文件                │
│   (.ai-devcopilot/state/)       │
└─────────────────────────────────┘
    │
    ├──► 存在未完成流程 ──► 提示恢复
    │         │
    │         ▼
    │   ┌─────────────────────────┐
    │   │ ask_followup_question   │
    │   │ - 继续上次流程          │
    │   │ - 开始新流程            │
    │   └─────────────────────────┘
    │
    └──► 无未完成流程
              │
              ▼
        ┌─────────────────────────────────┐
        │   检测输入类型                   │
        │   (URL / 关键词 / 指令)          │
        └─────────────────────────────────┘
              │
              ▼
        ┌─────────────────────────────────┐
        │   匹配 Pipeline Trigger          │
        └─────────────────────────────────┘
              │
              ▼
        ┌─────────────────────────────────┐
        │   触发对应 Pipeline              │
        │   (dev-flow / hotfix-flow)      │
        └─────────────────────────────────┘
```

## 输出格式

### 新流程启动

```
--- 🔀 入口路由判断 ---

✓ 输入类型: 飞书链接
✓ 匹配规则: feishu.cn/*
✓ 路由目标: dev-flow Pipeline

⏭️  下一步: 启动标准开发流程
```

### 流程恢复检测

```
--- 🔄 检测到未完成的流程 ---

流程类型: dev-flow
当前阶段: 阶段 2/4 (初始化)
暂停原因: 等待确认计划
需求标题: 用户登录功能
分支名称: feat/23181-user-login

📌 提示: 检测到您上次未完成的流程
```

> **执行要求**: 检测到未完成流程时，必须使用 `ask_followup_question` 工具询问用户：
> ```
> 问题: "检测到未完成的流程，请选择操作："
> 选项:
>   1. "继续上次流程 - 从上次暂停的位置继续执行" (trigger: "继续上次流程")
>   2. "开始新流程 - 放弃上次流程，开始新的开发任务" (trigger: "开始新流程")
> ```

## 使用示例

**示例 1：飞书链接**
```
用户输入: https://xxx.feishu.cn/wiki/wikcnABC123

路由结果:
  类型: 飞书链接
  匹配: feishu.cn/*
  路由: dev-flow Pipeline
```

**示例 2：热修复**
```
用户输入: 线上登录token过期，需要紧急修复

路由结果:
  类型: 热修复请求
  匹配: 紧急修复
  路由: hotfix-flow Pipeline
```

**示例 3：新需求**
```
用户输入: /dev 新增用户权限管理功能

路由结果:
  类型: 开发指令
  匹配: /dev
  路由: dev-flow Pipeline
```

## 与其他 Skill 的关系

```
entry-router (入口路由)
    │
    ├──► dev-flow Pipeline
    │         │
    │         └──► requirement-fetch (组合层)
    │                   │
    │                   └──► input-detect (原子层)
    │
    └──► hotfix-flow Pipeline
              │
              └──► requirement-fetch (组合层)
```

## 重要说明

1. **不要绕过此入口**: AI 编辑器应优先调用此 skill 进行路由判断
2. **不要直接调用原子层**: 飞书链接等输入不应直接调用 `feishu-doc-fetch`，应通过 Pipeline 流程
3. **保持路由一致性**: 新增 Pipeline 时需同步更新此 skill 的路由规则

## 相关文件

- [Dev Flow Pipeline](../../../pipelines/dev-flow/SKILL.md)
- [Hotfix Flow Pipeline](../../../pipelines/hotfix-flow/SKILL.md)
- [Input Detect](../input-detect/SKILL.md)
