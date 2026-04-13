#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
REGISTRY_FILE="$ROOT_DIR/skills/ai-devcopilot/registry/skills-registry.yml"
FALLBACK_FILE="$ROOT_DIR/capabilities/fallback-rules.json"
MATRIX_FILE="$ROOT_DIR/capabilities/capability-matrix.json"

check_agent() {
    local agent_file="$1"

    grep -q 'entry-router' "$agent_file" || { echo "缺少 entry-router 引导: $agent_file" >&2; exit 1; }
    grep -q 'dev-flow' "$agent_file" || { echo "缺少 dev-flow 描述: $agent_file" >&2; exit 1; }
    grep -q 'hotfix-flow' "$agent_file" || { echo "缺少 hotfix-flow 描述: $agent_file" >&2; exit 1; }
    grep -q '确认计划，开始执行' "$agent_file" || { echo "缺少计划确认口令: $agent_file" >&2; exit 1; }
    grep -q 'using-superpowers(强制)' "$agent_file" || { echo "缺少 using-superpowers 强制约束: $agent_file" >&2; exit 1; }
    grep -q '缺失时必须阻断流程并提示启用 superpowers' "$agent_file" || { echo "缺少 superpowers 缺失阻断约束: $agent_file" >&2; exit 1; }
}

check_registry() {
    local registry_file="$1"

    grep -q '"stageRequiredProvider": "superpowers"' "$registry_file" || { echo "registry 缺少 stageRequiredProvider=superpowers" >&2; exit 1; }
    grep -q '"onMissing": "blocking"' "$registry_file" || { echo "registry 缺少 onMissing=blocking" >&2; exit 1; }
    grep -q '"required": "superpowers"' "$registry_file" || { echo "registry 缺少 required superpowers" >&2; exit 1; }
    ! grep -q '"preferred": "superpowers"' "$registry_file" || { echo "registry 不应包含 preferred superpowers" >&2; exit 1; }
}

check_fallback() {
    local fallback_file="$1"

    ! grep -q 'fallback_to_local_writing_plans' "$fallback_file" || { echo "fallback 不应再回退 local writing-plans" >&2; exit 1; }
    ! grep -q 'fallback_to_local_delivery' "$fallback_file" || { echo "fallback 不应再回退 local code-delivery" >&2; exit 1; }
    ! grep -q 'keep_pipeline_and_use_local_composites' "$fallback_file" || { echo "fallback 不应继续本地 composite 回退" >&2; exit 1; }
    grep -q '"dev-flow"' "$fallback_file" || { echo "fallback 缺少 dev-flow 规则" >&2; exit 1; }
    grep -q '"behavior": "stop_and_require_superpowers"' "$fallback_file" || { echo "fallback 缺少 superpowers 阻断行为" >&2; exit 1; }
}

check_matrix() {
    local matrix_file="$1"

    grep -q '"skill.superpowers.test-driven-development"' "$matrix_file" || { echo "capability matrix 缺少 test-driven-development 声明" >&2; exit 1; }
    python3 - "$matrix_file" <<'PY'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    matrix = json.load(f)

pipelines = matrix.get('targets', {}).get('pipelines', {})
for name, config in pipelines.items():
    if 'skill.superpowers.available' in config.get('optional', []):
        raise SystemExit(f"pipeline {name} 不应把 skill.superpowers.available 放进 optional")
PY
}

for editor in claude codebuddy opencode; do
    [ -f "$DIST_DIR/$editor/AI DevCopilot.md" ] || { echo "缺少 Agent 产物: $DIST_DIR/$editor/AI DevCopilot.md" >&2; exit 1; }
    [ -f "$DIST_DIR/$editor/skills/ai-devcopilot/pipelines/dev-flow/SKILL.md" ] || { echo "缺少 dev-flow Skill: $editor" >&2; exit 1; }
    [ -f "$DIST_DIR/$editor/skills/ai-devcopilot/pipelines/hotfix-flow/SKILL.md" ] || { echo "缺少 hotfix-flow Skill: $editor" >&2; exit 1; }
    [ -f "$DIST_DIR/$editor/skills/ai-devcopilot/registry/skills-registry.yml" ] || { echo "缺少 dist registry: $editor" >&2; exit 1; }
    check_agent "$DIST_DIR/$editor/AI DevCopilot.md"
    check_registry "$DIST_DIR/$editor/skills/ai-devcopilot/registry/skills-registry.yml"
done

check_agent "$ROOT_DIR/AI DevCopilot.md"
check_registry "$REGISTRY_FILE"
check_fallback "$FALLBACK_FILE"
check_matrix "$MATRIX_FILE"

echo "dev-flow 冒烟校验通过"
