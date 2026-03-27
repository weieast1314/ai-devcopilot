---
name: feishu-doc-fetch
description: 从飞书文档读取完整原始内容。
triggers:
  - 飞书文档链接
  - feishu.cn/wiki
  - feishu.cn/docx
  - /feishu-doc-fetch
---

# Feishu Doc Fetch (读取飞书文档)

这个技能用于从飞书 Wiki/文档中读取完整的原始内容，返回 Markdown 格式。

## 输入标准化

- **输入**: 飞书文档 URL
- **格式**: `https://xxx.feishu.cn/wiki/xxx` 或 `https://xxx.feishu.cn/docx/xxx`

## 输出标准化

- **格式**: 完整的文档原始内容（Markdown）
- **元数据**: 文档标题、文档类型

## 执行流程

### 步骤 1: 解析 URL

从飞书文档 URL 中提取 `doc_token`。

```
URL 格式:
- Wiki: https://xxx.feishu.cn/wiki/wikcnABC123
- Docx: https://xxx.feishu.cn/docx/doxcnABC123

提取规则:
- Wiki: 提取 /wiki/ 后的 token
- Docx: 提取 /docx/ 后的 token
```

### 步骤 2: 获取文档内容

根据 URL 类型调用对应的 MCP 工具：

```
Wiki 文档 (/wiki/):
1. 使用 lark_getWikiNode 获取节点信息
2. 使用 lark_getDocument 获取内容

普通文档 (/docx/):
1. 直接使用 lark_getDocument 获取内容
```

### 步骤 3: 返回结果

```
═══════════════════════════════════════════
📄 飞书文档获取
═══════════════════════════════════════════

✓ 文档类型: Wiki
✓ 文档标题: 用户登录
✓ 内容长度: 1,234 字符

📊 状态: 获取完成
⏭️  下一步: 解析需求信息
```

## 飞书 MCP 工具

可用的 MCP 工具：
- `docx_v1_document_rawContent` - 获取文档原始内容
- `wiki_v2_space_getNode` - 获取 Wiki 节点信息
- `wiki_v1_node_search` - 搜索 Wiki

## 使用示例

**输入**:
```
请读取这个飞书文档: https://xxx.feishu.cn/wiki/wikcnABC123
```

**输出**:
```markdown
# 用户登录

## 背景
#23181 客服系统需要智能分类能力...

## 需求描述
实现AI大模型客服问题自动分类...
```

## 错误处理

| 错误类型 | 处理方式 |
|----------|----------|
| 无访问权限 | 提示用户检查文档权限 |
| 文档不存在 | 提示用户确认链接正确性 |
| 网络错误 | 提示重试或检查网络 |

## 相关技能

- [Input Detect](../../analysis/input-detect/SKILL.md)
- [Requirement Parse](../../analysis/requirement-parse/SKILL.md)
