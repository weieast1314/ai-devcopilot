#!/bin/bash
# AI DevCopilot 工作流安装脚本
# 技能安装到各编辑器目录，配置统一存储在 ~/.ai-devcopilot/

set -e

# --- 默认配置 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LEGACY_SKILLS_SOURCE="$SCRIPT_DIR/skills/ai-devcopilot"
DIST_DIR="$SCRIPT_DIR/dist"
ADAPTERS_DIR="$SCRIPT_DIR/adapters"
EDITOR_MANIFEST="$ADAPTERS_DIR/editors.json"
BUILD_DIST_SCRIPT="$SCRIPT_DIR/scripts/build-dist.sh"
VERSION="1.3.0"

# 全局配置目录（默认，可由 adapter manifest 覆盖）
GLOBAL_CONFIG_DIR="$HOME/.ai-devcopilot"
ENV_FILE="$GLOBAL_CONFIG_DIR/env.sh"
PROJECT_CONFIG_DIR_REL=".ai-devcopilot"
PROJECT_ENV_FILE_REL="$PROJECT_CONFIG_DIR_REL/env.sh"
PROJECT_MEMORY_DIR_REL="$PROJECT_CONFIG_DIR_REL/memory"
PROJECT_STATE_DIR_REL="$PROJECT_CONFIG_DIR_REL/state"
TEMPLATE_FILE="$SCRIPT_DIR/env.sh.template"
FLOW_STATE_TEMPLATE="$SCRIPT_DIR/templates/flow-state.template.json"

# --- 颜色定义 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

HAS_JQ=0
if command -v jq &> /dev/null; then
    HAS_JQ=1
fi

expand_home_path() {
    local raw_path="$1"
    echo "${raw_path/#\~/$HOME}"
}

load_shared_config() {
    if [ "$HAS_JQ" -eq 1 ] && [ -f "$EDITOR_MANIFEST" ]; then
        GLOBAL_CONFIG_DIR=$(expand_home_path "$(jq -r '.sharedConfig.globalConfigDir // "~/.ai-devcopilot"' "$EDITOR_MANIFEST")")
        ENV_FILE=$(expand_home_path "$(jq -r '.sharedConfig.globalEnvFile // "~/.ai-devcopilot/env.sh"' "$EDITOR_MANIFEST")")
        PROJECT_CONFIG_DIR_REL=$(jq -r '.sharedConfig.projectConfigDir // ".ai-devcopilot"' "$EDITOR_MANIFEST")
        PROJECT_ENV_FILE_REL=$(jq -r '.sharedConfig.projectEnvFile // ".ai-devcopilot/env.sh"' "$EDITOR_MANIFEST")
        PROJECT_MEMORY_DIR_REL=$(jq -r '.sharedConfig.projectMemoryDir // ".ai-devcopilot/memory"' "$EDITOR_MANIFEST")
    fi
}

normalize_editor_id() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

get_dist_skills_source() {
    local editor_id
    editor_id=$(normalize_editor_id "$1")
    echo "$DIST_DIR/$editor_id/skills/ai-devcopilot"
}

resolve_skills_source() {
    local editor_id
    local dist_source

    editor_id=$(normalize_editor_id "$1")
    dist_source=$(get_dist_skills_source "$editor_id")

    # 优先使用已存在的 dist
    if [ -d "$dist_source" ]; then
        echo "$dist_source"
        return 0
    fi

    # dist 不存在，尝试自动构建
    if [ -f "$BUILD_DIST_SCRIPT" ]; then
        echo -e "${YELLOW}      ⚙ 正在构建 dist 产物...${NC}" >&2
        if bash "$BUILD_DIST_SCRIPT" --editor "$editor_id" >/dev/null 2>&1; then
            if [ -d "$dist_source" ]; then
                echo -e "${GREEN}      ✓ 构建完成${NC}" >&2
                echo "$dist_source"
                return 0
            fi
        else
            echo -e "${YELLOW}      ⚠ 构建失败，尝试使用源目录${NC}" >&2
        fi
    fi

    # 回退到源目录
    if [ -d "$LEGACY_SKILLS_SOURCE" ]; then
        echo "$LEGACY_SKILLS_SOURCE"
        return 0
    fi

    return 1
}

