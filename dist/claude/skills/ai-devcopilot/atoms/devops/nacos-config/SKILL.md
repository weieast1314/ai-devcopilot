---
name: nacos-config
description: 管理 Nacos 配置，包括查看、对比和更新配置项。
triggers:
  - Nacos 配置
  - 查看 Nacos
  - 更新配置
  - /nacos-config
---

# Nacos Config (Nacos 配置)

这个技能用于管理 Nacos 配置中心的配置项，支持查看、对比和更新配置。

## 输入标准化

- **输入**:
  - 操作类型（get/diff/update）
  - 配置 Data ID
  - Group（默认 DEFAULT_GROUP）
- **可选输入**: 配置内容（更新操作）

## 输出标准化

- **格式**: 配置内容或差异报告
- **内容**:
  - 配置项列表
  - 变更对比
  - 更新结果

## 执行流程

### 步骤 1: 加载环境配置

```bash
if [ -f ~/.ai-devcopilot/env.sh ]; then
  source ~/.ai-devcopilot/env.sh
  echo "✓ 已加载 ~/.ai-devcopilot/env.sh"
fi
```

### 步骤 2: 验证连接

```
═══════════════════════════════════════════
⚙️ Nacos 配置管理
═══════════════════════════════════════════

[1/3] 连接 Nacos
      ✓ Server: ${NACOS_SERVER_ADDR}
      ✓ Namespace: ${NACOS_NAMESPACE}
      
📊 进度: 1/3
⏭️  下一步: 执行操作
```

### 步骤 3: 执行操作

```
[2/3] 获取配置
      ✓ Data ID: your-app.yaml
      ✓ Group: DEFAULT_GROUP
      
📊 进度: 2/3
```

### 步骤 4: 返回结果

```
[3/3] 返回结果
      ✓ 配置内容已获取

📊 状态: 操作完成
```

## 环境变量配置

```bash
# Nacos 配置
export NACOS_SERVER_ADDR="your-nacos-server:8848"
export NACOS_NAMESPACE="dev"
export NACOS_GROUP="DEFAULT_GROUP"
```

## 使用示例

**输入**:
```
查看项目的配置
```

**输出**:
```
✓ Nacos Server: http://${NACOS_SERVER_ADDR}
✓ Data ID: your-app.yaml

配置内容:
app:
  feature:
    enabled: true
```

## 环境配置

```bash
# Nacos 配置
export NACOS_SERVER_ADDR="your-nacos-server:8848"
export NACOS_NAMESPACE="dev"
export NACOS_GROUP="DEFAULT_GROUP"
```

## 相关技能

- [Jenkins Trigger](../jenkins-trigger/SKILL.md)
- [Code Delivery](../../../composites/workflow/code-delivery/SKILL.md)
