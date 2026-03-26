#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ROOT_DIR_ENV="$ROOT_DIR" node <<'NODE'
const fs = require('fs');
const path = require('path');

const root = process.env.ROOT_DIR_ENV;
const registryFile = path.join(root, 'skills', 'ai-devcopilot', 'registry', 'skills-registry.yml');
const skillsDir = path.join(root, 'skills', 'ai-devcopilot');
const lines = fs.readFileSync(registryFile, 'utf8').split(/\r?\n/);

let context = null;
let section = null;
const registered = new Set();

for (const line of lines) {
  if (line.startsWith('## 原子 Skill')) {
    context = 'atoms';
    continue;
  }
  if (line.startsWith('## 组合 Skill')) {
    context = 'composites';
    continue;
  }
  if (line.startsWith('## Pipeline')) {
    context = 'pipelines';
    continue;
  }
  if (line.startsWith('## ')) {
    context = null;
    continue;
  }
  if (line.startsWith('### ')) {
    section = line.slice(4).split(' ', 1)[0].trim();
    continue;
  }
  if (!line.startsWith('|')) {
    continue;
  }

  const cells = line.trim().replace(/^\||\|$/g, '').split('|').map((cell) => cell.trim());
  if (cells.length === 0) {
    continue;
  }
  if (['Skill', 'Pipeline', '对象', '-------', '----------'].includes(cells[0])) {
    continue;
  }
  if (/^-+$/.test(cells[0])) {
    continue;
  }

  const name = cells[0];
  if (context === 'atoms' && section) {
    registered.add(`atoms/${section}/${name}`);
  } else if (context === 'composites' && section) {
    registered.add(`composites/${section}/${name}`);
  } else if (context === 'pipelines') {
    registered.add(`pipelines/${name}`);
  }
}

function collectDirs(baseRelative, minDepth, maxDepth) {
  const base = path.join(skillsDir, baseRelative);
  const output = [];

  function walk(current, depth) {
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      const fullPath = path.join(current, entry.name);
      const relPath = path.relative(skillsDir, fullPath).replace(/\\/g, '/');
      const relDepth = relPath.split('/').length;
      if (relDepth >= minDepth && relDepth <= maxDepth) {
        output.push(relPath);
      }
      if (relDepth < maxDepth) {
        walk(fullPath, depth + 1);
      }
    }
  }

  if (fs.existsSync(base)) {
    walk(base, 1);
  }
  return output;
}

const actual = new Set([
  ...collectDirs('atoms', 3, 3),
  ...collectDirs('composites', 3, 3),
  ...collectDirs('pipelines', 2, 2),
]);

const missing = [...registered].filter((item) => !actual.has(item)).sort();
const extra = [...actual].filter((item) => !registered.has(item)).sort();

if (missing.length > 0) {
  throw new Error(`registry declares missing directories:\n${missing.join('\n')}`);
}
if (extra.length > 0) {
  throw new Error(`directories exist but are not declared in registry:\n${extra.join('\n')}`);
}

console.log('registry validation passed');
NODE
