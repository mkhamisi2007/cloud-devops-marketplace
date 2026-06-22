# Research: Cloud DevOps Plugin Marketplace

**Phase**: 0 Research (Design decisions and technical rationale)  
**Date**: 2026-06-22  
**Status**: Complete

## Design Decisions & Rationale

### 1. Plugin Architecture & Independence

**Decision**: Each plugin is a standalone directory with its own `.claude-plugin/plugin.json` manifest, README, and implementation files.

**Rationale**: 
- Aligns with constitution Principle I (Plugin Independence): each plugin can be installed independently
- No shared code or dependencies between plugins reduces coupling
- Users can adopt individual plugins without waiting for others
- Simplifies versioning: each plugin increments independently

**Alternatives Considered**:
- Monolithic codebase with feature flags: Would couple plugins; violates independence principle
- Shared library for common functionality: Might tempt cross-plugin dependencies; deferred to future if pattern emerges

---

### 2. Stateless Analysis Tools

**Decision**: All three plugins are stateless; they analyze provided input (files, text, manifests) without persistent storage or configuration files.

**Rationale**:
- Reduces installation complexity (no config setup)
- Enables easy CI/CD integration (no state to manage)
- Aligns with Unix philosophy: tools do one thing well
- Rules are baked into plugin logic, not external config

**Alternatives Considered**:
- Configuration profiles (e.g., "strict" vs. "lenient" tagging rules): Deferred to v2 if user demand emerges
- Rule caching/learning: Out of scope for marketplace MVP

---

### 3. terraform-standards: Hook + Command Pattern

**Decision**: Two entry points:
- **Hook** (pre-commit): Blocks commits containing hardcoded credentials
- **Command** (pre-apply): Runs checklist validating tags, naming, encryption

**Rationale**:
- Hook prevents security incidents at earliest point (commit time)
- Command provides linting-style feedback before deployment
- Separates concerns: blocking (hook) vs. advisory (command)
- Aligns with constitution Principle III: hooks must log clear reasons when blocking

**Alternatives Considered**:
- Post-commit hook only: Would allow bad code to be committed; weaker security posture
- Command only: Would require developers to remember to run manually; unreliable

---

### 4. k8s-troubleshooter: Agent + Skill Pattern

**Decision**: Two entry points:
- **Agent**: Interactive diagnosis of pod failures from kubectl output
- **Skill**: Manifest validation (enforces resource limits, health probes on Deployments)

**Rationale**:
- Agents excel at multi-step reasoning (state analysis → hypothesis → remediation)
- Skills enable batch validation (pre-deployment checks in CI/CD)
- Separation serves different workflows (DevOps engineer debugging vs. platform team validation)
- Aligns with constitution Principle V: skill enforces CKA best practices

**Alternatives Considered**:
- Single agent only: Would miss CI/CD pre-deployment validation use case
- Single skill only: Would limit interactive diagnostic experience

---

### 5. aws-security-review: Skill Only

**Decision**: Single skill endpoint that reviews provided AWS configurations.

**Rationale**:
- Configuration review is stateless analysis (skill-appropriate)
- No interactive debugging needed (unlike k8s diagnostics)
- Enables easy pipeline integration (CI/CD can invoke skill to audit configurations)
- Aligns with constitution Principle IV: enforces AWS Well-Architected Security Pillar

**Alternatives Considered**:
- Agent for interactive review: Unnecessary complexity; configuration flagging is deterministic
- Multiple skills per policy type: Monolithic skill simpler for users; can be split in v2

---

### 6. Marketplace Registry Structure

**Decision**: Central `.claude-plugin/marketplace.json` lists all available plugins with metadata (name, description, version, installation path).

**Rationale**:
- Users can discover plugins from a single source
- Future automation: installation scripts, version checking, dependency resolution
- Reduces friction for adopters (no need to clone entire repo to use one plugin)

**Alternatives Considered**:
- GitHub Releases for each plugin: Would fragment discovery; requires per-plugin releases
- Implicit registry (infer from directory structure): Less discoverable; no metadata

---

### 7. Documentation Standards

**Decision**: Each plugin has a README.md covering:
- Installation instructions (where to copy files)
- Quick-start example
- Configuration options (if any)
- Troubleshooting (common issues and fixes)

All documentation in English per constitution Principle II.

**Rationale**:
- Consistent structure enables users to find information quickly
- English standardization supports distributed DevOps teams
- Explicit troubleshooting reduces support burden

---

## Technical Constraints & Assumptions

- **Constraint**: No external package dependencies (use Claude Code and git built-in capabilities only)
  - Rationale: Reduces installation friction; easier to maintain
  
- **Constraint**: Plugins must work on macOS, Windows, Linux (via Claude Code cross-platform support)
  - Rationale: DevOps tools must run everywhere; specified in spec assumptions
  
- **Assumption**: Users have git installed (for terraform-standards commit hook)
  - Rationale: Standard in DevOps environments
  
- **Assumption**: Users have kubectl available (for k8s-troubleshooter)
  - Rationale: Required by spec assumption; diagnostic tool cannot work without it
  
- **Assumption**: AWS configurations provided as JSON/YAML exports (not live API calls)
  - Rationale: Simpler, no AWS credentials required in plugin; aligns with "stateless" design

---

## Next Steps

Phase 1 will define:
1. **data-model.md**: Entity structures (plugin configuration, hook manifest, skill/command definitions)
2. **contracts/**: Plugin interface specifications (what each plugin accepts and returns)
3. **quickstart.md**: End-to-end validation scenarios proving marketplace works
