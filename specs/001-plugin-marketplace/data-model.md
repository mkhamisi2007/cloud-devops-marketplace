# Data Model: Cloud DevOps Plugin Marketplace

**Phase**: 1 Design  
**Date**: 2026-06-22

## Entity Overview

This document defines the core entities, their attributes, relationships, and lifecycle states in the marketplace.

---

## 1. Marketplace Entity

**Definition**: The registry and container for all available plugins.

**Attributes**:
| Attribute | Type | Description | Validation Rules |
|-----------|------|-------------|------------------|
| `name` | string | Marketplace name | Required; min 3 chars; kebab-case |
| `description` | string | Purpose and overview | Required; English language |
| `version` | string | Marketplace version | Semantic version (X.Y.Z) |
| `plugins` | array[PluginReference] | Available plugins in registry | At least 1 plugin |
| `created` | ISO 8601 date | Registry creation date | Auto-generated |
| `updated` | ISO 8601 date | Last update date | Auto-updated |

**Example** (`.claude-plugin/marketplace.json`):
```json
{
  "name": "cloud-devops-marketplace",
  "description": "Private marketplace for DevOps plugins",
  "version": "1.0.0",
  "plugins": [
    {
      "id": "terraform-standards",
      "version": "1.0.0",
      "path": "plugins/terraform-standards"
    },
    // ... more plugins
  ]
}
```

---

## 2. Plugin Entity

**Definition**: A standalone, independently installable Claude Code extension.

**Attributes**:
| Attribute | Type | Description | Validation Rules |
|-----------|------|-------------|------------------|
| `id` | string | Unique plugin identifier | Required; kebab-case; unique in marketplace |
| `name` | string | User-readable plugin name | Required; English |
| `description` | string | What the plugin does | Required; English; <= 200 chars |
| `version` | string | Plugin semantic version | Semantic version (X.Y.Z); independent of other plugins |
| `author` | string | Plugin maintainer(s) | Required |
| `entrypoints` | object | Commands, agents, skills, hooks | At least 1 entrypoint |
| `documentation` | PluginDocumentation | README, guides, examples | Required |

**Example** (`.claude-plugin/plugin.json` in `plugins/terraform-standards/`):
```json
{
  "id": "terraform-standards",
  "name": "Terraform Standards",
  "description": "Enforce tagging, naming, and encryption in Terraform code",
  "version": "1.0.0",
  "author": "DevOps Team",
  "entrypoints": {
    "commands": ["pre-apply-checklist"],
    "hooks": ["commit-credential-blocker"]
  },
  "documentation": {
    "readme": "README.md",
    "guides": ["INSTALLATION.md"],
    "examples": ["examples/"]
  }
}
```

---

## 3. Command Entity

**Definition**: A Claude Code command that users invoke to perform plugin actions.

**Attributes**:
| Attribute | Type | Description | Validation Rules |
|-----------|------|-------------|------------------|
| `id` | string | Command identifier | Required; kebab-case |
| `name` | string | User-readable command name | Required; English |
| `description` | string | What the command does | Required; English |
| `input_type` | enum | What user provides | "file", "text", "manifest", "policy" |
| `output_format` | enum | Response format | "markdown", "json", "plain-text" |
| `examples` | array[string] | Usage examples | At least 1 example |

**Example** (`commands/pre-apply-checklist.md`):
```markdown
# pre-apply-checklist

Validate Terraform files before applying to ensure they meet tagging, naming, and encryption standards.

**Input**: Path to .tf files or directory containing Terraform code  
**Output**: List of violations with remediation suggestions  
**Exit Code**: 0 if all checks pass; non-zero if violations found
```

---

## 4. Agent Entity

**Definition**: A Claude Code agent that interactively diagnoses or analyzes input.

**Attributes**:
| Attribute | Type | Description | Validation Rules |
|-----------|------|-------------|------------------|
| `id` | string | Agent identifier | Required; kebab-case |
| `name` | string | User-readable agent name | Required; English |
| `description` | string | What the agent diagnoses | Required; English |
| `input_description` | string | What user provides | Required; specific (e.g., "kubectl output") |
| `reasoning_approach` | string | How agent analyzes input | Required; explains multi-step logic |
| `output_format` | string | Response structure | Required (markdown, structured JSON) |

**Example** (`agents/k8s-diagnosis.md`):
```markdown
# k8s-diagnosis

Analyzes kubectl output to diagnose pod failures and suggest remediation.

**Input**: kubectl output (describe pods, get events, logs)  
**Reasoning**: 
1. Parse pod states (CrashLoopBackOff, Pending, OOMKilled)
2. Extract conditions and events
3. Hypothesize root cause (resource, probe, affinity, etc.)
4. Suggest remediation

**Output**: Markdown report with diagnosis and action items
```

---

## 5. Skill Entity

**Definition**: A Claude Code skill that validates, reviews, or analyzes configurations.