describe_skills_source() {
    local editor_id
    local dist_source

    editor_id=$(normalize_editor_id "$1")
    dist_source=$(get_dist_skills_source "$editor_id")

    if [ -d "$dist_source" ]; then
        echo "dist/$editor_id/skills/ai-devcopilot"
    elif [ -d "$LEGACY_SKILLS_SOURCE" ]; then
        echo "skills/ai-devcopilot (legacy fallback)"
    else
        echo "missing"
    fi
}

load_editor_from_manifest() {
    local editor_id="$1"
    local adapter_file="$ADAPTERS_DIR/${editor_id}.json"

    [ -f "$adapter_file" ] || return 1

    ADAPTER_ID=$(jq -r '.id' "$adapter_file")
    ADAPTER_NAME=$(jq -r '.displayName' "$adapter_file")
    ADAPTER_SKILLS_ROOT=$(expand_home_path "$(jq -r '.paths.skillsRoot' "$adapter_file")")
    ADAPTER_SKILLS_TARGET=$(expand_home_path "$(jq -r '.paths.skillsInstallDir' "$adapter_file")")
    ADAPTER_MCP_TARGET=$(expand_home_path "$(jq -r '.paths.mcpConfigPath' "$adapter_file")")
    ADAPTER_SCAN_MODE=$(jq -r '.install.scanMode // "package_root"' "$adapter_file")
    ADAPTER_REQUIRES_TOP_LEVEL_SYMLINK=$(jq -r '.install.requiresTopLevelSymlink // false' "$adapter_file")
    ADAPTER_LINK_RECORD=$(jq -r '.install.linkStrategy.recordFile // empty' "$adapter_file")
    if [ -n "$ADAPTER_LINK_RECORD" ]; then
        ADAPTER_LINK_RECORD=$(expand_home_path "$ADAPTER_LINK_RECORD")
    fi
    ADAPTER_LINK_RULES=$(jq -r '.install.linkStrategy.categories[]? | "\(.name):\(.depth)"' "$adapter_file")
    return 0
}

load_editor_legacy() {
    local editor_id="$1"

    case "$editor_id" in
        claude)
            ADAPTER_ID="claude"
            ADAPTER_NAME="Claude"
            ADAPTER_SKILLS_ROOT="$HOME/.claude/skills"
            ADAPTER_SKILLS_TARGET="$HOME/.claude/skills/ai-devcopilot"
            ADAPTER_MCP_TARGET="$HOME/.claude/mcp.json"
            ADAPTER_SCAN_MODE="top_level_only"
            ADAPTER_REQUIRES_TOP_LEVEL_SYMLINK="true"
            ADAPTER_LINK_RECORD="$HOME/.claude/skills/.ai-devcopilot-links"
            ADAPTER_LINK_RULES=$'atoms:2\ncomposites:2\npipelines:1'
            ;;
        codebuddy)
            ADAPTER_ID="codebuddy"
            ADAPTER_NAME="CodeBuddy"
            ADAPTER_SKILLS_ROOT="$HOME/.codebuddy/skills"
            ADAPTER_SKILLS_TARGET="$HOME/.codebuddy/skills/ai-devcopilot"
            ADAPTER_MCP_TARGET="$HOME/.codebuddy/mcp.json"
            ADAPTER_SCAN_MODE="package_root"
            ADAPTER_REQUIRES_TOP_LEVEL_SYMLINK="false"
            ADAPTER_LINK_RECORD=""
            ADAPTER_LINK_RULES=""
            ;;
        opencode)
            ADAPTER_ID="opencode"
            ADAPTER_NAME="OpenCode"
            ADAPTER_SKILLS_ROOT="$HOME/.opencode/skills"
            ADAPTER_SKILLS_TARGET="$HOME/.opencode/skills/ai-devcopilot"
            ADAPTER_MCP_TARGET="$HOME/.opencode/mcp.json"
            ADAPTER_SCAN_MODE="package_root"
            ADAPTER_REQUIRES_TOP_LEVEL_SYMLINK="false"
            ADAPTER_LINK_RECORD=""
            ADAPTER_LINK_RULES=""
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

load_editor_config() {
    local editor_id
    editor_id=$(normalize_editor_id "$1")

    if [ "$HAS_JQ" -eq 1 ] && load_editor_from_manifest "$editor_id"; then
        return 0
    fi

    load_editor_legacy "$editor_id"
}

