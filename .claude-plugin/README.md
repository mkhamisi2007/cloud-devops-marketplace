# Cloud DevOps Plugin Marketplace

A private marketplace for Claude Code plugins that enforce infrastructure standards and enable DevOps diagnostics.

## Overview

The Cloud DevOps Plugin Marketplace provides three complementary, independently installable plugins for DevOps teams:

- **terraform-standards**: Enforce Terraform code standards (tagging, naming, encryption)
- **k8s-troubleshooter**: Diagnose Kubernetes pod failures and validate manifest best practices
- **aws-security-review**: Flag overly permissive AWS configurations

Each plugin can be installed and used independently without requiring others.

## Available Plugins

### 1. terraform-standards

**Purpose**: Prevent Terraform infrastructure misconfiguration before deployment.

**Features**:
- Enforce mandatory tags (Environment, Owner) on all resources
- Validate kebab-case naming convention
- Ensure encryption on storage resources (S3, EBS)
- Block commits containing hardcoded credentials
- Pre-apply checklist command for validation

**Installation**: See `plugins/terraform-standards/README.md`

**Quick Start**:
```bash
# Install the plugin
cp -r plugins/terraform-standards ~/.claude/plugins/

# Run checklist on Terraform files
claude code run terraform-standards pre-apply-checklist ./terraform/

# Hook will automatically block commits with credentials
git commit -m "Update infrastructure"
```

---

### 2. k8s-troubleshooter

**Purpose**: Rapidly diagnose Kubernetes pod failures and validate manifest best practices.

**Features**:
- Interactive agent for diagnosing pod failures (CrashLoopBackOff, Pending, OOMKilled)
- Skill for validating Deployment manifests against CKA best practices
- Suggests remediation steps for identified issues
- Enforces resource requests/limits and health probes

**Installation**: See `plugins/k8s-troubleshooter/README.md`

**Quick Start**:
```bash
# Install the plugin
cp -r plugins/k8s-troubleshooter ~/.claude/plugins/

# Diagnose pod failures
kubectl describe pods | claude code run k8s-troubleshooter k8s-diagnosis

# Validate manifests
claude code run k8s-troubleshooter manifest-validator deployment.yaml
```

---

### 3. aws-security-review

**Purpose**: Automatically flag risky AWS resource configurations.

**Features**:
- Identify overly permissive IAM policies (Action: "*", Resource: "*")
- Flag S3 buckets with public read/write access
- Report security groups allowing unrestricted access on sensitive ports
- Suggest least-privilege remediation

**Installation**: See `plugins/aws-security-review/README.md`

**Quick Start**:
```bash
# Install the plugin
cp -r plugins/aws-security-review ~/.claude/plugins/

# Review IAM policy
claude code run aws-security-review iam-policy-reviewer policy.json

# Review S3 bucket configuration
claude code run aws-security-review iam-policy-reviewer bucket-policy.json
```

---

## Installation

### Prerequisites

- Claude Code CLI or Claude Code VS Code extension
- Git 2.0+ (for terraform-standards commit hook)
- kubectl (for k8s-troubleshooter)
- Basic familiarity with DevOps tools

### Install Individual Plugins

Each plugin can be installed independently:

```bash
# Clone or download the marketplace
git clone https://github.com/yourorg/cloud-devops-marketplace.git

# Install terraform-standards
cp -r cloud-devops-marketplace/plugins/terraform-standards ~/.claude/plugins/

# Install k8s-troubleshooter
cp -r cloud-devops-marketplace/plugins/k8s-troubleshooter ~/.claude/plugins/

# Install aws-security-review
cp -r cloud-devops-marketplace/plugins/aws-security-review ~/.claude/plugins/
```

### Verify Installation

```bash
# Check that plugins are discoverable
ls ~/.claude/plugins/terraform-standards/
ls ~/.claude/plugins/k8s-troubleshooter/
ls ~/.claude/plugins/aws-security-review/
```

---

## Troubleshooting

### Plugin not found

- Verify the plugin directory exists: `ls ~/.claude/plugins/`
- Check that the `.claude-plugin/plugin.json` file is present in the plugin directory
- Restart Claude Code after installing

### Command/Agent/Skill not recognized

- Ensure the plugin is installed to the correct Claude Code directory
- Verify that `.claude-plugin/plugin.json` contains the correct entrypoint names
- Check Claude Code documentation for your version

### git hook not running (terraform-standards)

- Verify pre-commit hook is installed: `ls -la .git/hooks/pre-commit`
- Check file permissions: `chmod +x .git/hooks/pre-commit`
- Run hook manually to test: `./.git/hooks/pre-commit`

### kubectl command not found (k8s-troubleshooter)

- Install kubectl: `brew install kubernetes-cli` (macOS) or `apt install kubectl` (Linux)
- Verify: `kubectl version --client`
- Add to PATH if necessary

### Performance issues

- For terraform-standards: Verify Terraform files are valid HCL2 syntax
- For k8s-troubleshooter: Provide representative subset of kubectl output if full output is very large
- For aws-security-review: Large IAM policies with 100+ statements may take longer to analyze

---

## Documentation

For detailed documentation, see:

- **Marketplace Architecture**: `docs/ARCHITECTURE.md`
- **Setup Guide**: `.specify/SETUP.md`
- **Plugin Contracts**: `specs/001-plugin-marketplace/contracts/`
- **Quickstart & Validation**: `specs/001-plugin-marketplace/quickstart.md`

---

## Support

For issues, feature requests, or contributions:

1. Check the plugin-specific README and troubleshooting section
2. Review the quickstart guide for validation scenarios
3. Consult the architecture documentation for design decisions
4. Open an issue with specific error messages and context

---

## License

[To be specified - recommend MIT or Apache 2.0 for DevOps tools]

## Version

**Marketplace Version**: 1.0.0  
**Last Updated**: 2026-06-22
