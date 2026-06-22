# Contract: terraform-standards Plugin

**Plugin**: terraform-standards  
**Version**: 1.0.0  
**Date**: 2026-06-22

## Overview

The terraform-standards plugin provides two entry points: a pre-apply checklist command and a pre-commit hook. Both analyze Terraform files and enforce tagging, naming, and encryption standards.

---

## Command Contract: `pre-apply-checklist`

### Input

**Type**: File path or directory path  
**Format**: One or more `.tf` files  
**Example**: `./terraform/` or `./main.tf`

**Validation**:
- Path must exist and be readable
- Files must be valid HCL2 syntax (Terraform 0.12+)
- If directory: recursively scan `*.tf` files

### Processing

The command analyzes each resource and validates:

1. **Mandatory Tags**
   - Rule: All resources must have `Environment` and `Owner` tags
   - Exception: Data sources and locals are exempt
   - Violations: List resource by type, name, and missing tag

2. **Naming Convention**
   - Rule: Resource names must use kebab-case (e.g., `s3-bucket-prod`, not `s3BucketProd`)
   - Exception: Tags, variables, and outputs exempt (follow HCL conventions)
   - Violations: Show resource with current name and corrected example

3. **Encryption**
   - Rule: Storage resources (S3, EBS) must have encryption enabled
   - Rule: S3 buckets must enable `server_side_encryption_configuration`
   - Rule: EBS volumes must set `encrypted = true`
   - Violations: Show resource and required encryption setting

### Output

**Format**: Markdown report  
**Exit Code**:
- `0`: All checks pass (no violations)
- `1`: Violations found (but no syntax errors)
- `2`: Terraform syntax error (invalid HCL)

**Example Output** (violations found):
```
# terraform-standards Checklist Report

**File**: main.tf

## ❌ Violations Found

### Missing Tags (4 violations)
- Resource: aws_s3_bucket "backup_vault"
  Missing: Environment, Owner
  Fix: Add tags block with Environment and Owner

- Resource: aws_instance "app_server"
  Missing: Owner
  Fix: Add Owner tag to tags block

### Naming Violations (2 violations)
- Resource: aws_s3_bucket "S3BucketProd"
  Current: S3BucketProd
  Suggested: s3-bucket-prod
  Fix: Rename to kebab-case

### Encryption Violations (1 violation)
- Resource: aws_ebs_volume "data_volume"
  Missing: encrypted = true
  Fix: Add 'encrypted = true' to aws_ebs_volume block

## Summary
- Total violations: 7
- Next step: Fix violations and re-run checklist
```

**Example Output** (all pass):
```
# terraform-standards Checklist Report

**File**: main.tf

## ✅ All Checks Pass

No violations found. Your Terraform code meets all standards.
```

---

## Hook Contract: `commit-credential-blocker`

### Trigger

**Event**: Pre-commit (before git commit executes)  
**Files Checked**: All `.tf` files in staged changes

### Input

**Type**: Git staging area  
**Automatic**: Hook receives staged files from git; no user input required

### Processing

The hook scans staged `.tf` files for hardcoded credentials:

**Patterns Blocked**:
- AWS Access Key ID: `AKIA[0-9A-Z]{16}` (regex)
- AWS Secret Key: `aws_secret_access_key = "..."` (string pattern)
- Hardcoded passwords: `password = "..."` (string pattern)
- PEM private keys: `-----BEGIN (PRIVATE|RSA|OPENSSH)` (string pattern)
- Tokens in comments: `token = "...", api_key = "..."`

### Output

**Format**: Plain text (console message)  
**Action**: Block commit (exit with non-zero code)

**Example Output** (credentials found):
```
[terraform-standards] ❌ Credentials detected in staged files

File: terraform/prod/vars.tf, Line 5:
  aws_secret_access_key = "AKIAIOSFODNN7EXAMPLE"

Issue: Hardcoded AWS secret key found in Terraform code

Recovery:
  1. Remove the hardcoded credential from terraform/prod/vars.tf
  2. Use one of these alternatives instead:
     - AWS provider variable: aws_secret_access_key = var.aws_secret
     - Environment variable: export AWS_SECRET_ACCESS_KEY=...
     - AWS credentials file: ~/.aws/credentials
     - AssumeRole: Use IAM role with credentials provider
  3. Stage the corrected file: git add terraform/prod/vars.tf
  4. Retry commit: git commit -m "..."

Reference: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
```

**Example Output** (no credentials):
```
[terraform-standards] ✅ No credentials detected. Commit allowed.
```

---

## Success Criteria

**Command Success**:
- ✅ Identifies all missing mandatory tags (100% detection rate)
- ✅ Flags all naming violations (kebab-case)
- ✅ Reports all encryption gaps (S3, EBS)
- ✅ Generates actionable reports with examples

**Hook Success**:
- ✅ Blocks 100% of commits with AWS credentials
- ✅ Logs clear reason and recovery steps per constitution Principle III
- ✅ Does not block legitimate code (no false positives)
- ✅ Performance: <2 second check on 1000-line Terraform files

---

## Error Handling

| Error | Cause | User Action |
|-------|-------|-------------|
| "File not found" | Path doesn't exist | Verify path is correct |
| "Invalid HCL syntax" | Terraform parsing error | Fix syntax errors first, re-run |
| "Permission denied" | Cannot read file | Ensure file is readable |
| Hook blocks valid code | False positive in credential check | Report issue; developer may override with `git commit --no-verify` |

---

## Assumptions

- Terraform version 0.12 or later (HCL2 syntax)
- Git 2.0+ for commit hooks
- User has write access to .git/hooks/ directory for hook installation
- Plugin assumes `Environment` and `Owner` are the only mandatory tags (v1); extensible in v2
