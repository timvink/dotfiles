---
name: pre-commit
description: When setting up automated code quality checks on git commit. When project has .pre-commit-config.yaml. When implementing git hooks for formatting, linting, or validation. When creating prepare-commit-msg hooks to modify commit messages. When distributing a tool as a pre-commit hook.
---

# Pre-commit Framework

Configure and implement git hooks using pre-commit or prek for automated code quality checks, formatting, linting, and commit message processing across multi-language projects.

## Alternative: prek

Always use **prek**, a Rust-based reimplementation of pre-commit that offers:

- Faster execution (Rust vs Python)
- No Python dependency required
- **Drop-in replacement**: Uses same `.pre-commit-config.yaml` file
- **Identical CLI interface**: All commands work the same way

**Installation**:

```bash
# Using uv (recommended)
uv tool install prek

# Using pip
pip install prek

# Using cargo
cargo install prek
```

**Detection**: To determine which tool is installed in a repository, read `.git/hooks/pre-commit` (second line):

- Contains "pre-commit.com" → pre-commit is installed
- Contains "github.com/j178/prek" → prek is installed

**Throughout this skill**: Commands shown with `pre-commit` work identically with `prek`. Simply replace `pre-commit` with `prek` in any command.

## When to Use This Skill

Use this skill when:

- Setting up git hooks for code quality automation
- Implementing commit message validation or rewriting workflows
- Configuring pre-commit hooks for formatting tools (black, prettier, etc.)
- Creating custom hooks for project-specific quality checks
- Installing hooks for prepare-commit-msg stage (message modification)
- Troubleshooting hook installation or execution issues
- Designing hook definitions for distribution in tool repositories
- Managing hook stages and execution order

## Core Concepts

### Hook Stages

Pre-commit supports multiple git hook stages matching git hook names directly:

| Stage                | Purpose                     | Common Use Cases                  |
| -------------------- | --------------------------- | --------------------------------- |
| `pre-commit`         | Before commit creation      | Code formatting, linting, tests   |
| `prepare-commit-msg` | Before message editor opens | **Commit message rewriting**      |
| `commit-msg`         | After message written       | Message validation only           |
| `pre-push`           | Before push to remote       | Integration tests, security scans |
| `pre-merge-commit`   | Before merge commit         | Merge validation                  |
| `post-checkout`      | After checkout              | Environment setup                 |
| `post-commit`        | After commit created        | Notifications, logging            |
| `post-merge`         | After merge completes       | Dependency updates                |
| `manual`             | Explicit invocation only    | On-demand tasks                   |

### Critical Distinction: prepare-commit-msg vs commit-msg

| Feature                   | prepare-commit-msg                                              | commit-msg            |
| ------------------------- | --------------------------------------------------------------- | --------------------- |
| **Can modify message**    | **Yes**                                                         | No (validation only)  |
| **When it runs**          | Before editor opens                                             | After message written |
| **Environment variables** | `PRE_COMMIT_COMMIT_MSG_SOURCE`, `PRE_COMMIT_COMMIT_OBJECT_NAME` | None                  |
| **Use for**               | Rewriting, formatting                                           | Validation, rejection |

**For commit message rewriting:** Use `prepare-commit-msg` stage.

**For commit message validation:** Use `commit-msg` stage with tools like commitlint.

Skill(command: "conventional-commits")
```

## Installation

### Install pre-commit or prek Tool

**pre-commit (Python-based)**:

```bash
# Using uv (recommended)
uv tool install pre-commit

# Using pip
pip install pre-commit

# Verify installation
pre-commit --version
```

**prek (Rust-based alternative)**:

```bash
# Using uv (recommended)
uv tool install prek

# Using pip
pip install prek

# Using cargo
cargo install prek

# Verify installation
prek --version
```

### Install Hooks in Repository

```bash
# Using pre-commit:
# Install default hook type (pre-commit stage only)
pre-commit install

# Install specific hook type (required for prepare-commit-msg)
pre-commit install --hook-type prepare-commit-msg

# Install multiple hook types
pre-commit install --hook-type pre-commit --hook-type prepare-commit-msg

# Install and setup environments immediately
pre-commit install --install-hooks

# Overwrite existing hooks
pre-commit install --overwrite

