# Setup Guide: Cloud DevOps Plugin Marketplace

**Version**: 1.0.0  
**Last Updated**: 2026-06-22

This guide covers installing and verifying the Cloud DevOps Plugin Marketplace and its plugins.

---

## Prerequisites

Before installing, ensure you have:

### Required

- **Claude Code**: Version 1.0+ (CLI or VS Code extension)
  - Installation: https://claude.com/code or `npm install -g @anthropic-ai/claude-code`
  - Verify: `claude code --version`

- **Git**: Version 2.0+ (for terraform-standards hook)
  - macOS: `brew install git`
  - Linux: `sudo apt-get install git`
  - Windows: https://git-scm.com/download/win
  - Verify: `git --version`

### Optional (for specific plugins)

- **kubectl**: For k8s-troubleshooter
  - Installation: https://kubernetes.io/docs/tasks/tools/
  - Verify: `kubectl version --client`
  - Purpose: Provides pod diagnostic data to the k8s-troubleshooter agent

- **Terraform**: For terraform-standards examples
  - Installation: https://www.terraform.io/downloads.html
  - Verify: `terraform version`
  - Purpose: Example files; not required for checklist command

---

## Installation Steps

### Step 1: Clone or Download Marketplace

```bash
# Clone the repository
git clone https://github.com/yourorg/cloud-devops-marketplace.git
cd cloud-devops-marketplace

# Or download and extract ZIP
unzip cloud-devops-marketplace.zip
cd cloud-devops-marketplace
```

### Step 2: Identify Claude Code Plugin Directory

Determine where Claude Code expects plugins:

```bash
# macOS/Linux
export CLAUDE_CODE_PLUGINS_DIR=~/.claude/plugins

# Windows (PowerShell)
$env:CLAUDE_CODE_PLUGINS_DIR = "$env:USERPROFILE\.claude\plugins"

# Create directory if it doesn't exist
mkdir -p $CLAUDE_CODE_PLUGINS_DIR
```

### Step 3: Install Desired Plugins

Choose which plugins to install (each is independent):

#### Install terraform-standards

```bash
# Copy plugin to Claude Code directory
cp -r plugins/terraform-standards $CLAUDE_CODE_PLUGINS_DIR/terraform-standards

# Verify installation
ls -la $CLAUDE_CODE_PLUGINS_DIR/terraform-standards/.claude-plugin/

# Should show: plugin.json
```

#### Install k8s-troubleshooter

```bash
# Copy plugin to Claude Code directory
cp -r plugins/k8s-troubleshooter $CLAUDE_CODE_PLUGINS_DIR/k8s-troubleshooter

# Verify installation
ls -la $CLAUDE_CODE_PLUGINS_DIR/k8s-troubleshooter/.claude-plugin/

# Should show: plugin.json
```

#### Install aws-security-review

```bash
# Copy plugin to Claude Code directory
cp -r plugins/aws-security-review $CLAUDE_CODE_PLUGINS_DIR/aws-security-review

# Verify installation
ls -la $CLAUDE_CODE_PLUGINS_DIR/aws-security-review/.claude-plugin/

# Should show: plugin.json
```

### Step 4: Restart Claude Code

After installing plugins, restart Claude Code to reload plugin registry:

- **CLI**: Quit and restart `claude code` command
- **VS Code Extension**: Reload window (Cmd+Shift+P → "Reload Window")

### Step 5: Verify Installation

Test that plugins are discoverable:

```bash
# List installed plugins
ls $CLAUDE_CODE_PLUGINS_DIR/

# Should output:
# terraform-standards
# k8s-troubleshooter
# aws-security-review
```

---

## Plugin-Specific Setup

### terraform-standards: Git Hook Installation

The pre-commit hook requires additional setup:

```bash
# Navigate to your project using terraform-standards
cd /path/to/your/terraform/project

# Install pre-commit hook
cp $CLAUDE_CODE_PLUGINS_DIR/terraform-standards/hooks/pre-commit .git/hooks/pre-commit

# Make executable
chmod +x .git/hooks/pre-commit

# Verify installation
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x ... pre-commit
```

**Testing the hook**:

```bash
# Create a test file with hardcoded credentials
echo 'resource "aws_provider" {' > test.tf
echo '  access_key = "AKIAIOSFODNN7EXAMPLE"' >> test.tf
echo '}' >> test.tf

# Try to commit (should be blocked)
git add test.tf
git commit -m "Add provider config"

# Expected output:
# [terraform-standards] ❌ Credentials detected in staged files
# File: test.tf
# Recovery: Remove credentials and use environment variables instead
```

### k8s-troubleshooter: kubectl Configuration

Ensure kubectl has access to your cluster:

```bash
# Verify kubectl connectivity
kubectl cluster-info

# Should output cluster endpoint and version

# Verify kubectl can list resources
kubectl get pods --all-namespaces

# Should show pods in your cluster(s)
```

### aws-security-review: No Additional Setup Required

aws-security-review analyzes provided configurations and requires no external connections.

---

## Verification Checklist

### Installation Verification

