#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ROOT_DIR_ENV="$ROOT_DIR" node <<'NODE'
const fs = require('fs');
const path = require('path');

const root = process.env.ROOT_DIR_ENV;
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'adapters', 'editors.json'), 'utf8'));
const requiredShared = ['globalConfigDir', 'globalEnvFile', 'projectConfigDir', 'projectEnvFile', 'projectMemoryDir'];
const requiredPaths = ['skillsRoot', 'skillsInstallDir', 'mcpConfigPath'];
const requiredRuntime = ['supportsMcp', 'supportsAutoRun', 'supportsAskFollowup', 'supportsStatePersistence', 'agentFrontmatterProfile'];
const requiredInstall = ['scanMode', 'requiresTopLevelSymlink'];

for (const key of requiredShared) {
  if (!(manifest.sharedConfig && Object.prototype.hasOwnProperty.call(manifest.sharedConfig, key))) {
    throw new Error(`editors.json missing sharedConfig.${key}`);
  }
}

if (!Array.isArray(manifest.editors) || manifest.editors.length === 0) {
  throw new Error('editors.json does not declare any editors');
}

for (const editor of manifest.editors) {
  const adapterPath = path.join(root, 'adapters', editor.adapterFile);
  const adapter = JSON.parse(fs.readFileSync(adapterPath, 'utf8'));
  for (const key of requiredPaths) {
    if (!(adapter.paths && Object.prototype.hasOwnProperty.call(adapter.paths, key))) {
      throw new Error(`${path.basename(adapterPath)} missing paths.${key}`);
    }
  }
  for (const key of requiredRuntime) {
    if (!(adapter.runtime && Object.prototype.hasOwnProperty.call(adapter.runtime, key))) {
      throw new Error(`${path.basename(adapterPath)} missing runtime.${key}`);
    }
  }
  for (const key of requiredInstall) {
    if (!(adapter.install && Object.prototype.hasOwnProperty.call(adapter.install, key))) {
      throw new Error(`${path.basename(adapterPath)} missing install.${key}`);
    }
  }
}

console.log('adapter validation passed');
NODE

bash "$ROOT_DIR/install.sh" "$ROOT_DIR" -e all --validate-only -y >/dev/null
bash "$ROOT_DIR/install.sh" "$ROOT_DIR" -e all --dry-run -y >/dev/null

echo "install target validation passed"