print_install_plan() {
    local mode_label="$1"

    echo -e "${YELLOW}安装计划预览（$mode_label）${NC}"
    for editor_id in "${EDITORS[@]}"; do
        if ! load_editor_config "$editor_id"; then
            echo -e "  ${RED}✗ 未找到编辑器配置: $editor_id${NC}"
            exit 1
        fi

        echo ""
        echo "  [$ADAPTER_NAME]"
        echo "    - Skills 来源:     $(describe_skills_source "$editor_id")"
        echo "    - Skills 安装目录: $ADAPTER_SKILLS_TARGET"
        echo "    - MCP 配置路径:   $ADAPTER_MCP_TARGET"
        echo "    - 扫描模式:       $ADAPTER_SCAN_MODE"
        if [ "$ADAPTER_REQUIRES_TOP_LEVEL_SYMLINK" = "true" ]; then
            echo "    - 一级入口链接:   是"
        else
            echo "    - 一级入口链接:   否"
        fi
    done

    echo ""
    echo "  [共享配置]"
    echo "    - 全局配置: $ENV_FILE"
    echo "    - 项目配置: $PROJECT_ENV_FILE_REL"
    echo "    - 项目记忆: $PROJECT_MEMORY_DIR_REL"
    echo "    - 流程状态: $PROJECT_STATE_DIR_REL/flow-state.json"
}

# 帮助信息
show_help() {
    echo "用法: $0 [目标项目路径] [选项]"
    echo ""
    echo "选项:"
    echo "  -e, --editor <name>    指定编辑器 (claude, codebuddy, opencode)"
    echo "  -y, --yes              跳过交互式配置，使用默认模板"
    echo "      --dry-run          仅输出安装计划，不写入文件"
    echo "      --validate-only    校验安装目标与配置路径，不执行安装"
    echo "  -h, --help             显示帮助信息"
    echo ""
    echo "配置架构:"
    echo "  技能目录: \\${EDITOR_HOME}/skills/ai-devcopilot"
    echo "  MCP 配置: \\${EDITOR_HOME}/mcp.json"
    echo "  统一配置: ~/.ai-devcopilot/env.sh"
    exit 0
}

# 生成 MCP 配置文件
generate_mcp_config() {
    local MCP_CONFIG_FILE="$1"
    local MCP_CONFIG_DIR
    MCP_CONFIG_DIR=$(dirname "$MCP_CONFIG_FILE")

    mkdir -p "$MCP_CONFIG_DIR"

    # 检查是否已配置 lark MCP
    if [ -f "$MCP_CONFIG_FILE" ]; then
        if grep -q '"lark"' "$MCP_CONFIG_FILE"; then
            echo -e "      ✓ 飞书 MCP 已配置: $MCP_CONFIG_FILE"
            return
        fi
        echo -e "      ! MCP 配置文件已存在，正在添加飞书配置..."
    fi

    # 生成飞书 MCP 配置片段
    local LARK_CONFIG
    LARK_CONFIG=$(cat << EOF
    "lark": {
      "command": "npx",
      "args": [
        "-y",
        "@larksuiteoapi/lark-mcp",
        "mcp",
        "--app-id",
        "$LARK_ID",
        "--app-secret",
        "$LARK_SECRET"
      ]
    }
EOF
)

    # 如果文件不存在，创建新文件
    if [ ! -f "$MCP_CONFIG_FILE" ]; then
        cat > "$MCP_CONFIG_FILE" << EOF
{
  "mcpServers": {
$LARK_CONFIG
  }
}
EOF
        echo -e "      ✓ 已生成 MCP 配置: $MCP_CONFIG_FILE"
        return
    fi

    # 文件存在，合并配置
    if command -v jq &> /dev/null; then
        local TEMP_FILE
        TEMP_FILE=$(mktemp)
        jq --arg id "$LARK_ID" --arg secret "$LARK_SECRET" \
            '.mcpServers.lark = {
                "command": "npx",
                "args": ["-y", "@larksuiteoapi/lark-mcp", "mcp", "--app-id", $id, "--app-secret", $secret]
            }' "$MCP_CONFIG_FILE" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$MCP_CONFIG_FILE"
        echo -e "      ✓ 已更新 MCP 配置: $MCP_CONFIG_FILE"
    else
        if grep -q '"mcpServers": {}' "$MCP_CONFIG_FILE"; then
            sed -i.bak "s/\"mcpServers\": {}/\"mcpServers\": {\n$LARK_CONFIG\n  }/" "$MCP_CONFIG_FILE"
            rm -f "${MCP_CONFIG_FILE}.bak"
            echo -e "      ✓ 已更新 MCP 配置: $MCP_CONFIG_FILE"
        else
            echo -e "      ! 请手动添加飞书 MCP 配置到: $MCP_CONFIG_FILE"
        fi
    fi
}