- [ ] Claude Code is installed and runnable (`claude code --version`)
- [ ] Git is installed and accessible (`git --version`)
- [ ] Plugin directories exist under ~/.claude/plugins/
- [ ] Each plugin has a `.claude-plugin/plugin.json` file
- [ ] Claude Code has been restarted after installation

### Functionality Verification

#### terraform-standards

- [ ] Run pre-apply checklist command:
  ```bash
  claude code run terraform-standards pre-apply-checklist ./
  ```
  Expected: Runs without error (may report no violations if directory is clean)

- [ ] Hook is installed and executable:
  ```bash
  ls -la .git/hooks/pre-commit
  ```
  Expected: `-rwxr-xr-x` permissions

#### k8s-troubleshooter

- [ ] kubectl is accessible:
  ```bash
  kubectl get pods
  ```
  Expected: Lists pods in your cluster

- [ ] Agent is runnable:
  ```bash
  kubectl describe pod test-pod 2>/dev/null | claude code run k8s-troubleshooter k8s-diagnosis
  ```
  Expected: Provides diagnostic output or "no issues found"

#### aws-security-review

- [ ] Skill is runnable:
  ```bash
  echo '{"Statement": [{"Action": "*", "Resource": "*"}]}' | claude code run aws-security-review iam-policy-reviewer
  ```
  Expected: Flags overly permissive policy

### Performance Verification

- [ ] terraform-standards checklist completes in <5 seconds
- [ ] k8s-troubleshooter agent responds in <10 seconds
- [ ] aws-security-review skill responds in <5 minutes

---

## Troubleshooting

### Plugin Not Found

**Symptom**: "Plugin not found" or "Unknown command"

**Solutions**:
1. Verify plugin is in correct directory:
   ```bash
   ls ~/.claude/plugins/terraform-standards/
   ```

2. Verify plugin.json exists:
   ```bash
   cat ~/.claude/plugins/terraform-standards/.claude-plugin/plugin.json
   ```

3. Restart Claude Code and try again

4. Check Claude Code documentation for plugin path configuration

### Command/Agent/Skill Not Recognized

**Symptom**: "Unknown agent: k8s-diagnosis" or similar

**Solutions**:
1. Verify entrypoint name matches plugin.json:
   ```bash
   grep -A 5 "entrypoints" ~/.claude/plugins/terraform-standards/.claude-plugin/plugin.json
   ```

2. Ensure plugin is fully copied (not just `.claude-plugin/` directory)

3. Reload Claude Code completely (quit and restart)

### Git Hook Not Running

**Symptom**: Hook doesn't block commits with credentials

**Solutions**:
1. Verify hook is installed:
   ```bash
   ls -la .git/hooks/pre-commit
   ```

2. Verify hook is executable:
   ```bash
   chmod +x .git/hooks/pre-commit
   ```

3. Test hook manually:
   ```bash
   ./.git/hooks/pre-commit
   ```

4. Check hook script content:
   ```bash
   head -20 .git/hooks/pre-commit
   ```

### kubectl Connection Fails

**Symptom**: "Unable to connect to Kubernetes cluster" or no pod output

**Solutions**:
1. Verify kubectl is installed:
   ```bash
   which kubectl
   ```

2. Verify cluster connectivity:
   ```bash
   kubectl cluster-info
   ```

3. Check kubeconfig:
   ```bash
   echo $KUBECONFIG
   ls ~/.kube/config
   ```

4. Provide kubeconfig path if needed:
   ```bash
   export KUBECONFIG=~/.kube/config
   kubectl get pods
   ```

### Performance Issues

**Symptom**: Commands take >10 seconds or timeout

**Solutions**:
1. For terraform-standards: Verify HCL2 syntax in Terraform files
   ```bash
   terraform validate
   ```

2. For k8s-troubleshooter: Provide truncated output if full output is very large
   ```bash
   kubectl get pods -n namespace | head -100 | claude code run k8s-troubleshooter k8s-diagnosis
   ```

3. For aws-security-review: Break complex policies into smaller chunks

---

## Uninstallation

To remove installed plugins:

```bash
# Remove terraform-standards
rm -rf ~/.claude/plugins/terraform-standards

# Remove k8s-troubleshooter
rm -rf ~/.claude/plugins/k8s-troubleshooter

# Remove aws-security-review
rm -rf ~/.claude/plugins/aws-security-review

# Remove terraform-standards hook (if installed)
rm .git/hooks/pre-commit
```

---

## Next Steps

After successful installation:

1. **Read Plugin Documentation**: Review README.md in each plugin directory
2. **Try Examples**: Run example files provided in plugins/*/examples/
3. **Read Quickstart**: See `specs/001-plugin-marketplace/quickstart.md` for detailed validation scenarios
4. **Check Architecture**: See `docs/ARCHITECTURE.md` for design and technical details

---

## Support

If you encounter issues during setup:

1. Review the **Troubleshooting** section above
2. Check plugin-specific README files in `plugins/*/README.md`
3. Review `docs/ARCHITECTURE.md` for design details
4. Consult `specs/001-plugin-marketplace/quickstart.md` for validation scenarios

---

## Version History

- **1.0.0** (2026-06-22): Initial release
  - terraform-standards plugin
  - k8s-troubleshooter plugin
  - aws-security-review plugin
  - Marketplace registry and documentation
