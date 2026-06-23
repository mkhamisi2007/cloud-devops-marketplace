# terraform-standards Plugin

Enforce Terraform best practices with automated validation and commit blocking.

## Overview

The terraform-standards plugin helps DevOps teams maintain consistent Terraform code through:

- ✅ **Pre-apply checklist**: Validate Terraform files for tags, naming, and encryption
- ✅ **Pre-commit hook**: Block commits containing hardcoded credentials
- ✅ **Clear remediation**: Every violation includes actionable fix instructions

## Installation

This plugin is part of the Cloud DevOps Marketplace. To install:

```bash
/plugin install terraform-standards@cloud-devops-marketplace
```

## Quick Start

### 1. Run Pre-Apply Checklist

Validate your Terraform files before applying:

```bash
/plugin run terraform-standards pre-apply-checklist
```

Provide the path to your Terraform files or directory when prompted.

**Example**:
```
Terraform file path: ./terraform/
```

**Output**: Markdown report showing any violations with remediation steps.

### 2. Automatic Pre-Commit Hook

The hook automatically runs when you commit Terraform files:

```bash
git commit -m "Update infrastructure"
```

**If credentials are detected**: Commit is blocked with clear recovery instructions.

**If no credentials**: Commit proceeds with confirmation message.

## Features

### Pre-Apply Checklist Command

Validates Terraform files for:

1. **Mandatory Tags**
   - Every resource must have `Environment` and `Owner` tags
   - Exception: Data sources and locals are exempt
   - Violations show which tags are missing

2. **Naming Convention**
   - Resource names must use kebab-case (e.g., `s3-bucket-prod`, not `S3BucketProd`)
   - Exception: Tags, variables, outputs follow HCL naming conventions
   - Violations show current name and suggested fix

3. **Encryption**
   - S3 buckets must have `server_side_encryption_configuration` enabled
   - EBS volumes must have `encrypted = true`
   - Violations show the required encryption setting

**Exit Codes**:
- `0` = All checks pass
- `1` = Violations found (but valid syntax)
- `2` = Terraform syntax error (invalid HCL)

### Pre-Commit Hook

Blocks commits containing hardcoded credentials:

- **AWS Access Keys**: Detects `AKIA[0-9A-Z]{16}` patterns
- **AWS Secret Keys**: Blocks `aws_secret_access_key = "..."`
- **Passwords**: Blocks `password = "..."`
- **PEM Private Keys**: Blocks `-----BEGIN PRIVATE KEY` etc.
- **Tokens**: Blocks `api_key = "..."`, `token = "..."`

When credentials are detected:
- Commit is blocked (exit code 1)
- File name and line number are shown
- Clear recovery instructions are provided
- Developer can use `git commit --no-verify` to override (not recommended)

## Usage Examples

### Example 1: Validate Terraform Directory

```bash
/plugin run terraform-standards pre-apply-checklist

# When prompted:
# Terraform file path: ./terraform/prod/
```

Output shows violations like:
```
### Missing Tags (2 violations)
- Resource: aws_s3_bucket "backup_vault"
  Missing: Environment, Owner
  Fix: Add tags block with Environment and Owner
```

### Example 2: Block Credentials at Commit

```bash
# Developer accidentally added hardcoded key
echo 'aws_secret_access_key = "AKIAIOSFODNN7EXAMPLE"' >> terraform/main.tf
git add terraform/main.tf
git commit -m "Add API configuration"

# Output:
# [terraform-standards] ❌ Credentials detected in staged files
# 
# File: terraform/main.tf, Line 42:
#   aws_secret_access_key = "AKIAIOSFODNN7EXAMPLE"
#
# Recovery:
#   1. Remove the hardcoded credential
#   2. Use environment variables or AWS credentials file instead
#   ...
```

### Example 3: Compliant Commit

```bash
# Terraform file with proper tags, naming, encryption
git add terraform/main.tf
git commit -m "Add production S3 bucket"

# Output:
# [terraform-standards] ✅ No credentials detected. Commit allowed.
```

## Configuration

The plugin enforces these standards by default:

| Standard | Rule | Scope |
|----------|------|-------|
| **Tags** | Environment, Owner required | All resources except data sources, locals |
| **Naming** | kebab-case | Resource names only |
| **Encryption** | Required on S3, EBS | Storage resources |
| **Credentials** | Blocked | All .tf files in staged changes |

Future versions may support configuration files to customize these rules.

## Examples

See `examples/` directory for:
- ✅ `compliant.tf` - Properly tagged, named, and encrypted resources
- ❌ `violations.tf` - Examples of common violations
- 📋 `aws-well-architected.tf` - AWS Well-Architected best practices

## Troubleshooting

### "Invalid HCL syntax" Error

**Cause**: Terraform file has syntax errors  
**Fix**: Validate with `terraform validate` first, then fix syntax errors

```bash
terraform validate
# Fix any errors, then re-run checklist
/plugin run terraform-standards pre-apply-checklist
```

### Hook Blocks Valid Code (False Positive)

**Cause**: Legitimate string contains credential-like pattern  
**Fix**: Override hook for this commit only (not recommended)

```bash
git commit --no-verify -m "Add configuration"
```

Better fix: Refactor code to avoid the pattern.

### Hook Not Running

**Cause**: Hook not installed or not executable  
**Fix**: Reinstall the plugin

```bash
/plugin uninstall terraform-standards
/plugin install terraform-standards@cloud-devops-marketplace
```

### Multiple Violations in Large File

**Cause**: Many resources violate standards  
**Fix**: Fix violations in order (tags, then naming, then encryption)

```bash
# 1. Add missing tags to all resources
# 2. Rename resources to kebab-case
# 3. Enable encryption on storage resources
# 4. Re-run checklist
/plugin run terraform-standards pre-apply-checklist
```

## Standards Reference

This plugin enforces standards aligned with:

- **AWS Well-Architected Framework**: Security Pillar
  - Tagging enables compliance tracking and cost allocation
  - Encryption protects data at rest
  
- **Infrastructure as Code Best Practices**
  - Naming conventions improve code readability
  - Consistent tag structure enables automation

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review examples in `examples/` directory
3. See main marketplace README for general plugin help

---

**Version**: 1.0.0  
**Author**: DevOps Team  
**License**: MIT
