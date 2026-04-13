#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CORE_SOURCE="$ROOT_DIR/core/agent/AI DevCopilot.source.md"
SKILLS_SOURCE="$ROOT_DIR/skills/ai-devcopilot"
TEMPLATE_DIR="$ROOT_DIR/templates/agent"
DIST_DIR="$ROOT_DIR/dist"
EDITOR_MANIFEST="$ROOT_DIR/adapters/editors.json"
DEFAULT_EDITOR="claude"
HAS_JQ=0

if command -v jq >/dev/null 2>&1; then
    HAS_JQ=1
fi

show_help() {
    echo "用法: $0 [--editor <claude|codebuddy|opencode|all>]"
    echo ""
    echo "选项:"
    echo "  --editor <name>   仅构建指定编辑器；默认 all"
    echo "  -h, --help        显示帮助信息"
}

normalize_editor_id() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

get_default_editor() {
    if [ "$HAS_JQ" -eq 1 ] && [ -f "$EDITOR_MANIFEST" ]; then
        jq -r '.defaultEditor // "claude"' "$EDITOR_MANIFEST"
    else
        echo "$DEFAULT_EDITOR"
    fi
}

get_manifest_editors() {
    if [ "$HAS_JQ" -eq 1 ] && [ -f "$EDITOR_MANIFEST" ]; then
        jq -r '.editors[].id' "$EDITOR_MANIFEST"
    else
        printf '%s\n' claude codebuddy opencode
    fi
}

get_frontmatter_profile() {
    local editor_id="$1"
    local adapter_file="$ROOT_DIR/adapters/${editor_id}.json"

    if [ "$HAS_JQ" -eq 1 ] && [ -f "$adapter_file" ]; then
        jq -r '.runtime.agentFrontmatterProfile // .id' "$adapter_file"
    else
        echo "$editor_id"
    fi
}

render_agent_file() {
    local template_file="$1"
    local output_file="$2"

    awk -v body_file="$CORE_SOURCE" '
        $0 == "{{PROMPT_BODY}}" {
            while ((getline line < body_file) > 0) {
                print line
            }
            close(body_file)
            next
        }
        { print }
    ' "$template_file" > "$output_file"
}

build_editor_dist() {
    local editor_id="$1"
    local profile
    local template_file
    local editor_dist_dir
    local editor_skills_dist
    local editor_agent_dist

    profile=$(get_frontmatter_profile "$editor_id")
    template_file="$TEMPLATE_DIR/${profile}.md.tpl"
    editor_dist_dir="$DIST_DIR/$editor_id"
    editor_skills_dist="$editor_dist_dir/skills/ai-devcopilot"
    editor_agent_dist="$editor_dist_dir/AI DevCopilot.md"

    if [ ! -f "$template_file" ]; then
        echo "错误: 找不到模板文件 $template_file" >&2
        exit 1
    fi

    rm -rf "$editor_dist_dir"
    mkdir -p "$editor_dist_dir/skills"
    cp -R "$SKILLS_SOURCE" "$editor_skills_dist"
    render_agent_file "$template_file" "$editor_agent_dist"

    echo "已生成 [$editor_id]"
    echo "  - Agent:  $editor_agent_dist"
    echo "  - Skills: $editor_skills_dist"
}

TARGET_EDITOR="all"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --editor)
            TARGET_EDITOR="$2"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知参数: $1" >&2
            show_help >&2
            exit 1
            ;;
    esac
    shift
done

if [ ! -f "$CORE_SOURCE" ]; then
    echo "错误: 找不到核心 Agent 源文件 $CORE_SOURCE" >&2
    exit 1
fi

if [ ! -d "$SKILLS_SOURCE" ]; then
    echo "错误: 找不到 Skills 源目录 $SKILLS_SOURCE" >&2
    exit 1
fi

mkdir -p "$DIST_DIR"
DEFAULT_EDITOR=$(normalize_editor_id "$(get_default_editor)")

if [ "$(normalize_editor_id "$TARGET_EDITOR")" = "all" ]; then
    EDITORS=()
    while IFS= read -r editor_id; do
        [ -n "$editor_id" ] && EDITORS+=("$editor_id")
    done < <(get_manifest_editors)
else
    EDITORS=("$(normalize_editor_id "$TARGET_EDITOR")")
fi

BUILT_DEFAULT=0
for editor_id in "${EDITORS[@]}"; do
    build_editor_dist "$editor_id"
    if [ "$(normalize_editor_id "$editor_id")" = "$DEFAULT_EDITOR" ]; then
        cp "$DIST_DIR/$editor_id/AI DevCopilot.md" "$ROOT_DIR/AI DevCopilot.md"
        BUILT_DEFAULT=1
    fi
done

if [ "$BUILT_DEFAULT" -eq 1 ]; then
    echo "已同步默认 Agent 产物: $ROOT_DIR/AI DevCopilot.md"
fi
