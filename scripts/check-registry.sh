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

const registry = JSON.parse(fs.readFileSync(registryFile, 'utf8'));

function assertArray(value, name) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error(`${name} must be a non-empty array`);
  }
}

assertArray(registry.atoms, 'atoms');
assertArray(registry.composites, 'composites');
assertArray(registry.pipelines, 'pipelines');

const declaredAtoms = new Set();
const declaredComposites = new Set();
const declaredPipelines = new Set();
const dependencyNames = new Set();

for (const atom of registry.atoms) {
  if (!atom.name || !atom.category || !atom.version) {
    throw new Error(`invalid atom entry: ${JSON.stringify(atom)}`);
  }
  declaredAtoms.add(atom.name);
}

for (const composite of registry.composites) {
  if (!composite.name || !composite.category || !composite.version || !Array.isArray(composite.dependsOn)) {
    throw new Error(`invalid composite entry: ${JSON.stringify(composite)}`);
  }
  declaredComposites.add(composite.name);
  composite.dependsOn.forEach((dependency) => dependencyNames.add(dependency));
}

for (const pipeline of registry.pipelines) {
  if (!pipeline.name || !pipeline.version || !Array.isArray(pipeline.dependsOn)) {
    throw new Error(`invalid pipeline entry: ${JSON.stringify(pipeline)}`);
  }
  declaredPipelines.add(pipeline.name);
  pipeline.dependsOn.forEach((dependency) => dependencyNames.add(dependency));
}

for (const dependency of dependencyNames) {
  if (!declaredAtoms.has(dependency) && !declaredComposites.has(dependency) && !declaredPipelines.has(dependency)) {
    throw new Error(`registry dependency is not declared: ${dependency}`);
  }
}

function collectLeafDirs(baseRelative, expectedDepth) {
  const base = path.join(skillsDir, baseRelative);
  const output = [];

  function walk(current) {
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      const fullPath = path.join(current, entry.name);
      const relPath = path.relative(skillsDir, fullPath).replace(/\\/g, '/');
      const depth = relPath.split('/').length;
      if (depth === expectedDepth) {
        output.push(relPath);
      } else if (depth < expectedDepth) {
        walk(fullPath);
      }
    }
  }

  if (fs.existsSync(base)) {
    walk(base);
  }
  return output;
}

const actualAtoms = new Set(collectLeafDirs('atoms', 3));
const actualComposites = new Set(collectLeafDirs('composites', 3));
const actualPipelines = new Set(collectLeafDirs('pipelines', 2));

const declaredAtomPaths = new Set(registry.atoms.map((item) => `atoms/${item.category}/${item.name}`));
const declaredCompositePaths = new Set(registry.composites.map((item) => `composites/${item.category}/${item.name}`));
const declaredPipelinePaths = new Set(registry.pipelines.map((item) => `pipelines/${item.name}`));

function diff(expected, actual, label) {
  const missing = [...expected].filter((item) => !actual.has(item)).sort();
  const extra = [...actual].filter((item) => !expected.has(item)).sort();
  if (missing.length > 0) {
    throw new Error(`${label} declares missing directories:\n${missing.join('\n')}`);
  }
  if (extra.length > 0) {
    throw new Error(`${label} has undeclared directories:\n${extra.join('\n')}`);
  }
}

diff(declaredAtomPaths, actualAtoms, 'atom registry');
diff(declaredCompositePaths, actualComposites, 'composite registry');
diff(declaredPipelinePaths, actualPipelines, 'pipeline registry');

if (!registry.capabilityRefs || !registry.capabilityRefs.matrix || !registry.capabilityRefs.fallbacks) {
  throw new Error('registry missing capabilityRefs.matrix or capabilityRefs.fallbacks');
}

for (const ref of Object.values(registry.capabilityRefs)) {
  const target = path.join(root, ref);
  if (!fs.existsSync(target)) {
    throw new Error(`registry capability reference not found: ${ref}`);
  }
}

const matrixPath = path.join(root, registry.capabilityRefs.matrix);
const matrix = JSON.parse(fs.readFileSync(matrixPath, 'utf8'));
const capabilities = new Set(Object.keys(matrix.capabilities || {}));

const mandatorySuperpowersComposites = {
  'writing-plans': ['brainstorming', 'writing-plans'],
  'executing-plans': ['executing-plans', 'test-driven-development', 'systematic-debugging'],
  'code-verification': ['verification-before-completion', 'code-review'],
  'code-delivery': ['finishing-branch']
};

for (const [name, expectedSkills] of Object.entries(mandatorySuperpowersComposites)) {
  const composite = registry.composites.find((item) => item.name === name);
  if (!composite) {
    throw new Error(`missing mandatory composite: ${name}`);
  }

  const policy = composite.providerPolicy || {};
  if (policy.required !== 'superpowers') {
    throw new Error(`composite ${name} must set providerPolicy.required=superpowers`);
  }
  if (policy.onMissing !== 'blocking') {
    throw new Error(`composite ${name} must set providerPolicy.onMissing=blocking`);
  }
  if (!Array.isArray(policy.requiredSkills) || policy.requiredSkills.length === 0) {
    throw new Error(`composite ${name} must declare providerPolicy.requiredSkills`);
  }

  for (const skill of expectedSkills) {
    if (!policy.requiredSkills.includes(skill)) {
      throw new Error(`composite ${name} missing required skill: ${skill}`);
    }
  }

  for (const skill of policy.requiredSkills) {
    const capabilityKey = `skill.superpowers.${skill}`;
    if (!capabilities.has(capabilityKey)) {
      throw new Error(`missing capability declaration: ${capabilityKey}`);
    }
  }
}

for (const pipeline of registry.pipelines) {
  const policy = pipeline.stageProviderPolicy || {};
  if (policy.sessionPreflight !== 'using-superpowers') {
    throw new Error(`pipeline ${pipeline.name} must set sessionPreflight=using-superpowers`);
  }
  if (policy.projectRouter !== 'entry-router') {
    throw new Error(`pipeline ${pipeline.name} must set projectRouter=entry-router`);
  }
  if (policy.stageRequiredProvider !== 'superpowers') {
    throw new Error(`pipeline ${pipeline.name} must set stageRequiredProvider=superpowers`);
  }
  if (policy.onMissing !== 'blocking') {
    throw new Error(`pipeline ${pipeline.name} must set onMissing=blocking`);
  }
}

console.log('registry validation passed');
NODE
