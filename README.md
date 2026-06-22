# Cloud DevOps Plugin Marketplace

> A private marketplace for Claude Code plugins that enforce infrastructure standards and enable DevOps diagnostics.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-blue.svg)](CHANGELOG.md)
[![Marketplace Ready](https://img.shields.io/badge/Status-Ready-brightgreen.svg)](#)

## 🚀 Quick Start

Add the marketplace and install plugins with Claude Code commands:

```bash
# 1. Add the marketplace
/plugin marketplace add mkhamisi2007/claude-plugins

# 2. Install plugins as needed
/plugin install terraform-standards@cloud-devops-marketplace
/plugin install k8s-troubleshooter@cloud-devops-marketplace
/plugin install aws-security-review@cloud-devops-marketplace

# 3. Verify installation
/plugin list

# That's it! You're ready to use the plugins.
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

- **Claude Code** (CLI or VS Code extension with plugin support)
  - Installation: https://claude.com/code
  - Verify: `claude code --version`

- **Optional**: `kubectl` (for k8s-troubleshooter)
  - Installation: https://kubernetes.io/docs/tasks/tools/
  - Only needed if using Kubernetes diagnostics plugin

### Installation Steps

#### Step 1: Add the Marketplace

In your Claude Code environment, run:

```
/plugin marketplace add mkhamisi2007/claude-plugins
```

This registers the Cloud DevOps Plugin Marketplace as a plugin source.

#### Step 2: Install Desired Plugins

Install the plugins you need using the `/plugin install` command:

```
# Install Terraform standards enforcement
/plugin install terraform-standards@cloud-devops-marketplace

# Install Kubernetes troubleshooter
/plugin install k8s-troubleshooter@cloud-devops-marketplace

# Install AWS security review
/plugin install aws-security-review@cloud-devops-marketplace
```

You can install all three or just the ones you need—each plugin is completely independent.

#### Step 3: Verify Installation

List all installed plugins to confirm:

```
/plugin list
```

You should see the installed plugins in the output.

#### Step 4: Update the Marketplace (Optional)

If you want to pull the latest plugin updates in the future:

```
/plugin marketplace update cloud-devops-marketplace
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

```
# 1. Install the plugin (see Installation Steps above)
/plugin install terraform-standards@cloud-devops-marketplace

# 2. Run checklist on your Terraform files
/plugin run terraform-standards pre-apply-checklist

# 3. Fix any violations reported

# 4. Commit with confidence (hook blocks credentials)
git commit -m "Update infrastructure"
```

#### Features

**Pre-Apply Checklist Command**
```
# Validate Terraform files before applying
/plugin run terraform-standards pre-apply-checklist

# Output: Markdown report with violations (if any)
# - Missing mandatory tags
# - Naming convention violations
# - Missing encryption
```

**Pre-Commit Hook** (automatic)
```
# The terraform-standards plugin automatically blocks commits with hardcoded credentials
# When you try to commit, the hook validates your changes:

git commit -m "Update infrastructure"
# [terraform-standards] ✅ No credentials detected. Commit allowed.
# OR
# [terraform-standards] ❌ Credentials detected in staged files
# File: main.tf, Line 5: access_key = "AKIAIOSFODNN7EXAMPLE"
# Recovery: Remove credentials and use environment variables instead.
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

```
# 1. Install the plugin
/plugin install k8s-troubleshooter@cloud-devops-marketplace

# 2. Diagnose pod failures
/plugin run k8s-troubleshooter k8s-diagnosis

# Paste or provide kubectl output when prompted
# Output: Diagnostic suggestions with remediation steps

# 3. Validate a manifest
/plugin run k8s-troubleshooter manifest-validator

# Provide your deployment.yaml when prompted
# Output: Report on missing health probes, resource limits, etc.
```

#### Features

**Pod Diagnosis Agent** - Diagnose pod failures interactively
```
/plugin run k8s-troubleshooter k8s-diagnosis

# Provide kubectl output when prompted:
# kubectl describe pods --all-namespaces

# Get suggestions for:
# - CrashLoopBackOff: Check health probes, environment, startup logs
# - Pending: Check resources available, node affinity, PVC status
# - OOMKilled: Increase memory limits
```

**Manifest Validator Skill** - Validate manifests before deployment
```
/plugin run k8s-troubleshooter manifest-validator

# Provide your Kubernetes manifest when prompted
# Validates:
# - Resource requests/limits present on all containers
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

```
# 1. Install the plugin
/plugin install aws-security-review@cloud-devops-marketplace

# 2. Review an IAM policy
/plugin run aws-security-review iam-policy-reviewer

# Provide your IAM policy JSON when prompted
# Output: Flags overly permissive patterns, suggests fixes

# 3. Review S3 bucket or security group configuration
/plugin run aws-security-review iam-policy-reviewer

# Provide your S3 bucket policy or security group JSON
# Output: Flags security issues and suggests restrictions
```

#### Features

**IAM Policy Review**
```
/plugin run aws-security-review iam-policy-reviewer

# Provide your IAM policy JSON

# Flags:
# - Action: "*" without scope → Suggest specific actions
# - Resource: "*" without conditions → Suggest specific resources
# - Principal: "*" in trust policies → Suggest specific principals
```

**S3 Bucket Configuration Review**
```
/plugin run aws-security-review iam-policy-reviewer

# Provide your S3 bucket policy JSON

# Flags:
# - Public read access (Principal: "*")
# - Public write access
# - Missing Block Public Access settings
```

**Security Group Review**
```
/plugin run aws-security-review iam-policy-reviewer

# Provide your security group configuration JSON

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

```
# 1. Validate Terraform configuration
/plugin run terraform-standards pre-apply-checklist
# Provide your Terraform files when prompted

# 2. Fix any violations
# 3. Apply Terraform
terraform apply

# 4. Validate resulting Kubernetes manifests
/plugin run k8s-troubleshooter manifest-validator
# Provide your deployment.yaml when prompted

# 5. Review IAM policies for security
/plugin run aws-security-review iam-policy-reviewer
# Provide your IAM policy JSON when prompted

# 6. Deploy with confidence!
```

### Workflow 2: Production Troubleshooting

```
# Pod is misbehaving? Get instant diagnostics
/plugin run k8s-troubleshooter k8s-diagnosis
# Paste kubectl describe pods output when prompted

# Output gives you:
# - Root cause analysis
# - Specific remediation steps
# - Expected outcome after fixes

# Result: Faster incident resolution, happier DevOps team
```

### Workflow 3: Security Audit

```
# Export current AWS configuration
aws iam get-role-policy --role-name MyRole --policy-name MyPolicy \
  --query 'RolePolicyDocument' > policy.json

# Review for security issues
/plugin run aws-security-review iam-policy-reviewer
# Provide your policy.json when prompted

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

### Plugin Not Found in /plugin list

```
# Verify marketplace is added
/plugin marketplace list

# If cloud-devops-marketplace is missing, add it:
/plugin marketplace add mkhamisi2007/claude-plugins

# Verify plugin is installed
/plugin list
```

### Plugin Command Not Recognized

```
# Verify plugin is installed
/plugin list

# If not listed, install it:
/plugin install terraform-standards@cloud-devops-marketplace

# After installing, try running the plugin:
/plugin run terraform-standards pre-apply-checklist
```

### Update Plugin Marketplace

```
# Get latest versions of all plugins
/plugin marketplace update cloud-devops-marketplace

# This fetches the newest plugin versions from the marketplace
```

### kubectl Connection Fails (k8s-troubleshooter)

```bash
# Verify kubectl is installed
which kubectl

# Verify cluster connectivity
kubectl cluster-info

# Ensure KUBECONFIG is set
echo $KUBECONFIG
```

### Plugin Execution Issues

```
# If a plugin fails to run, check:
1. Plugin is installed: /plugin list
2. Marketplace is up to date: /plugin marketplace update cloud-devops-marketplace
3. You have valid input to provide (policy JSON, Terraform files, kubectl output)
4. Your Claude Code environment is recent enough to support plugins
```

For more help, see individual plugin README files in `plugins/*/README.md` or **SETUP.md** for comprehensive troubleshooting.

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
