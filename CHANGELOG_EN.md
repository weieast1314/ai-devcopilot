# Changelog

This document records all important changes to the AI DevCopilot project.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

**🌐 [中文](CHANGELOG.md)** | **English**

## [Unreleased]

### Added
- Improve open source project documentation structure
- Add MIT open source license
- Add contributing guide (CONTRIBUTING.md)
- Add code of conduct (CODE_OF_CONDUCT.md)
- Add GitHub Issue and PR templates
- Improve README.md with badges and table of contents
- Add bilingual documentation support (Chinese/English)
- Add structural integration docs for `superpowers` with stage mapping guidance
- Add `skill.superpowers.*` capability declarations into the capability matrix

### Changed
- Upgrade routing to a three-level mandatory priority: session-level `using-superpowers` → project-level `entry-router` → stage-level required superpowers skills
- Extend `skills-registry.yml` with provider / providerPolicy / stageProviderPolicy metadata
- Update `fallback-rules.json` to enforce blocking behavior when superpowers skills are unavailable
- Bump visible version markers to `1.4.0` in README and Agent source

## [1.3.0] - 2026-03-18

### Added
- Complete four-phase workflow: Requirements Acquisition → Solution Design → Code Implementation → One-Click Delivery
- Feishu document integration, automatically read requirements and create branches
- Intelligent planning mode, automatically generate implementation plans
- Jenkins automatic deployment integration
- Multi-editor support (Claude, CodeBuddy, OpenCode)
- Dual-layer configuration architecture ensuring sensitive information security
- Team collaboration standards (branch naming, commit messages)
- Complete installation script and configuration templates

### Skills System
- `entry-router`: Unified entry routing
- `requirement-fetch`: Multi-source requirement intake
- `requirement-to-branch`: Requirement to branch
- `writing-plans`: Planning mode
- `executing-plans`: Plan execution
- `code-verification`: Code verification
- `code-delivery`: Code delivery
- `jenkins-trigger`: Jenkins deployment trigger
- `nacos-config`: Nacos configuration management
- `code-review`: Code review

### Documentation
- Detailed usage tutorial
- Team quick start guide
- Team FAQ
- Usage examples and quick reference

### Tools
- Installation script (`install.sh`)
- Demo script (`demo.sh`)
- Configuration templates (`env.sh.template`)
- Plan and PR templates

## [1.0.0] - 2026-03-13

### Added
- Project initialization
- Basic workflow framework
- Core skills development

---

## Version Notes

- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible functionality additions
- **PATCH**: Backward-compatible bug fixes

## How to Update

```bash
# Pull latest code
cd /path/to/ai-devcopilot
git pull

# Reinstall
./install.sh -e claude -y

# Restart editor
```

---

**Last Updated**: 2026-03-27