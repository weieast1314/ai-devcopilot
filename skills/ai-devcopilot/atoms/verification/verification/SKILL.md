---
name: verification
description: 运行构建和测试验证代码变更，完成后必须询问用户下一步动作。
triggers:
  - 验证代码
  - 编译验证
  - 编译检查
  - /verification
---

# Verification (验证代码)

这个技能用于在提交前验证代码的正确性，确保无语法错误且通过基本回归。

## 输入标准化

- **输入**: 项目路径、验证类型
- **验证类型**:
  - `compile` - 仅编译
  - `test` - 运行测试
  - `full` - 完整验证（编译 + 测试）

## 输出标准化

- **格式**: 验证报告
- **内容**: 验证结果（通过/失败）、错误详情、建议修复

## 执行流程

### 步骤 1: 识别项目类型

```
项目类型检测:
- pom.xml → Maven
- build.gradle → Gradle
- package.json → npm/yarn/pnpm
- go.mod → Go
- requirements.txt → Python
```

### 步骤 2: 执行验证

```
═══════════════════════════════════════════
✅ 代码验证
═══════════════════════════════════════════

项目类型: Maven (Spring Boot)

[1/2] 编译验证
      $ mvn compile -DskipTests -q
      ✓ ai-api 编译成功
      ✓ ai-service 编译成功
      
📊 进度: 1/2
⏭️  下一步: 测试验证
```

### 步骤 3: 测试验证（可选）

```
[2/2] 测试验证
      ❓ 是否运行单元测试? [y/N]: y
      $ mvn test -q
      ✓ 运行 15 个测试
      ✓ 全部通过
      
📊 进度: 2/2
✅ 验证通过

❓ 验证已完成，是否继续下一步（如代码审查或提交）？[Y/n]:
```

## 验证命令

### Java/Maven

```bash
# 编译
mvn compile -q

# 完整构建
mvn clean install -DskipTests

# 测试
mvn test
```

### Node.js/npm

```bash
# 编译
npm run build

# 测试
npm test
```

### Go

```bash
# 编译
go build ./...

# 测试
go test ./...
```

## 使用示例

**输入**:
```
验证类型: full
```

**输出**:
```
✓ 编译通过
✓ 测试通过
总结: 验证通过 ✓
```

## 相关技能

- [Executing Plans](../../planning/executing-plans/SKILL.md)
- [Code Review](../../review/code-review/SKILL.md)
- [Finish Branch](../../../composites/delivery-workflow/finish-branch/SKILL.md)
