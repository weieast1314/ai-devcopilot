#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
EDITOR_MANIFEST="$ROOT_DIR/adapters/editors.json"
ROOT_AGENT_FILE="$ROOT_DIR/AI DevCopilot.md"
HAS_JQ=0

if command -v jq >/dev/null 2>&1; then
    HAS_JQ=1
fi

normalize_editor_id() {
    echo "$1" | tr -d '\r' | tr '[:upper:]' '[:lower:]'
}

get_default_editor() {
    if [ "$HAS_JQ" -eq 1 ] && [ -f "$EDITOR_MANIFEST" ]; then
        jq -r '.defaultEditor // "claude"' "$EDITOR_MANIFEST"
    else
        echo "claude"
    fi
}

get_manifest_editors() {
    if [ "$HAS_JQ" -eq 1 ] && [ -f "$EDITOR_MANIFEST" ]; then
        jq -r '.editors[].id' "$EDITOR_MANIFEST"
    else
        printf '%s\n' claude codebuddy opencode
    fi
}

check_file() {
    local path="$1"
    [ -f "$path" ] || { echo "缺少文件: $path" >&2; exit 1; }
}

check_dir() {
    local path="$1"
    [ -d "$path" ] || { echo "缺少目录: $path" >&2; exit 1; }
}

check_agent_file() {
    local path="$1"

    check_file "$path"
    grep -q '^---$' "$path" || { echo "Agent 文件缺少 frontmatter: $path" >&2; exit 1; }
    if grep -q '{{PROMPT_BODY}}' "$path"; then
        echo "Agent 文件仍包含未替换占位符: $path" >&2
        exit 1
    fi
}

EDITORS=()
while IFS= read -r editor_id; do
    [ -n "$editor_id" ] && EDITORS+=("$(normalize_editor_id "$editor_id")")
done < <(get_manifest_editors)
DEFAULT_EDITOR=$(normalize_editor_id "$(get_default_editor)")
DEFAULT_DIST_AGENT="$DIST_DIR/$DEFAULT_EDITOR/AI DevCopilot.md"

for editor_id in "${EDITORS[@]}"; do
    check_dir "$DIST_DIR/$editor_id"
    check_dir "$DIST_DIR/$editor_id/skills/ai-devcopilot"
    check_agent_file "$DIST_DIR/$editor_id/AI DevCopilot.md"
done

check_agent_file "$ROOT_AGENT_FILE"
check_file "$DEFAULT_DIST_AGENT"
cmp -s "$ROOT_AGENT_FILE" "$DEFAULT_DIST_AGENT" || {
    echo "根目录 AI DevCopilot.md 与默认编辑器产物不一致" >&2
    exit 1
}

echo "dist 校验通过"
