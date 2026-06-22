# Cloud DevOps Plugin Marketplace - Architecture

**Version**: 1.0.0  
**Last Updated**: 2026-06-22

## Design Philosophy

The marketplace is built on five core principles:

1. **Plugin Independence**: Each plugin is independently installable, with no dependencies on other marketplace plugins
2. **English Documentation**: All user-facing documentation and examples are written in English
3. **Hooks Must Log Clearly**: All hooks log clear, actionable messages when blocking actions
4. **Terraform Well-Architected**: Terraform standards align with AWS Well-Architected Framework Security Pillar
5. **Kubernetes CKA Compliance**: Kubernetes validation follows Certified Kubernetes Administrator best practices

---

## Architecture Overview

### High-Level Structure

```
cloud-devops-marketplace/
├── .claude-plugin/                  # Marketplace registry
│   ├── marketplace.json             # Plugin metadata and discovery
│   └── README.md                    # Installation guide
│
├── plugins/                         # Individual plugins
│   ├── terraform-standards/         # Terraform enforcement plugin
│   │   ├── .claude-plugin/          # Plugin manifest
│   │   ├── commands/                # CLI commands
│   │   ├── hooks/                   # Git hooks
│   │   ├── examples/                # Example Terraform files
│   │   └── README.md                # Plugin documentation
│   │
│   ├── k8s-troubleshooter/         # Kubernetes diagnostics plugin
│   │   ├── .claude-plugin/          # Plugin manifest
│   │   ├── agents/                  # Diagnostic agents
│   │   ├── skills/                  # Validation skills
│   │   ├── examples/                # Example manifests
│   │   └── README.md                # Plugin documentation
│   │
│   └── aws-security-review/         # AWS security plugin
│       ├── .claude-plugin/          # Plugin manifest
│       ├── skills/                  # Review skills
│       ├── examples/                # Example configurations
│       └── README.md                # Plugin documentation
│
├── docs/                            # Marketplace documentation
│   └── ARCHITECTURE.md              # This file
│
└── specs/                           # Feature specifications
    └── 001-plugin-marketplace/      # Feature design artifacts
        ├── spec.md                  # Requirements & acceptance criteria
        ├── plan.md                  # Implementation strategy
        ├── tasks.md                 # Implementation tasks
        ├── data-model.md            # Entity definitions
        ├── contracts/               # Plugin interface specs
        ├── research.md              # Design decisions
        └── quickstart.md            # Validation scenarios
```

---

## Plugin Architecture

Each plugin is a self-contained Claude Code extension with:

### 1. Plugin Manifest (`.claude-plugin/plugin.json`)

Defines plugin metadata, entrypoints, and documentation paths:

```json
{
  "id": "terraform-standards",
  "name": "Terraform Standards",
  "version": "1.0.0",
  "entrypoints": {
    "commands": ["pre-apply-checklist"],
    "hooks": ["commit-credential-blocker"]
  }
}
```

### 2. Entrypoints

Plugins expose functionality through three types of entrypoints:

#### Commands
- User-triggered CLI commands
- Example: `terraform-standards pre-apply-checklist`
- Input: File paths or text
- Output: Markdown reports with findings

#### Agents
- Interactive, multi-step reasoning tools
- Example: `k8s-troubleshooter k8s-diagnosis`
- Input: Unstructured text (kubectl output)
- Output: Diagnostic suggestions with remediation

#### Skills
- Deterministic validation/review tools
- Example: `k8s-troubleshooter manifest-validator`
- Input: Structured configuration (manifests, policies)
- Output: Compliance/security findings

#### Hooks
- Automated scripts triggered by system events
- Example: Git pre-commit hook
- Event: Version control commit
- Action: Block unsafe changes with clear messaging

### 3. Documentation

Each plugin includes:

