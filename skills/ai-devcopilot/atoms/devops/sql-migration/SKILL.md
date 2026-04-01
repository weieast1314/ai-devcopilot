---
name: sql-migration
description: 管理 SQL 迁移脚本，生成表结构和初始数据。
triggers:
  - SQL 迁移
  - 生成 SQL
  - 创建数据库脚本
  - /sql-migration
---

# SQL Migration (SQL 迁移)

这个技能用于管理数据库迁移脚本，包括生成表结构、索引和初始数据。

## 输入标准化

- **输入**:
  - 迁移类型（create_table/add_column/create_index/data）
  - 表名或描述
  - 字段列表（可选）
- **可选输入**: 基于实体类生成

## 输出标准化

- **格式**: SQL 文件
- **存储位置**: `sql/{YYYY-MM-DD}_{description}.sql`
- **命名规范**: `{日期}_{简短描述}.sql`

## 执行流程

### 步骤 1: 确定迁移类型

```
迁移类型:
- create_table: 创建新表
- add_column: 添加字段
- create_index: 创建索引
- data: 初始数据
```

### 步骤 2: 生成 SQL 内容

```
--- 📊 SQL 迁移生成 ---

[1/2] 生成 SQL
      ✓ 表名: t_ai_call_log
      ✓ 字段: 8 个
      ✓ 索引: 3 个
      
📊 进度: 1/2
⏭️  下一步: 保存文件
```

### 步骤 3: 保存文件

```
[2/2] 保存文件
      ✓ 路径: sql/2026-03-13_ai_call_log.sql

📊 状态: 生成完成
```

## 表结构模板

```sql
-- =====================================================
-- SQL 迁移脚本
-- 需求: {需求标题}
-- Issue: #{issue-id}
-- 日期: {YYYY-MM-DD}
-- =====================================================

CREATE TABLE IF NOT EXISTS `t_xxx` (
    `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `last_modified_time` DATETIME DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='表说明';

-- 回滚脚本
/*
DROP TABLE IF EXISTS `t_xxx`;
*/
```

## 字段类型映射

| Java 类型 | MySQL 类型 | 说明 |
|-----------|------------|------|
| Long | BIGINT(20) | 主键、外键 |
| String | VARCHAR(n) | 短文本 |
| String | TEXT | 长文本 |
| Integer | INT(11) | 整数 |
| Boolean | TINYINT(1) | 布尔 |
| BigDecimal | DECIMAL(m,n) | 金额 |
| LocalDateTime | DATETIME | 时间 |

## 使用示例

**输入**:
```
创建 AI 调用日志表，包含：模型ID、输入内容、输出内容、耗时、状态
```

**输出**:
```
✓ 表名: t_ai_call_log
✓ 字段: 8 个
✓ 文件: sql/2026-03-13_ai_call_log.sql
```

## 相关技能

- [Writing Plans](../../../composites/workflow/writing-plans/SKILL.md)
- [Code Delivery](../../../composites/workflow/code-delivery/SKILL.md)