**Attributes**:
| Attribute | Type | Description | Validation Rules |
|-----------|------|-------------|------------------|
| `id` | string | Skill identifier | Required; kebab-case |
| `name` | string | User-readable skill name | Required; English |
| `description` | string | What the skill validates/reviews | Required; English |
| `input_type` | string | Configuration type analyzed | "terraform", "kubernetes", "iam-policy", "s3-bucket", etc. |
| `validation_rules` | array[string] | Rules enforced | At least 1 rule |
| `error_handling` | string | How skill handles violations | "flag" (report), "block" (fail), "warn" |

**Example** (`skills/manifest-validator.md`):
```markdown
# manifest-validator

Validates Kubernetes Deployment manifests against CKA best practices.

**Rules Enforced**:
- Resource requests and limits defined on all containers
- Liveness and readiness probes configured
- Images use specific tags (no "latest")
- RBAC enabled; no cluster-admin bindings

**Error Handling**: Flag violations and suggest fixes
```

---

## 6. Hook Entity

**Definition**: An automation script triggered by system events (e.g., git commit).

**Attributes**:
| Attribute | Type | Description | Validation Rules |
|-----------|------|-------------|------------------|
| `id` | string | Hook identifier | Required; kebab-case |
| `event` | enum | When hook triggers | "pre-commit", "post-commit", "pre-push" |
| `action` | enum | What hook does | "block" (fail event), "warn" (log), "log" (info only) |
| `validation_rules` | array[string] | What hook checks | At least 1 rule |
| `error_message` | string | Message when hook blocks | Required; clear and actionable |
| `recovery_instructions` | string | How user fixes violation | Required per constitution Principle III |

**Example** (`hooks/hooks.json` in `plugins/terraform-standards/`):
```json
{
  "hooks": [
    {
      "id": "commit-credential-blocker",
      "event": "pre-commit",
      "action": "block",
      "validation_rules": [
        "No AWS_ACCESS_KEY_ID",
        "No AWS_SECRET_ACCESS_KEY",
        "No hardcoded passwords",
        "No private keys"
      ],
      "error_message": "Credentials detected in Terraform files. Remove before committing.",
      "recovery_instructions": "1. Remove credentials from .tf files\n2. Use AWS provider variables or assume role\n3. Retry commit"
    }
  ]
}
```

---

## 7. Plugin Documentation Entity

**Definition**: Documentation accompanying each plugin.

**Attributes**:
| Attribute | Type | Description | Validation Rules |
|-----------|------|-------------|------------------|
| `readme` | file | Installation, overview, quick-start | Required; Markdown; English |
| `configuration_guide` | file | Config options, environment variables | If applicable; Markdown; English |
| `examples` | directory | Runnable examples for each command/skill/agent | Required; >= 1 per entrypoint |
| `troubleshooting` | file | Common issues and solutions | Required; Markdown; English |

---

## Relationships

```
Marketplace (1) ─── (N) Plugins
    ↓
Plugin (1) ──── (N) Entrypoints
    ├── (N) Commands
    ├── (N) Agents
    ├── (N) Skills
    └── (N) Hooks

Entrypoint (1) ─── (1) Documentation
Entrypoint (1) ─── (N) Examples
```

---

## Validation Rules

### Cross-Entity Rules

1. **Plugin Independence**: 
   - No plugin may import code from another plugin
   - Plugins may reference each other's documentation or outputs but not directly call code
   - Each plugin has separate manifest, versioning, and installation

2. **Documentation Consistency**:
   - All user-facing text must be in English (per constitution)
   - All commands/agents/skills must have examples
   - All hooks must have clear error messages and recovery instructions

3. **Naming Conventions**:
   - Plugin IDs: `kebab-case`
   - Command/Agent/Skill/Hook IDs: `kebab-case`
   - Files: `lowercase-with-dashes.md`
   - JSON keys: `camelCase`

4. **Version Management**:
   - Plugins use semantic versioning (X.Y.Z) independently
   - Marketplace version increments when plugins are added/removed
   - Plugin versions do not need to align

5. **Hook Requirements** (per constitution Principle III):
   - Every hook must log its action (what was checked)
   - Every blocking hook must log why it blocked (rule violated)
   - Every blocking hook must log how to fix (recovery instructions)

---

## State Transitions

Plugins are stateless; they do not maintain persistent state. All analysis is deterministic based on input:

```
User Input
    ↓
Plugin (Command/Agent/Skill/Hook)
    ↓
Analysis (deterministic rules)
    ↓
Output (violations, recommendations, diagnostics)
```

No state is carried between invocations.

---

## Assumptions & Constraints

- **No database**: Plugins store no state; markdown/JSON files only
- **No configuration profiles**: Rules are built into plugins (not user-configurable in v1)
- **No inter-plugin communication**: Each plugin operates independently; output of one may inform user action in another, but no direct calls
- **English-only**: All documentation, examples, error messages in English
- **No external services**: All analysis happens locally with provided data