- **README.md**: Installation, quick-start, usage examples, troubleshooting
- **Examples/**: Sample input files demonstrating plugin features
- **Contract specification**: (in marketplace specs/contracts/) - interface definitions

---

## Design Decisions

### Stateless Analysis Tools

All plugins are stateless—they analyze provided input without maintaining persistent state.

**Rationale**: Simplifies installation, enables CI/CD integration, follows Unix philosophy (do one thing well).

**Trade-off**: Configuration rules are baked into plugin logic, not externalized. Extensibility deferred to v2 if user demand emerges.

### Plugin Independence

Plugins do not depend on each other; they communicate through shared Claude Code infrastructure, not direct code calls.

**Rationale**: Allows independent versioning, isolated deployment, reduced deployment risk.

**Implementation**: Each plugin has separate `.claude-plugin/plugin.json`, manifest, and directory.

### Marketplace Registry

Central `.claude-plugin/marketplace.json` lists all available plugins with metadata.

**Rationale**: Enables discovery without cloning entire repository; supports future automation (installation scripts, version checking).

### Hook-Based Enforcement (terraform-standards)

Pre-commit hook blocks commits with hardcoded credentials; pre-apply command validates other standards.

**Rationale**: Hooks prevent security incidents at earliest point (commit time); commands provide linting-style feedback.

**Logging** (Constitution Principle III):
- Every blocked commit logs: what rule was violated, why, and how to fix it
- Example: "Credentials detected: AWS_ACCESS_KEY_ID found in terraform/prod/vars.tf. Remove hardcoded key and use environment variables instead."

### Agent + Skill Pattern (k8s-troubleshooter)

Provides two entry points for different workflows:

- **Agent**: Interactive diagnosis for human operators debugging production issues
- **Skill**: Batch validation for CI/CD pre-deployment checks

**Rationale**: Agents excel at multi-step reasoning; skills enable automation. Both serve different DevOps workflows.

### Terraform Well-Architected Alignment

Terraform enforcement rules align with AWS Well-Architected Framework Security Pillar:

- **Data Protection**: Encryption mandatory on storage resources
- **Compliance**: Tagging enforces tracking and cost allocation
- **IAM Principle of Least Privilege**: Blocks credentials that could lead to overly broad access
- **Logging & Monitoring**: Commit hook logs all violations

### Kubernetes CKA Compliance

Manifest validation enforces CKA exam best practices:

- **Resource Management**: Requests/limits prevent resource exhaustion
- **Health & Recovery**: Liveness/readiness probes enable automatic pod recovery
- **Security**: Image versioning prevents unexpected breaking changes
- **RBAC**: Enforced through external policies (not in this plugin but aligned)

---

## Technical Constraints

1. **No External Dependencies**: Plugins use Claude Code and git built-in capabilities only
2. **Cross-Platform**: Plugins must work on macOS, Windows, Linux via Claude Code
3. **No State Management**: All analysis is stateless and deterministic
4. **English Only**: All documentation, examples, error messages in English
5. **Stateless Analysis**: Tools analyze provided data only (no API calls to live AWS/Kubernetes)

---

## Versioning Strategy

### Plugin Versioning

Each plugin uses semantic versioning independently:

- **MAJOR** (X): Breaking changes to input/output format or entrypoint
- **MINOR** (Y): New features or rules added without breaking existing functionality
- **PATCH** (Z): Bug fixes, clarifications, performance improvements

Example: `terraform-standards 1.2.3`, `k8s-troubleshooter 1.0.0`, `aws-security-review 2.1.0`

### Marketplace Versioning

Marketplace version increments when:

- Plugins are added or removed (MINOR)
- Marketplace structure changes (MAJOR if incompatible)
- New documentation or guides added (PATCH)

---

## Deployment & Installation

### Installation Model

Plugins are installed by copying to user's Claude Code configuration directory:

```bash
cp -r plugins/terraform-standards ~/.claude/plugins/terraform-standards
```

**Advantages**:
- No package manager dependency
- Full plugin source transparency
- Easy local development and testing

**Disadvantages**:
- Manual version management (future: implement version checking in installer)
- No automatic updates (user responsibility)

### Hook Setup

terraform-standards commit hook requires user installation:

```bash
cp plugins/terraform-standards/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

---

## Testing & Validation

### Acceptance Testing

Each plugin includes acceptance tests demonstrating key functionality:

- **terraform-standards**: Tag enforcement, naming validation, encryption checks, credential blocking
- **k8s-troubleshooter**: Pod failure diagnosis, manifest validation
- **aws-security-review**: IAM policy review, S3 bucket checking, security group review

### Performance Targets

- **k8s-troubleshooter**: Diagnose typical 10+ pod output in <10 seconds
- **aws-security-review**: Review AWS configuration in <5 minutes
- **terraform-standards**: Check 100-resource Terraform files in <5 seconds

### Integration Testing

Each plugin is independently testable without others installed.

---

## Future Extensibility

### Version 2.0 Candidates

- **Configuration Profiles**: Allow customizing enforcement rules (strict vs. lenient)
- **Rule Caching**: Improve performance by caching analysis results
- **Inter-Plugin Communication**: Enable k8s-troubleshooter to cross-reference Terraform for context
- **Web Dashboard**: Centralized policy and configuration management
- **Automated Remediation**: Not just flagging issues but optionally fixing them

### Design for Extension

Current design supports future extensibility through:

- **Contract-Based Communication**: Each plugin's interface is documented in `specs/contracts/`
- **Stateless Design**: Future plugins can be added without affecting existing ones
- **Configuration Separation**: Rules are distinct from execution logic

---

## Compliance & Governance

### Constitution Compliance

All plugins must adhere to the marketplace constitution (`.specify/memory/constitution.md`):

1. ✅ **Plugin Independence**: Each installable without others
2. ✅ **English Documentation**: All docs in English
3. ✅ **Hooks Log Clearly**: terraform-standards hook provides clear recovery instructions
4. ✅ **Terraform Well-Architected**: Enforcement aligns with AWS security best practices
5. ✅ **Kubernetes CKA**: Validation follows CKA exam standards

### Principle Validation

When adding new plugins or features:

- Verify no cross-plugin hard dependencies
- Ensure all documentation is in English
- For hooks: Verify clear error messages with recovery steps
- For Terraform features: Align with AWS Well-Architected Security Pillar
- For Kubernetes features: Align with CKA exam standards

---

## Glossary

- **Plugin**: A standalone Claude Code extension (commands, agents, skills, or hooks)
- **Marketplace**: Registry of available plugins and their metadata
- **Command**: User-triggered CLI command (e.g., `pre-apply-checklist`)
- **Agent**: Interactive multi-step reasoning tool for human-guided diagnosis
- **Skill**: Deterministic validation or review tool for automation
- **Hook**: Automated script triggered by system events (e.g., git commits)
- **Contract**: Interface specification defining input/output for a plugin component
- **Entrypoint**: Interface through which users interact with plugin (command, agent, skill, hook)

---

## References

- **Marketplace Specification**: `specs/001-plugin-marketplace/spec.md`
- **Implementation Plan**: `specs/001-plugin-marketplace/plan.md`
- **Plugin Contracts**: `specs/001-plugin-marketplace/contracts/`
- **AWS Well-Architected Framework**: https://aws.amazon.com/architecture/well-architected/
- **CKA Exam Guide**: https://www.cncf.io/certification/cka/
