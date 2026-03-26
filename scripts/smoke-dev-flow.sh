#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"

check_agent() {
    local agent_file="$1"

    grep -q 'entry-router' "$agent_file" || { echo "缺少 entry-router 引导: $agent_file" >&2; exit 1; }
    grep -q 'dev-flow' "$agent_file" || { echo "缺少 dev-flow 描述: $agent_file" >&2; exit 1; }
    grep -q 'hotfix-flow' "$agent_file" || { echo "缺少 hotfix-flow 描述: $agent_file" >&2; exit 1; }
    grep -q '确认计划，开始执行' "$agent_file" || { echo "缺少计划确认口令: $agent_file" >&2; exit 1; }
}

for editor in claude codebuddy opencode; do
    [ -f "$DIST_DIR/$editor/AI DevCopilot.md" ] || { echo "缺少 Agent 产物: $DIST_DIR/$editor/AI DevCopilot.md" >&2; exit 1; }
    [ -f "$DIST_DIR/$editor/skills/ai-devcopilot/pipelines/dev-flow/SKILL.md" ] || { echo "缺少 dev-flow Skill: $editor" >&2; exit 1; }
    [ -f "$DIST_DIR/$editor/skills/ai-devcopilot/pipelines/hotfix-flow/SKILL.md" ] || { echo "缺少 hotfix-flow Skill: $editor" >&2; exit 1; }
    check_agent "$DIST_DIR/$editor/AI DevCopilot.md"
done

check_agent "$ROOT_DIR/AI DevCopilot.md"

echo "dev-flow 冒烟校验通过"
