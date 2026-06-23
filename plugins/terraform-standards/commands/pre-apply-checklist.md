# Command: pre-apply-checklist

Validate Terraform files for tagging, naming conventions, and encryption standards before applying infrastructure changes.

## Description

Analyzes Terraform (.tf) files and reports violations of:
- **Mandatory tags**: Environment and Owner tags required on all resources
- **Naming convention**: Resource names must use kebab-case
- **Encryption**: Storage resources (S3, EBS) must have encryption enabled

Exit codes:
- `0` = All checks pass
- `1` = Violations found
- `2` = Terraform syntax error

## Input

The command accepts a file or directory path containing Terraform files.

**Prompt**: "Enter the path to your Terraform file or directory:"

**Valid inputs**:
- Single file: `./main.tf`
- Directory (recursive): `./terraform/`, `./infra/`
- Absolute path: `/home/user/terraform/prod/`

**Validation**:
- Path must exist and be readable
- Files must be valid Terraform HCL2 syntax (0.12+)
- Directory is recursively scanned for `*.tf` files

## Processing

### 1. Parse Terraform Files

For each `.tf` file found:
1. Read file content
2. Parse HCL2 syntax (validate valid Terraform)
3. Extract resource blocks

**Resources checked**: Any block of type `resource "..."`

**Resources exempt from tagging rules**:
- `data "..."` (data sources)
- `locals {...}` (local values)
- `variable "..."` (input variables)
- `output "..."` (outputs)

### 2. Validate Mandatory Tags

**Rule**: All resources must have tags block with Environment and Owner keys

**Violation**: Resource missing Environment tag, Owner tag, or both

**Report format**:
```
- Resource: aws_s3_bucket "example"
  Missing: Environment, Owner
  Fix: Add tags block with Environment = "..." and Owner = "..."
```

### 3. Validate Naming Convention

**Rule**: Resource names must use kebab-case (lowercase with hyphens only)

**Pattern**: `[a-z0-9]+(-[a-z0-9]+)*`

**Violation**: Resource name contains uppercase, underscores, or mixed case

**Examples**:
- ❌ Invalid: `S3BucketProd`, `S3_Bucket_Prod`, `s3BucketProd`
- ✅ Valid: `s3-bucket-prod`, `app-server-01`, `db-primary`

**Report format**:
```
- Resource: aws_s3_bucket "BackupVault"
  Current: BackupVault
  Suggested: backup-vault
  Fix: Rename resource name to kebab-case
```

### 4. Validate Encryption

**Rule**: Storage resources must have encryption enabled

**Scope**:
- S3 buckets: Must have `server_side_encryption_configuration` block
- EBS volumes: Must have `encrypted = true` attribute

**Violation**: Storage resource missing encryption configuration

**Report format**:
```
- Resource: aws_ebs_volume "data_volume"
  Missing: encrypted = true
  Fix: Add 'encrypted = true' to resource block
```

## Output

### Format

Markdown report with sections for each violation type.

### Example Output (All Pass)

```markdown
# terraform-standards Checklist Report

**File**: main.tf

## ✅ All Checks Pass

No violations found. Your Terraform code meets all standards.
```

### Example Output (Violations Found)

```markdown
# terraform-standards Checklist Report

**Files Checked**: 3 file(s) in terraform/ directory

## ❌ Violations Found

### Missing Tags (4 violations)

- Resource: aws_s3_bucket "backup_vault"
  Missing: Environment, Owner
  Fix: Add tags block with Environment and Owner

- Resource: aws_instance "web_server"
  Missing: Owner
  Fix: Add Owner tag to tags block

### Naming Violations (2 violations)

- Resource: aws_s3_bucket "S3BucketProd"
  Current: S3BucketProd
  Suggested: s3-bucket-prod
  Fix: Rename to kebab-case

- Resource: aws_rds_instance "CompanyDatabase"
  Current: CompanyDatabase
  Suggested: company-database
  Fix: Rename to kebab-case

### Encryption Violations (1 violation)

- Resource: aws_ebs_volume "data_volume"
  Missing: encrypted = true
  Fix: Add 'encrypted = true' to aws_ebs_volume block

## Summary

- **Total violations**: 7
- **Files with violations**: 2 / 3
- **Next step**: Fix violations and re-run checklist

## How to Fix

1. Add mandatory tags to all resources:
   ```terraform
   tags = {
     Environment = "production"
     Owner       = "team@company.com"
   }
   ```

2. Rename resources to kebab-case:
   - PascalCase → kebab-case
   - snake_case → kebab-case
   - MixedCase → kebab-case

3. Enable encryption on storage:
   ```terraform
   # S3 bucket
   resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
     ...
   }
   
   # EBS volume
   encrypted = true
   ```

4. Re-run checklist to verify all fixes

## Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | All checks pass | Proceed with `terraform apply` |
| 1 | Violations found | Fix violations and re-run |
| 2 | Syntax error | Fix HCL syntax, re-run |
```

## Error Handling

### File Not Found

```
Error: Path does not exist
  Path: /home/user/nonexistent/

Action: Verify the path is correct and readable
```

### Invalid Terraform Syntax

```
Error: Invalid Terraform HCL syntax in file
  File: main.tf
  Line: 45
  Error: Unexpected token: expected '=' but found 'value'

Action: Fix Terraform syntax errors first, then re-run checklist
  Suggested: Run 'terraform validate' to identify syntax issues
```

### Permission Denied

```
Error: Permission denied reading file
  File: terraform/prod/main.tf
  
Action: Check file permissions and ensure you have read access
  Suggested: chmod u+r terraform/prod/main.tf
```

## Limitations

- Does not validate resource attribute values (e.g., bucket names must be globally unique)
- Does not check for deprecated resource types
- Does not validate provider configuration
- Exempts specific resource types from tagging (data sources, locals)
- Regex patterns are simple; complex HCL structures may not parse correctly

## Related Documentation

- **Contract**: `specs/001-plugin-marketplace/contracts/terraform-standards-contract.md`
- **Examples**: `plugins/terraform-standards/examples/`
- **Hook Documentation**: Pre-commit hook blocks credentials in separate process

## Success Criteria

✅ Identifies all missing mandatory tags (100% detection rate)  
✅ Flags all naming violations (kebab-case enforcement)  
✅ Reports all encryption gaps (S3, EBS)  
✅ Generates actionable reports with remediation examples  
✅ Performance: <5 seconds on typical Terraform projects (< 1000 lines)
