---
name: jenkins-trigger
description: 触发 Jenkins 构建部署。
triggers:
  - 触发部署
  - 开始部署
  - 发布到 dev
  - 部署到
  - /jenkins-trigger
---

# Jenkins Trigger (触发部署)

这个技能用于触发 Jenkins 构建部署，支持参数化构建和状态查询。

## ⚠️ 执行规则（AI 必须遵循）

1. **环境变量**：执行前必须 `source ~/.ai-devcopilot/env.sh`
2. **项目配置检查**：必须检查 `.ai-devcopilot/env.sh` 是否存在，不存在则引导用户创建
3. **配置验证**：必须验证 JENKINS_URL、JENKINS_USERNAME 是否配置
4. **分支确认**：必须确认要部署的分支名称
5. **状态输出**：必须输出构建触发状态和监控链接
6. **错误处理**：配置缺失时必须提示用户运行安装脚本

## 输入标准化

- **输入**:
  - 分支名称（默认当前分支）
  - 目标环境（dev/test/product）
- **配置**: JENKINS_URL, JENKINS_USERNAME, JENKINS_API_TOKEN

## 输出标准化

- **格式**: 构建任务已触发 + 构建状态 URL
- **状态**: 触发成功/失败

## 执行流程

### 步骤 1: 加载环境配置

```bash
# 加载全局配置
if [ -f ~/.ai-devcopilot/env.sh ]; then
  source ~/.ai-devcopilot/env.sh
  echo "✓ 已加载 ~/.ai-devcopilot/env.sh"
else
  echo "✗ 未找到配置文件: ~/.ai-devcopilot/env.sh"
  echo "  请先运行安装脚本: ./install.sh"
  exit 1
fi
```

### 步骤 1.5: 检查项目配置（JENKINS_JOB_DEV）

```
═══════════════════════════════════════════
📋 项目配置检查
═══════════════════════════════════════════

[1.5/3] 检查项目配置
```

**检查逻辑**（AI 执行）:

1. **检查项目配置文件是否存在**:
   ```bash
   if [ -f .ai-devcopilot/env.sh ]; then
     source .ai-devcopilot/env.sh
     echo "✓ 已加载项目配置: .ai-devcopilot/env.sh"
   else
     # 需要引导用户创建
   fi
   ```

2. **如果文件不存在，引导用户创建**:
   ```
   ⚠ 未找到项目配置文件: .ai-devcopilot/env.sh
   
   默认 Jenkins Job 名称:
     • Dev Job: <项目名>-dev
     • Test Job: <项目名>-test
   
   ❓ 确认使用默认值? [Y/n] 或输入新的 Dev Job 名称:
   ```

3. **用户输入处理**:
   - 直接回车或 `Y` → 使用默认值，创建配置文件
   - 输入 `N` → 分别询问 Dev/Test Job 名称
   - 直接输入名称 → 作为 Dev Job，再询问 Test Job

4. **创建配置文件**:
   ```bash
   mkdir -p .ai-devcopilot
   cat > .ai-devcopilot/env.sh << EOF
   # Jenkins Job 配置
   # 项目特定的 Job 名称配置，可提交到 Git
   
   export JENKINS_JOB_DEV="$JENKINS_JOB_DEV"
   export JENKINS_JOB_TEST="$JENKINS_JOB_TEST"
   EOF
   echo "✓ 已创建项目配置: .ai-devcopilot/env.sh"
   ```

5. **加载项目配置**:
   ```bash
   source .ai-devcopilot/env.sh
   ```

**示例交互**:
```
[1.5/3] 检查项目配置
      
      ⚠ 未找到项目配置: .ai-devcopilot/env.sh
      
      默认 Jenkins Job 名称:
        • Dev Job: ai-api-dev
        • Test Job: ai-api-test
      
      ❓ 确认使用默认值? [Y/n] 或输入新的 Dev Job 名称: my-custom-job
      
      请输入 Test Job 名称 [ai-api-test]: my-custom-test
      
      ✓ 已创建项目配置: .ai-devcopilot/env.sh
        JENKINS_JOB_DEV=my-custom-job
        JENKINS_JOB_TEST=my-custom-test

📊 阶段进度: 1.5/3
```

### 步骤 2: 验证配置

```
═══════════════════════════════════════════
🚀 Jenkins 构建触发
═══════════════════════════════════════════

[1/3] 验证配置
      ✓ Jenkins URL: ${JENKINS_URL}
      ✓ 用户: ${JENKINS_USERNAME}
      
📊 进度: 1/3
⏭️  下一步: 验证分支
```

### 步骤 3: 触发构建

```bash
curl -X POST "${JENKINS_URL}/job/${JOB_NAME}/buildWithParameters" \
  -u "${JENKINS_USERNAME}:${JENKINS_API_TOKEN}" \
  --data-urlencode "branch_name=${BRANCH_NAME}"
```

### 步骤 4: 返回结果

```
═══════════════════════════════════════════
🚀 Jenkins 构建触发
═══════════════════════════════════════════

[3/3] 触发构建
      ✓ 构建已触发
      
监控链接: ${JENKINS_URL}/job/${JENKINS_JOB_DEV}/lastBuild/

📊 状态: 触发成功
```

## 使用示例

**输入**:
```
部署分支 feat/23181-ai-classification 到集成环境
```

**输出**:
```
✓ 构建已触发
监控: ${JENKINS_URL}/job/${JENKINS_JOB_DEV}/lastBuild/
```

## 环境变量配置

```bash
# Jenkins 配置
export JENKINS_URL="http://your-jenkins-server:8080"
export JENKINS_USERNAME="your_username"
export JENKINS_API_TOKEN="your_api_token"

# 项目 Job 名称
export JENKINS_JOB_DEV="your-project-dev"
export JENKINS_JOB_TEST="your-project-test"
```

## 相关技能

- [Nacos Config](../nacos-config/SKILL.md)
- [Code Delivery](../../../composites/workflow/code-delivery/SKILL.md)