create_top_level_links() {
    local skills_target="$1"
    local skills_root="$2"
    local links_record="$3"
    local link_count=0
    local collision_count=0

    mkdir -p "$skills_root"

    if [ -f "$links_record" ]; then
        while IFS= read -r old_link; do
            if [ -L "$old_link" ]; then
                rm -f "$old_link"
            fi
        done < "$links_record"
        rm -f "$links_record"
    fi

    touch "$links_record"

    while IFS=: read -r category depth; do
        [ -n "$category" ] || continue

        if [ "$depth" = "2" ]; then
            for skill_path in "$skills_target/$category"/*/*/; do
                if [ -d "$skill_path" ]; then
                    local skill_name
                    local link_target
                    skill_name=$(basename "$skill_path")
                    link_target="$skills_root/$skill_name"

                    if [ -e "$link_target" ] && [ ! -L "$link_target" ]; then
                        echo -e "      ${YELLOW}⚠ 跳过重名目录: $skill_name${NC}" >&2
                        ((collision_count++))
                        continue
                    fi

                    ln -sf "$skill_path" "$link_target"
                    echo "$link_target" >> "$links_record"
                    ((link_count++))
                fi
            done
        else
            for skill_path in "$skills_target/$category"/*/; do
                if [ -d "$skill_path" ]; then
                    local skill_name
                    local link_target
                    skill_name=$(basename "$skill_path")
                    link_target="$skills_root/$skill_name"

                    if [ -e "$link_target" ] && [ ! -L "$link_target" ]; then
                        echo -e "      ${YELLOW}⚠ 跳过重名目录: $skill_name${NC}" >&2
                        ((collision_count++))
                        continue
                    fi

                    ln -sf "$skill_path" "$link_target"
                    echo "$link_target" >> "$links_record"
                    ((link_count++))
                fi
            done
        fi
    done <<< "$ADAPTER_LINK_RULES"

    echo -e "      ✓ 已创建 $link_count 个一级符号链接入口" >&2
    if [ $collision_count -gt 0 ]; then
        echo -e "      ${YELLOW}⚠ 检测到 $collision_count 个重名目录已跳过${NC}" >&2
    fi
}

install_skills() {
    local editor_id="$1"
    local skills_source

    if ! load_editor_config "$editor_id"; then
        echo -e "      ${RED}✗ 错误: 找不到编辑器配置: $editor_id${NC}" >&2
        return 1
    fi

    if ! skills_source=$(resolve_skills_source "$editor_id"); then
        echo -e "      ${RED}✗ 错误: 找不到可用的 Skills 源目录${NC}" >&2
        if [ -f "$BUILD_DIST_SCRIPT" ]; then
            echo -e "      ${YELLOW}提示: 可先执行 scripts/build-dist.sh 生成 dist 产物${NC}" >&2
        fi
        return 1
    fi

    mkdir -p "$ADAPTER_SKILLS_TARGET"
    cp -r "$skills_source"/* "$ADAPTER_SKILLS_TARGET/"
    echo -e "      ✓ Skills 已安装: $ADAPTER_SKILLS_TARGET" >&2
    echo -e "      ✓ 使用安装源: $skills_source" >&2

    if [ "$ADAPTER_REQUIRES_TOP_LEVEL_SYMLINK" = "true" ]; then
        create_top_level_links "$ADAPTER_SKILLS_TARGET" "$ADAPTER_SKILLS_ROOT" "$ADAPTER_LINK_RECORD"
    fi

    echo "$ADAPTER_MCP_TARGET"
}

load_shared_config

# 解析参数
EDITOR_ARG=""
SKIP_INTERACTIVE=0
DRY_RUN=0
VALIDATE_ONLY=0
POSITIONAL_ARGS=()
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -e|--editor) EDITOR_ARG="$2"; shift ;;
        -y|--yes) SKIP_INTERACTIVE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --validate-only) VALIDATE_ONLY=1 ;;
        -h|--help) show_help ;;
        *) POSITIONAL_ARGS+=("$1") ;;
    esac
    shift
done

# 恢复位置参数
set -- "${POSITIONAL_ARGS[@]}"

# 目标项目路径（第一个位置参数，默认为当前目录）
TARGET_PROJECT=${1:-.}

echo -e "${GREEN}=== AI DevCopilot 工作流安装程序 (v${VERSION}) ===${NC}"
echo ""

# --- 1. 编辑器选择 ---
echo -e "${YELLOW}[1/5] 选择 AI 编辑器${NC}"

if [ -n "$EDITOR_ARG" ]; then
    EDITOR_CHOICE_RAW=$EDITOR_ARG
else
    echo "请选择要安装的编辑器:"
    echo "1) Claude (路径: ~/.claude)"
    echo "2) CodeBuddy (路径: ~/.codebuddy)"
    echo "3) OpenCode (路径: ~/.opencode)"
    echo "4) 全部安装"
    read -p "请选择 [1-4]: " EDITOR_CHOICE_INPUT
    EDITOR_CHOICE_RAW=$EDITOR_CHOICE_INPUT
fi

case $(normalize_editor_id "$EDITOR_CHOICE_RAW") in
    1|claude)
        EDITORS=("claude")
        ;;
    2|codebuddy)
        EDITORS=("codebuddy")
        ;;
    3|opencode)
        EDITORS=("opencode")
        ;;
    4|all)
        EDITORS=("claude" "codebuddy" "opencode")
        ;;
    *)
        EDITORS=("claude")
        ;;
esac

for editor_id in "${EDITORS[@]}"; do
    load_editor_config "$editor_id"
    echo -e "      ✓ 将安装到: ${GREEN}$ADAPTER_NAME${NC}"
done
echo ""

# --- 2. 环境预检 ---
echo -e "${YELLOW}[2/5] 环境预检${NC}"
CHECK_FAILED=0

check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "      ${RED}⚠ 未找到命令: $1 ($2)${NC}"
        return 1
    else
        echo -e "      ✓ $1 已安装"
        return 0
    fi
}

check_cmd "git" "必需：版本管理" || CHECK_FAILED=1
check_cmd "curl" "必需：API 调用" || CHECK_FAILED=1
check_cmd "mvn" "可选：Java 构建" || true
check_cmd "npm" "可选：前端构建" || true

if [ "$HAS_JQ" -eq 0 ]; then
    echo -e "      ${YELLOW}⚠ 未找到 jq，将回退到内置编辑器映射；适配器清单仅作为文档元数据使用${NC}"
else
    echo -e "      ✓ jq 已安装（将使用 adapters/*.json 读取安装目标）"
fi

if [ -d "$DIST_DIR" ]; then
    echo -e "      ✓ 检测到 dist 产物，安装时将优先使用 dist/<editor>"
else
    echo -e "      ${YELLOW}⚠ 未检测到 dist 产物，将回退到 skills/ai-devcopilot 源目录${NC}"
fi

if [ $CHECK_FAILED -eq 1 ]; then
    echo -e "\n${RED}✗ 环境检查未通过，请安装必需组件后重试。${NC}"
    exit 1
fi
echo ""

if [ "$VALIDATE_ONLY" -eq 1 ]; then
    print_install_plan "validate-only"
    echo ""
    echo -e "${GREEN}✓ 校验通过：安装目标与共享配置均可解析${NC}"
    exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
    print_install_plan "dry-run"
    echo ""
    echo -e "${GREEN}✓ Dry-run 完成：未执行任何文件写入${NC}"
    exit 0
fi

# --- 3. 安装 Skills 到各编辑器目录 ---
echo -e "${YELLOW}[3/5] 安装 Skills${NC}"

MCP_FILES=()
for editor_id in "${EDITORS[@]}"; do
    load_editor_config "$editor_id"
    echo ""
    echo "  安装到 $ADAPTER_NAME:"
    result=$(install_skills "$editor_id")
    if [ $? -eq 0 ]; then
        MCP_FILES+=("$result")
    fi
done
echo ""

# --- 4. 项目配置 ---
echo -e "${YELLOW}[4/5] 项目配置${NC}"

# 自动生成 Job 名称默认值
PROJ_NAME=$(basename "$(cd "$TARGET_PROJECT" && pwd)")
DEFAULT_J_DEV="${PROJ_NAME}-dev"
DEFAULT_J_TEST="${PROJ_NAME}-test"

# 检查/生成 .ai-devcopilot/env.sh 文件
AI_DEVCOPILOT_DIR="$TARGET_PROJECT/$PROJECT_CONFIG_DIR_REL"
AI_DEVCOPILOT_FILE="$TARGET_PROJECT/$PROJECT_ENV_FILE_REL"
AI_DEVCOPILOT_MEMORY_DIR="$TARGET_PROJECT/$PROJECT_MEMORY_DIR_REL"
AI_DEVCOPILOT_STATE_DIR="$TARGET_PROJECT/$PROJECT_STATE_DIR_REL"
AI_DEVCOPILOT_STATE_FILE="$TARGET_PROJECT/$PROJECT_STATE_DIR_REL/flow-state.json"
mkdir -p "$AI_DEVCOPILOT_DIR"

if [ -f "$AI_DEVCOPILOT_FILE" ]; then
    echo -e "      ✓ 发现现有项目配置: $PROJECT_ENV_FILE_REL"
else
    cat > "$AI_DEVCOPILOT_FILE" << EOF
# Jenkins Job 配置
# 项目特定的 Job 名称配置，可提交到 Git

export JENKINS_JOB_DEV="$DEFAULT_J_DEV"
export JENKINS_JOB_TEST="$DEFAULT_J_TEST"
EOF
    echo -e "      ✓ 已生成项目配置文件: $PROJECT_ENV_FILE_REL"
    echo -e "        默认 JENKINS_JOB_DEV=$DEFAULT_J_DEV"
    echo -e "        默认 JENKINS_JOB_TEST=$DEFAULT_J_TEST"
    echo -e "        ${YELLOW}提示: 可在流程执行时确认或修改 Job 名称${NC}"
fi

# 项目级数据目录
mkdir -p "$AI_DEVCOPILOT_MEMORY_DIR"
echo -e "      ✓ 已创建项目数据目录: $PROJECT_MEMORY_DIR_REL/"
mkdir -p "$AI_DEVCOPILOT_STATE_DIR"
echo -e "      ✓ 已创建流程状态目录: $PROJECT_STATE_DIR_REL/"
if [ -f "$FLOW_STATE_TEMPLATE" ] && [ ! -f "$AI_DEVCOPILOT_STATE_FILE" ]; then
    cp "$FLOW_STATE_TEMPLATE" "$AI_DEVCOPILOT_STATE_FILE"
    echo -e "      ✓ 已初始化流程状态文件: $PROJECT_STATE_DIR_REL/flow-state.json"
fi
echo ""

# --- 5. 全局配置 (交互式) ---
echo -e "${YELLOW}[5/5] 全局环境配置${NC}"

mkdir -p "$GLOBAL_CONFIG_DIR"

if [ "$SKIP_INTERACTIVE" == "1" ]; then
    CONFIRM_CONFIG="n"
else
    read -p "是否现在配置环境变量 ($ENV_FILE)? [Y/n]: " CONFIRM_CONFIG
fi

if [[ "$CONFIRM_CONFIG" =~ ^[Nn]$ ]]; then
    echo -e "      ! 已跳过交互式配置"
    if [ ! -f "$ENV_FILE" ]; then
        sed -e "s|export JENKINS_URL=.*|export JENKINS_URL=\"http://your-jenkins:8080\"|" \
            -e "s|export JENKINS_USERNAME=.*|export JENKINS_USERNAME=\"your_username\"|" \
            -e "s|export JENKINS_API_TOKEN=.*|export JENKINS_API_TOKEN=\"your_token\"|" \
            -e "s|export NACOS_SERVER_ADDR=.*|export NACOS_SERVER_ADDR=\"your-nacos-server:8848\"|" \
            -e "s|export NACOS_NAMESPACE=.*|export NACOS_NAMESPACE=\"dev\"|" \
            -e "s|export NACOS_GROUP=.*|export NACOS_GROUP=\"DEFAULT_GROUP\"|" \
            "$TEMPLATE_FILE" > "$ENV_FILE"
        echo -e "      ✓ 已创建配置文件: $ENV_FILE"
    fi
    echo -e "      ! 如需使用飞书文档功能，请手动配置 MCP 或重新运行安装脚本"
else
    # 交互式引导
    if [ -f "$ENV_FILE" ]; then
        DEFAULT_J_URL=$(grep "export JENKINS_URL=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        DEFAULT_J_USER=$(grep "export JENKINS_USERNAME=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        DEFAULT_J_TOKEN=$(grep "export JENKINS_API_TOKEN=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        DEFAULT_NACOS_ADDR=$(grep "export NACOS_SERVER_ADDR=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        DEFAULT_NACOS_NS=$(grep "export NACOS_NAMESPACE=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        DEFAULT_NACOS_GROUP=$(grep "export NACOS_GROUP=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        DEFAULT_LARK_ID=$(grep "export LARK_APP_ID=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        DEFAULT_LARK_SECRET=$(grep "export LARK_APP_SECRET=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        echo -e "      ${GREEN}✓${NC} 已从现有配置加载默认值: $ENV_FILE"
    fi

    # 应用默认值
    DEFAULT_J_URL="${DEFAULT_J_URL:-${JENKINS_URL:-http://your-jenkins:8080}}"
    DEFAULT_J_USER="${DEFAULT_J_USER:-${JENKINS_USERNAME:-your_username}}"
    DEFAULT_J_TOKEN="${DEFAULT_J_TOKEN:-${JENKINS_API_TOKEN:-your_token}}"
    DEFAULT_NACOS_ADDR="${DEFAULT_NACOS_ADDR:-your-nacos-server:8848}"
    DEFAULT_NACOS_NS="${DEFAULT_NACOS_NS:-dev}"
    DEFAULT_NACOS_GROUP="${DEFAULT_NACOS_GROUP:-DEFAULT_GROUP}"
    DEFAULT_LARK_ID="${DEFAULT_LARK_ID:-${LARK_APP_ID:-}}"
    DEFAULT_LARK_SECRET="${DEFAULT_LARK_SECRET:-${LARK_APP_SECRET:-}}"

    echo "请输入以下参数 (直接回车将使用默认值):"
    read -p "Jenkins URL [$DEFAULT_J_URL]: " J_URL
    read -p "Jenkins Username [$DEFAULT_J_USER]: " J_USER
    read -p "Jenkins API Token [$DEFAULT_J_TOKEN]: " J_TOKEN

    # Nacos 配置引导
    echo ""
    echo -e "${YELLOW}--- Nacos 配置 ---${NC}"
    read -p "Nacos Server Addr [$DEFAULT_NACOS_ADDR]: " NACOS_ADDR
    read -p "Nacos Namespace [$DEFAULT_NACOS_NS]: " NACOS_NS
    read -p "Nacos Group [$DEFAULT_NACOS_GROUP]: " NACOS_GROUP

    # 应用输入值
    J_URL="${J_URL:-$DEFAULT_J_URL}"
    J_USER="${J_USER:-$DEFAULT_J_USER}"
    J_TOKEN="${J_TOKEN:-$DEFAULT_J_TOKEN}"
    NACOS_ADDR="${NACOS_ADDR:-$DEFAULT_NACOS_ADDR}"
    NACOS_NS="${NACOS_NS:-$DEFAULT_NACOS_NS}"
    NACOS_GROUP="${NACOS_GROUP:-$DEFAULT_NACOS_GROUP}"

    # MCP 配置引导
    echo ""
    echo -e "${YELLOW}--- MCP 服务配置 ---${NC}"
    echo "MCP 服务用于扩展 AI 能力（如飞书文档读取）"
    if [ -n "$DEFAULT_LARK_ID" ]; then
        echo -e "      检测到已有飞书配置: LARK_APP_ID=${DEFAULT_LARK_ID:0:8}..."
        read -p "是否使用已有的飞书配置? [Y/n]: " USE_ENV_LARK
        if [[ ! "$USE_ENV_LARK" =~ ^[Nn]$ ]]; then
            LARK_ID="$DEFAULT_LARK_ID"
            LARK_SECRET="$DEFAULT_LARK_SECRET"
            CONFIGURE_LARK="y"
        else
            read -p "是否重新配置飞书 MCP? [y/N]: " CONFIGURE_LARK
            if [[ "$CONFIGURE_LARK" =~ ^[Yy]$ ]]; then
                read -p "飞书 App ID: " LARK_ID
                read -p "飞书 App Secret: " LARK_SECRET
            fi
        fi
    else
        read -p "是否配置飞书 MCP? [y/N]: " CONFIGURE_LARK
        if [[ "$CONFIGURE_LARK" =~ ^[Yy]$ ]]; then
            read -p "飞书 App ID: " LARK_ID
            read -p "飞书 App Secret: " LARK_SECRET
        fi
    fi

    # 基于模板生成
    sed -e "s|export JENKINS_URL=.*|export JENKINS_URL=\"$J_URL\"|" \
        -e "s|export JENKINS_USERNAME=.*|export JENKINS_USERNAME=\"$J_USER\"|" \
        -e "s|export JENKINS_API_TOKEN=.*|export JENKINS_API_TOKEN=\"$J_TOKEN\"|" \
        -e "s|export NACOS_SERVER_ADDR=.*|export NACOS_SERVER_ADDR=\"$NACOS_ADDR\"|" \
        -e "s|export NACOS_NAMESPACE=.*|export NACOS_NAMESPACE=\"$NACOS_NS\"|" \
        -e "s|export NACOS_GROUP=.*|export NACOS_GROUP=\"$NACOS_GROUP\"|" \
        -e "s|^# export LARK_APP_ID=.*|export LARK_APP_ID=\"${LARK_ID:-}\"|" \
        -e "s|^# export LARK_APP_SECRET=.*|export LARK_APP_SECRET=\"${LARK_SECRET:-}\"|" \
        "$TEMPLATE_FILE" > "$ENV_FILE"

    # 如果配置了飞书 MCP，为每个编辑器生成 MCP 配置文件
    if [[ "$CONFIGURE_LARK" =~ ^[Yy]$ ]] && [ -n "$LARK_ID" ]; then
        echo ""
        echo -e "${YELLOW}--- 生成 MCP 配置 ---${NC}"
        for mcp_file in "${MCP_FILES[@]}"; do
            if [ -n "$mcp_file" ]; then
                generate_mcp_config "$mcp_file"
            fi
        done
    fi

    echo -e "      ✓ 配置文件已生成: $ENV_FILE"
fi

# 添加 .ai-devcopilot 数据目录到 .gitignore
GITIGNORE="$TARGET_PROJECT/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if ! grep -q "$PROJECT_MEMORY_DIR_REL/" "$GITIGNORE"; then
        echo "" >> "$GITIGNORE"
        echo "# AI DevCopilot 数据目录" >> "$GITIGNORE"
        echo "$PROJECT_MEMORY_DIR_REL/" >> "$GITIGNORE"
        echo -e "      ✓ 已添加 $PROJECT_MEMORY_DIR_REL/ 到 .gitignore"
    fi
fi

echo ""
echo -e "${GREEN}=== 安装成功 ===${NC}"
echo ""
echo "安装位置:"
for editor_id in "${EDITORS[@]}"; do
    load_editor_config "$editor_id"
    printf "  %-10s %b%s%b\n" "$ADAPTER_NAME:" "$YELLOW" "$ADAPTER_SKILLS_TARGET/" "$NC"
    if [ "$ADAPTER_REQUIRES_TOP_LEVEL_SYMLINK" = "true" ]; then
        echo -e "             ${GREEN}(已创建一级符号链接入口供 $ADAPTER_NAME 扫描)${NC}"
    fi
done
echo ""
echo "统一配置:"
echo -e "  全局配置: ${YELLOW}$ENV_FILE${NC}"
echo ""
echo "项目配置:"
echo -e "  项目配置: ${YELLOW}$PROJECT_ENV_FILE_REL${NC}"
echo -e "  项目记忆: ${YELLOW}$PROJECT_MEMORY_DIR_REL/${NC}"
echo -e "  流程状态: ${YELLOW}$PROJECT_STATE_DIR_REL/flow-state.json${NC}"
echo ""
echo "下一步:"
echo "  1. 重启 AI 编辑器以加载新配置"
echo "  2. 在对话框输入 '开始开发' 或 /dev 开启标准开发流程"
echo "  3. 推荐触发词："
echo "     - 开始开发 / /dev : 标准开发流程"
echo "     - 热修复 / /hotfix : 热修复流程"
echo "     - 飞书文档链接     : 自动识别并进入标准开发流程"
echo ""
