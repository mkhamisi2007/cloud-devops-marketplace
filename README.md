# Cloud DevOps Plugin Marketplace

> A private marketplace for Claude Code plugins that enforce infrastructure standards and enable DevOps diagnostics.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-blue.svg)](CHANGELOG.md)
[![Marketplace Ready](https://img.shields.io/badge/Status-Ready-brightgreen.svg)](#)

## 🚀 Quick Start

Install all three plugins with a few commands:

```bash
# Clone the marketplace
git clone https://github.com/yourusername/cloud-devops-marketplace.git
cd cloud-devops-marketplace

# Install plugins to your Claude Code directory
cp -r plugins/terraform-standards ~/.claude/plugins/
cp -r plugins/k8s-troubleshooter ~/.claude/plugins/
cp -r plugins/aws-security-review ~/.claude/plugins/

# Restart Claude Code and you're ready to go!
```

---

## 📋 What is This?

The Cloud DevOps Plugin Marketplace provides **three independent, powerful plugins** for your Claude Code environment:

1. **terraform-standards** - Enforce Terraform best practices (tagging, naming, encryption)
2. **k8s-troubleshooter** - Diagnose Kubernetes issues and validate manifests
3. **aws-security-review** - Flag overly permissive AWS configurations

Each plugin can be installed and used independently, with no dependencies on the others.

### Why This Marketplace?

- ✅ **Independent Installation**: Install only what you need
- ✅ **Best Practices Enforced**: Align with AWS Well-Architected and CKA standards
- ✅ **Clear Error Messages**: When rules are violated, get actionable guidance
- ✅ **Production-Ready**: Three complementary tools for modern DevOps workflows

---

## 📁 Project Structure

```
cloud-devops-marketplace/
├── README.md                        # This file
├── LICENSE                          # MIT License
│
├── .claude-plugin/                  # Marketplace metadata
│   ├── marketplace.json             # Plugin registry
│   ├── README.md                    # Installation guide
│   └── SETUP.md                     # Detailed setup instructions
│
├── plugins/                         # Individual plugins (install separately)
│   │
│   ├── terraform-standards/         # Terraform enforcement plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json          # Plugin manifest
│   │   ├── commands/
│   │   │   └── pre-apply-checklist.md
│   │   ├── hooks/
│   │   │   └── hooks.json
│   │   ├── examples/                # Example Terraform files
│   │   └── README.md                # Plugin documentation
│   │
│   ├── k8s-troubleshooter/         # Kubernetes diagnostics plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── agents/
│   │   │   └── k8s-diagnosis.md
│   │   ├── skills/
│   │   │   └── manifest-validator.md
│   │   ├── examples/                # Example K8s manifests
│   │   └── README.md                # Plugin documentation
│   │
│   └── aws-security-review/         # AWS security plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/
│       │   └── iam-policy-reviewer.md
│       ├── examples/                # Example AWS configs
│       └── README.md                # Plugin documentation
│
├── docs/
│   └── ARCHITECTURE.md              # Design & technical details
│
└── specs/                           # Feature specifications & design docs
    └── 001-plugin-marketplace/
        ├── spec.md                  # Requirements & acceptance criteria
        ├── plan.md                  # Implementation strategy
        ├── tasks.md                 # Task breakdown
        ├── data-model.md            # Entity definitions
        ├── contracts/               # Plugin interface specs
        ├── research.md              # Design decisions
        └── quickstart.md            # Validation guide
```

---

## 🔧 Installation Guide

### Prerequisites

- **Claude Code** (CLI or VS Code extension)
  - Installation: https://claude.com/code
  - Verify: `claude code --version`

- **Git** (2.0+)
  - macOS: `brew install git`
  - Linux: `sudo apt-get install git`
  - Windows: https://git-scm.com/download/win

- **Optional**: `kubectl` (for k8s-troubleshooter)
  - Installation: https://kubernetes.io/docs/tasks/tools/

### Installation Steps

#### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/cloud-devops-marketplace.git
cd cloud-devops-marketplace
```

#### Step 2: Install Desired Plugins

You can install all plugins or just the ones you need:

```bash
# Option A: Install all plugins
cp -r plugins/terraform-standards ~/.claude/plugins/
cp -r plugins/k8s-troubleshooter ~/.claude/plugins/
cp -r plugins/aws-security-review ~/.claude/plugins/

# Option B: Install individual plugins
cp -r plugins/terraform-standards ~/.claude/plugins/    # Terraform enforcement only
cp -r plugins/k8s-troubleshooter ~/.claude/plugins/    # Kubernetes diagnostics only
cp -r plugins/aws-security-review ~/.claude/plugins/   # AWS security review only
```

#### Step 3: Restart Claude Code

Quit and restart Claude Code to load the newly installed plugins.

#### Step 4: Verify Installation

```bash
# Check that plugins are installed
ls ~/.claude/plugins/

# Should show:
# terraform-standards
# k8s-troubleshooter
# aws-security-review
```

---

## 📖 Using Each Plugin

### 1. terraform-standards

**Enforce Terraform best practices** with automated validation and commit blocking.

#### What It Does

- ✅ Enforces mandatory tags (Environment, Owner) on all resources
- ✅ Validates kebab-case naming convention
- ✅ Ensures encryption on storage resources (S3, EBS)
- ✅ **Blocks commits** containing hardcoded credentials (AWS keys, passwords)
- ✅ Provides pre-apply checklist command for validation

#### Quick Start

```bash
# 1. Install the plugin (see Installation Steps above)

# 2. Run checklist on your Terraform files
cd /path/to/terraform/project
claude code run terraform-standards pre-apply-checklist ./

# 3. Fix any violations reported

# 4. Commit with confidence (hook blocks credentials)
git commit -m "Update infrastructure"
```

#### Features

**Pre-Apply Checklist Command**
```bash
# Validate Terraform files before applying
claude code run terraform-standards pre-apply-checklist ./terraform/

# Output: Markdown report with violations (if any)
# - Missing mandatory tags
# - Naming convention violations
# - Missing encryption
```

**Pre-Commit Hook** (optional setup)
```bash
# Install the git hook in your project
cp plugins/terraform-standards/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Now commits with hardcoded credentials are blocked automatically
```

#### Examples

See `plugins/terraform-standards/examples/` for sample Terraform files showing:
- ✅ Compliant resources (proper tags, encryption, naming)
- ❌ Non-compliant resources (missing tags, wrong naming, no encryption)

#### Documentation

Full details: `plugins/terraform-standards/README.md`

---

### 2. k8s-troubleshooter

**Diagnose Kubernetes issues in seconds** and validate manifest best practices.

#### What It Does

- 🔍 Analyzes kubectl output to diagnose pod failures
- 💡 Suggests root causes for CrashLoopBackOff, Pending, OOMKilled states
- ✅ Validates Deployment manifests against CKA best practices
- 📋 Enforces resource requests/limits and health probes
- 🚀 Provides diagnostics in <10 seconds

#### Quick Start

```bash
# 1. Install the plugin

# 2. Diagnose pod failures (interactive agent)
kubectl describe pods | claude code run k8s-troubleshooter k8s-diagnosis

# Output: Diagnostic suggestions with remediation steps

# 3. Validate a manifest (skill)
claude code run k8s-troubleshooter manifest-validator deployment.yaml

# Output: Report on missing health probes, resource limits, etc.
```

#### Features

**Pod Diagnosis Agent** - Diagnose pod failures interactively
```bash
# Get kubectl output for pods
kubectl describe pods --all-namespaces > pods.txt

# Get diagnostics
cat pods.txt | claude code run k8s-troubleshooter k8s-diagnosis

# Suggestions for:
# - CrashLoopBackOff: Check health probes, environment, startup logs
# - Pending: Check resources available, node affinity, PVC status
# - OOMKilled: Increase memory limits
```

**Manifest Validator Skill** - Validate manifests before deployment
```bash
# Validate a single manifest
claude code run k8s-troubleshooter manifest-validator deployment.yaml

# Validates:
# - Resource requests/limits present
# - Liveness and readiness probes configured
# - Images use specific version tags (no "latest")
```

#### Examples

See `plugins/k8s-troubleshooter/examples/` for:
- ✅ Valid Deployment with resource limits and probes
- ❌ Invalid manifest missing resource limits or probes
- 📋 Sample kubectl outputs for various failure states

#### Documentation

Full details: `plugins/k8s-troubleshooter/README.md`

---

### 3. aws-security-review

**Automatically flag risky AWS configurations** and suggest least-privilege fixes.

#### What It Does

- 🔐 Identifies overly permissive IAM policies (Action: "*", Resource: "*")
- 🪣 Flags S3 buckets with public read/write access
- 🔓 Reports security groups allowing unrestricted access on sensitive ports
- 💡 Suggests least-privilege remediation for each issue
- ⚡ Reviews configurations in <5 minutes

#### Quick Start

```bash
# 1. Install the plugin

# 2. Review an IAM policy
claude code run aws-security-review iam-policy-reviewer policy.json

# Output: Flags overly permissive patterns, suggests fixes

# 3. Review S3 bucket configuration
claude code run aws-security-review iam-policy-reviewer bucket-policy.json

# Output: Flags public access, suggests restrictions
```

#### Features

**IAM Policy Review**
```bash
# Review an IAM policy for overly permissive patterns
claude code run aws-security-review iam-policy-reviewer iam-policy.json

# Flags:
# - Action: "*" without scope → Suggest specific actions
# - Resource: "*" without conditions → Suggest specific resources
# - Principal: "*" in trust policies → Suggest specific principals
```

**S3 Bucket Configuration Review**
```bash
# Review S3 bucket policy
claude code run aws-security-review iam-policy-reviewer bucket-policy.json

# Flags:
# - Public read access (Principal: "*")
# - Public write access
# - Missing Block Public Access settings
```

**Security Group Review**
```bash
# Review security group configuration
claude code run aws-security-review iam-policy-reviewer security-group.json

# Flags:
# - SSH (port 22) from 0.0.0.0/0
# - Databases (3306, 5432) from anywhere
# - Accepts HTTP/HTTPS (80, 443) from anywhere (OK)
```

#### Examples

See `plugins/aws-security-review/examples/` for:
- ❌ Overly permissive IAM policy with Action: "*"
- ✅ Fixed IAM policy with specific scopes
- ❌ Public S3 bucket and how to remediate
- ❌ Unrestricted security group access

#### Documentation

Full details: `plugins/aws-security-review/README.md`

---

## 🎯 Common Workflows

### Workflow 1: Pre-Deployment Infrastructure Validation

```bash
# 1. Validate Terraform configuration
cd terraform/
claude code run terraform-standards pre-apply-checklist ./

# 2. Fix any violations
# 3. Apply Terraform
terraform apply

# 4. Validate resulting Kubernetes manifests
cd ../kubernetes/
claude code run k8s-troubleshooter manifest-validator deployment.yaml

# 5. Review IAM policies for security
cd ../iam/
claude code run aws-security-review iam-policy-reviewer service-role-policy.json

# 6. Deploy with confidence!
```

### Workflow 2: Production Troubleshooting

```bash
# Pod is misbehaving? Get instant diagnostics
kubectl describe pods --all-namespaces | \
  claude code run k8s-troubleshooter k8s-diagnosis

# Output gives you:
# - Root cause analysis
# - Specific remediation steps
# - Expected outcome after fixes

# Result: Faster incident resolution, happier DevOps team
```

### Workflow 3: Security Audit

```bash
# Export current AWS configuration
aws iam get-role-policy --role-name MyRole --policy-name MyPolicy \
  --query 'RolePolicyDocument' > policy.json

# Review for security issues
claude code run aws-security-review iam-policy-reviewer policy.json

# Get compliance report with fixes
```

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **README.md** (this file) | Project overview and quick start |
| **.claude-plugin/README.md** | Marketplace installation guide |
| **.claude-plugin/SETUP.md** | Detailed setup & prerequisites |
| **docs/ARCHITECTURE.md** | Design philosophy & technical architecture |
| **plugins/*/README.md** | Plugin-specific documentation |
| **specs/001-plugin-marketplace/spec.md** | Requirements & acceptance criteria |
| **specs/001-plugin-marketplace/quickstart.md** | Validation & integration scenarios |

---

## 🆘 Troubleshooting

### Plugin Not Found

```bash
# Verify plugin is installed
ls ~/.claude/plugins/terraform-standards/

# If missing, reinstall:
cp -r plugins/terraform-standards ~/.claude/plugins/

# Restart Claude Code
```

### Command Not Recognized

```bash
# Verify plugin.json exists and has correct entrypoints
cat ~/.claude/plugins/terraform-standards/.claude-plugin/plugin.json

# Restart Claude Code if you just installed the plugin
```

### Git Hook Not Working

```bash
# Verify hook is installed and executable
ls -la .git/hooks/pre-commit

# Make executable if needed
chmod +x .git/hooks/pre-commit

# Test hook manually
./.git/hooks/pre-commit
```

### kubectl Connection Fails

```bash
# Verify kubectl is installed
which kubectl

# Verify cluster connectivity
kubectl cluster-info

# Ensure KUBECONFIG is set
echo $KUBECONFIG
```

For more help, see individual plugin README files or **SETUP.md** for comprehensive troubleshooting.

---

## 🤝 Contributing

We welcome contributions! To contribute:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/new-plugin`)
3. **Commit** your changes (`git commit -am 'Add new feature'`)
4. **Push** to the branch (`git push origin feature/new-plugin`)
5. **Open** a Pull Request

Please ensure:
- All code follows the existing style
- Documentation is in English
- Plugin changes don't break existing functionality

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🎓 Learn More

- **Marketplace Architecture**: See `docs/ARCHITECTURE.md` for design decisions
- **Plugin Contracts**: See `specs/001-plugin-marketplace/contracts/` for interface specs
- **Design Documents**: See `specs/001-plugin-marketplace/` for full specifications

---

## 🔗 Links

- **Claude Code**: https://claude.com/code
- **AWS Well-Architected Framework**: https://aws.amazon.com/architecture/well-architected/
- **CKA Certification**: https://www.cncf.io/certification/cka/

---

## 📞 Support

If you encounter issues:

1. Check the **Troubleshooting** section above
2. Review the plugin-specific README (`plugins/*/README.md`)
3. See **SETUP.md** for detailed setup help
4. Check **ARCHITECTURE.md** for design context

---

**Made with ❤️ for DevOps teams**

---

## Version History

### v1.0.0 (2026-06-22)
- ✨ Initial release
- 🔧 terraform-standards plugin
- 🔍 k8s-troubleshooter plugin
- 🔐 aws-security-review plugin
- 📚 Comprehensive documentation
