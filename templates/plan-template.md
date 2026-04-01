# {需求标题}

> 创建日期: {YYYY-MM-DD}
> Issue: #{issue-id}
> 分支: {branch-name}
> 状态: 📋 待确认

## 背景

{需求背景描述，说明为什么需要这个功能}

## 涉及模块

- **模块A**: 描述涉及的具体模块
- **模块B**: 描述涉及的具体模块

## 修改点清单

### 数据库变更

- [ ] 新增表: `t_xxx`
- [ ] 修改表: `t_xxx` 添加字段

### 代码变更

- [ ] 新增实体: `entity/XxxDO.java`
- [ ] 新增 Mapper: `mapper/XxxMapper.java`
- [ ] 修改服务: `service/XxxService.java`
- [ ] 新增接口: `controller/XxxController.java`

### 配置变更

- [ ] Nacos 配置: `xxx.enabled=true`
- [ ] SQL 脚本: `sql/{date}_xxx.sql`

## 本地验证

```bash
# 1. 构建项目
mvn clean install -DskipTests

# 2. 运行指定测试
mvn test -Dtest=XxxTest

# 3. 启动服务验证
# ...
```

## 验收清单

- [ ] 功能验收点1
- [ ] 功能验收点2
- [ ] 性能要求
- [ ] 安全检查

## 执行进度

> 此部分在执行过程中更新

| 任务 | 状态 | 完成时间 |
|------|------|----------|
| 1.1 任务名称 | ⏳ 待执行 | - |

## 后续步骤

- [ ] 执行 SQL 脚本
- [ ] 配置 Nacos
- [ ] 创建 PR

## 备注

{其他需要说明的内容}