# Using prek (same commands, just replace 'pre-commit' with 'prek'):
prek install
prek install --hook-type prepare-commit-msg
# ... etc
```

### Configure Default Hook Types

To install `prepare-commit-msg` automatically with `pre-commit install` or `prek install`:

```yaml
# .pre-commit-config.yaml
default_install_hook_types: [pre-commit, prepare-commit-msg]
```

## Configuration Files

### .pre-commit-config.yaml (User Repository)

Place in repository root to configure which hooks to use.

#### Essential Properties

| Property                     | Type | Default        | Purpose                         |
| ---------------------------- | ---- | -------------- | ------------------------------- |
| `repos`                      | list | Required       | Repository mappings             |
| `default_install_hook_types` | list | `[pre-commit]` | Hook types installed by default |
| `default_stages`             | list | all stages     | Default stages for hooks        |
| `fail_fast`                  | bool | `false`        | Stop on first hook failure      |

#### Repository Mapping

```yaml
repos:
  - repo: https://github.com/org/tool
    rev: v1.0.0  # Use immutable ref (tag or SHA)
    hooks:
      - id: hook-name
        stages: [prepare-commit-msg]
        args: [--option, value]
```

#### Hook Configuration Properties

| Property         | Type   | Purpose                            |
| ---------------- | ------ | ---------------------------------- |
| `id`             | string | Hook ID from repository (required) |
| `stages`         | list   | Override hook stages               |
| `args`           | list   | Additional arguments               |
| `files`          | regex  | File pattern to match              |
| `exclude`        | regex  | File pattern to exclude            |
| `types`          | list   | File types (AND logic)             |
| `always_run`     | bool   | Run even without matching files    |
| `pass_filenames` | bool   | Pass staged files to hook          |
| `verbose`        | bool   | Force output on success            |

#### Example Configuration

```yaml
# .pre-commit-config.yaml
default_install_hook_types: [pre-commit, prepare-commit-msg]

repos:
  # Standard code quality hooks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml

  # Python formatting
  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black
        language_version: python3.11

  # Commit message processing
  - repo: https://github.com/your-org/commit-polish
    rev: v1.0.0
    hooks:
      - id: commit-polish
        stages: [prepare-commit-msg]
```

### .pre-commit-hooks.yaml (Hook Definition)

Place in hook repository to define available hooks for distribution.

#### Hook Definition Schema

| Property                     | Type   | Required            | Purpose                            |
| ---------------------------- | ------ | ------------------- | ---------------------------------- |
| `id`                         | string | **Yes**             | Unique hook identifier             |
| `name`                       | string | **Yes**             | Display name during execution      |
| `entry`                      | string | **Yes**             | Command to execute                 |
| `language`                   | string | **Yes**             | Hook language (python, node, etc.) |
| `stages`                     | list   | No                  | Git hooks to run for               |
| `pass_filenames`             | bool   | No (default: true)  | Pass staged files to hook          |
| `always_run`                 | bool   | No (default: false) | Run without matching files         |
| `files`                      | regex  | No                  | Pattern of files to run on         |
| `exclude`                    | regex  | No                  | Pattern to exclude                 |
| `types`                      | list   | No                  | File types (AND logic)             |
| `description`                | string | No                  | Hook description                   |
| `minimum_pre_commit_version` | string | No                  | Minimum pre-commit version         |

#### Example Hook Definition

```yaml
# .pre-commit-hooks.yaml
- id: commit-polish
  name: Polish Commit Message
  description: Rewrites commit messages to conventional format using LLM
  entry: commit-polish
  language: python
  stages: [prepare-commit-msg]
  pass_filenames: false  # Hook receives message file path
  always_run: true       # Run even without file changes
  minimum_pre_commit_version: '3.2.0'
```

## Implementing prepare-commit-msg Hooks

### Hook Arguments

The `prepare-commit-msg` hook receives:

1. **Positional argument** (`sys.argv[1]`): Path to commit message file (`.git/COMMIT_EDITMSG`)

2. **Environment variables**:
   - `PRE_COMMIT_COMMIT_MSG_SOURCE`: Message source (`message`, `template`, `merge`, `squash`, `commit`)
   - `PRE_COMMIT_COMMIT_OBJECT_NAME`: Commit SHA (for amend operations)

