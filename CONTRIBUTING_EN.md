# Contributing Guide

Thank you for your interest in the AI DevCopilot project! We welcome contributions of any kind, including but not limited to code, documentation, bug reports, and feature suggestions.

**🌐 [中文](CONTRIBUTING.md)** | **English**

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
  - [Reporting Issues](#reporting-issues)
  - [Submitting Code](#submitting-code)
  - [Improving Documentation](#improving-documentation)
- [Development Environment Setup](#development-environment-setup)
- [Code Standards](#code-standards)
- [Commit Message Convention](#commit-message-convention)
- [Branch Management](#branch-management)
- [Pull Request Process](#pull-request-process)
- [Version Release](#version-release)

## Code of Conduct

This project adopts the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project, you agree to abide by this code.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature suggestion, please submit it through the following:

1. **Search Existing Issues**: Ensure your issue hasn't been reported yet
2. **Create New Issue**: Use the provided Issue templates
3. **Provide Detailed Information**:
   - Issue description
   - Steps to reproduce
   - Expected behavior vs actual behavior
   - Environment information (OS, editor version, etc.)
   - Relevant logs or screenshots

### Submitting Code

1. **Fork the Project**: Click the "Fork" button in the upper right corner of the project
2. **Clone Your Fork**:
   ```bash
   git clone https://github.com/your-username/ai-devcopilot.git
   cd ai-devcopilot
   ```
3. **Create Feature Branch**:
   ```bash
   git checkout -b feat/your-feature-name
   ```
4. **Make Changes and Test**
5. **Commit Changes**:
   ```bash
   git add .
   git commit -m "feat: Add new feature description"
   ```
6. **Push to Your Fork**:
   ```bash
   git push origin feat/your-feature-name
   ```
7. **Create Pull Request**

### Improving Documentation

Documentation contributions are equally important! You can improve documentation by:

- Fixing typos
- Adding usage examples
- Translating documentation
- Improving clarity of explanations

## Development Environment Setup

### Prerequisites

| Tool | Version Requirement | Installation |
|------|---------------------|--------------|
| Git | 2.x+ | [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) |
| Bash | 4.x+ | Built-in on macOS/Linux; Git Bash is recommended on Windows |
| Node.js | 18.x+ | Required for `check-registry.sh` and `check-install-targets.sh` |
| jq (optional) | 1.6+ | Improves parsing in `build-dist.sh` and `validate-dist.sh` |
| PowerShell | 5.1+ | Built-in on Windows, used for `install.ps1` |
| AI Editor | Claude/CodeBuddy/OpenCode | Install corresponding editor |

### Local Development

```bash
# Clone the project
git clone https://github.com/your-username/ai-devcopilot.git
cd ai-devcopilot

# Install to local editor (development mode)
./install.sh -e claude

# Build and validate multi-editor artifacts
bash scripts/build-dist.sh
bash scripts/validate-dist.sh
bash scripts/check-registry.sh
bash scripts/check-install-targets.sh
bash scripts/smoke-dev-flow.sh

# Test modifications
# Edit files in skills directory
# Restart editor to test
```

```powershell
# Windows installer validation
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor all -ValidateOnly -Yes
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetProject . -Editor all -DryRun -Yes
```

## Code Standards

### Shell Script Standards

1. **Use ShellCheck**: Ensure scripts pass ShellCheck validation
   ```bash
   shellcheck install.sh
   ```

2. **Follow Google Shell Style Guide**:
   - Use 2-space indentation
   - Functions use lowercase letters and underscores
   - Variables use uppercase letters and underscores
   - Add comments for complex logic

3. **Error Handling**:
   ```bash
   set -e  # Exit immediately on error
   set -u  # Error on undefined variables
   set -o pipefail  # Error on pipe command failure
   ```

### Skills Documentation Standards

1. **File Structure**:
   ```
   skills/ai-devcopilot/
   ├── atoms/
   │   └── category/
   │       └── skill-name/
   │           └── SKILL.md
   ├── composites/
   │   └── workflow-name/
   │       └── skill-name/
   │           └── SKILL.md
   └── pipelines/
       └── pipeline-name/
           └── SKILL.md
   ```

2. **SKILL.md Format**:
   ```markdown
   # Skill Name
   
   ## Description
   Brief description of the skill's functionality
   
   ## Trigger Conditions
   List conditions or commands that trigger the skill
   
   ## Execution Steps
   1. First step
   2. Second step
   ...
   
   ## Configuration Requirements
   List required configuration items
   
   ## Examples
   Provide usage examples
   ```

## Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/en/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation update
- `style`: Code formatting (no logic changes)
- `refactor`: Refactoring (neither fix nor feature)
- `perf`: Performance improvement
- `test`: Adding or modifying tests
- `chore`: Build process or auxiliary tool changes
- `ci`: CI configuration changes
- `revert`: Revert commit

### Scope

Optional, indicates the scope of impact:

- `install`: Installation script
- `skills`: Skills related
- `config`: Configuration related
- `docs`: Documentation related

### Examples

```
feat(skills): Add code review skill

- Add code-review skill
- Support automatic code style checking
- Integrate security vulnerability scanning

Closes #123
```

```
fix(install): Fix macOS installation path issue

Fix path parsing error when using zsh on macOS

Fixes #456
```

## Branch Management

### Branch Naming Convention

```
feat/{issue-id}-{description}      # New feature
fix/{issue-id}-{description}       # Bug fix
hotfix/{issue-id}-{description}    # Emergency fix
refactor/{issue-id}-{description}  # Refactoring
docs/{description}                 # Documentation update
chore/{description}                # Tooling or configuration maintenance
```

Examples:
- `feat/123-add-docker-support`
- `fix/456-install-path-error`
- `docs/update-readme`

### Branch Strategy

- `main` or the team-agreed stable baseline branch: stable code
- `feat/*`: Feature branches
- `fix/*`: Fix branches
- `hotfix/*`: Emergency fix branches
- `refactor/*`: Refactoring branches

## Pull Request Process

### PR Title

Use the same format as commit messages:

```
feat(skills): Add code review skill
```

### PR Description

Use the provided PR template, including:

1. **Change Description**: Brief description of changes
2. **Change Type**: New feature/fix/documentation/refactor, etc.
3. **Related Issues**: Associated Issue numbers
4. **Testing**: How it was tested
5. **Screenshots**: If there are UI changes, provide screenshots
6. **Checklist**: Ensure all check items are completed

### Code Review

1. **Reviewers**: At least one maintainer review required
2. **Automated Checks**: Ensure all CI checks pass
3. **Modification Feedback**: Make changes based on review comments
4. **Merge**: Merged by maintainer after review approval

## Version Release

We use [Semantic Versioning](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible functionality additions
- **PATCH**: Backward-compatible bug fixes

### Release Process

1. Update `CHANGELOG.md`
2. Update version number (in README.md)
3. Create Git tag:
   ```bash
   git tag -a v1.4.0 -m "Release version 1.4.0"
   git push origin v1.4.0
   ```
4. Create Release on GitHub

## Getting Help

If you encounter problems during the contribution process, you can get help through:

- **Issues**: Submit problems or suggestions
- **Discussions**: Participate in project discussions
- **Contact Maintainers**: Directly contact project maintainers

## Acknowledgments

Thanks to all contributors who have helped with the AI DevCopilot project!

---

**Last Updated**: 2026-03-20