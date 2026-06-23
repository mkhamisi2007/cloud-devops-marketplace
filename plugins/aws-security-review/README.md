# aws-security-review Plugin

Automatically flag risky AWS configurations and suggest least-privilege fixes.

## Overview

The aws-security-review plugin helps security teams identify and remediate AWS misconfigurations through:

- 🔐 **IAM policy review**: Detect overly permissive roles and policies
- 🪣 **S3 bucket analysis**: Flag public access and missing protections
- 🔓 **Security group audit**: Identify unrestricted access on sensitive ports
- 💡 **Actionable remediation**: Every finding includes specific fixes

## Installation

This plugin is part of the Cloud DevOps Marketplace. To install:

```bash
/plugin install aws-security-review@cloud-devops-marketplace
```

## Quick Start

### Review AWS Configuration

Analyze IAM policies, S3 buckets, and security groups for security gaps:

```bash
/plugin run aws-security-review iam-policy-reviewer
```

Provide your AWS configuration when prompted (JSON, YAML, or Terraform format).

**Example**:
```
AWS resource configuration:
[Paste IAM policy, S3 bucket policy, or security group JSON here]
```

**Output**: Security review report with violations, severity levels, and remediation steps.

## Features

### IAM Policy Review

Detects overly permissive IAM policies and suggests specific actions/resources:

#### 1. Wildcard Actions
- **Violation**: `"Action": "*"` (allows all AWS API calls)
- **Risk**: Compromise allows full account access
- **Fix**: Narrow to specific actions (e.g., `s3:GetObject`, `ec2:DescribeInstances`)

#### 2. Wildcard Resources
- **Violation**: `"Resource": "*"` (affects all resources)
- **Risk**: Permissions apply to all AWS resources
- **Fix**: Limit to specific resource ARNs

#### 3. Wildcard Principal
- **Violation**: `"Principal": "*"` in trust policy (any AWS principal can assume)
- **Risk**: Anyone with AWS credentials can use this role
- **Fix**: Specify exact principal ARNs or services

#### 4. Missing Conditions
- **Violation**: Broad permissions without conditions
- **Risk**: No restrictions on time, IP, or other factors
- **Fix**: Add Condition block (SourceIp, DateLessThan, etc.)

**Exit Codes**:
- `0` = No critical violations
- `1` = Critical violations found

### S3 Bucket Security

Detects public access and missing protections:

- **Public read access** (Principal: "*")
- **Public write access** (Principal: "*" with PutObject)
- **ACL too permissive** (public-read, public-read-write)
- **Block Public Access disabled** (allows policy/ACL override)

**Fixes Provided**:
- Remove wildcard principals
- Add specific account/role restrictions
- Enable Block All Public Access setting
- AWS CLI commands for remediation

### Security Group Audit

Flags unrestricted access on sensitive ports:

#### Sensitive Ports (Block from 0.0.0.0/0)
- **22 (SSH)** - Unrestricted shell access
- **3306 (MySQL)** - Database exposed to internet
- **5432 (PostgreSQL)** - Database exposed to internet
- **3389 (RDP)** - Remote desktop exposure
- **25 (SMTP)** - Email access
- **1433 (MSSQL)** - SQL Server exposed

#### Public Ports (OK from 0.0.0.0/0)
- **80 (HTTP)** - Normal for public web apps
- **443 (HTTPS)** - Normal for public web apps (recommended over 80)

## Usage Examples

### Example 1: Review IAM Policy

```bash
/plugin run aws-security-review iam-policy-reviewer

# When prompted, paste your policy:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```

Output:
```
## AWS Security Review

### Summary
- Total violations: 1
- Critical: 1
- High: 0

### IAM Policy Violations

#### Severity: CRITICAL
**Issue**: Action is "*" (allows all actions)
**Risk**: Compromise of role allows full AWS account access
**Fix**: Replace with specific actions:
"Action": [
  "s3:GetObject",
  "ec2:DescribeInstances"
]
```

### Example 2: Review S3 Bucket Policy

```bash
/plugin run aws-security-review iam-policy-reviewer

# When prompted, paste S3 bucket policy:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::backup-vault/*"
    }
  ]
}
```

Output:
```
#### S3 Bucket: "backup-vault"
**Severity**: CRITICAL
**Issue**: Bucket policy allows public read access
**Risk**: Sensitive backups are publicly readable
**Fix**: Restrict to specific principal:
"Principal": {
  "AWS": "arn:aws:iam::123456789012:user/BackupOperator"
}

Also enable Block Public Access:
aws s3api put-public-access-block \
  --bucket backup-vault \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Example 3: Review Security Group

```bash
/plugin run aws-security-review iam-policy-reviewer

# When prompted, paste security group JSON:
{
  "GroupId": "sg-123456",
  "IpPermissions": [
    {
      "FromPort": 3306,
      "ToPort": 3306,
      "IpProtocol": "tcp",
      "IpRanges": [{"CidrIp": "0.0.0.0/0"}]
    }
  ]
}
```

Output:
```
#### Security Group: sg-123456
**Severity**: CRITICAL
**Issue**: Allows inbound on port 3306 from 0.0.0.0/0
**Risk**: MySQL database exposed to internet
**Fix**: Restrict to application security group:
{
  "FromPort": 3306,
  "ToPort": 3306,
  "IpProtocol": "tcp",
  "UserIdGroupPairs": [{"GroupId": "sg-app-tier"}]
}
```

## Configuration

The plugin flags these patterns by default:

| Pattern | Severity | Action |
|---------|----------|--------|
| `Action: "*"` | CRITICAL | Flag and suggest specific actions |
| `Resource: "*"` | HIGH | Flag and suggest specific ARNs |
| `Principal: "*"` | CRITICAL | Flag and suggest specific principals |
| S3 `Principal: "*"` | CRITICAL | Flag and suggest account restriction |
| SSH from 0.0.0.0/0 | CRITICAL | Flag and suggest IP restriction |
| Database ports from 0.0.0.0/0 | CRITICAL | Flag and suggest SG restriction |
| HTTP from 0.0.0.0/0 | INFORMATIONAL | OK for public web apps |

## Examples

See `examples/` directory for:
- ❌ `overly-permissive-policy.json` - IAM policy with "*" actions
- ✅ `least-privilege-policy.json` - Specific actions and resources
- ❌ `public-s3-bucket.json` - Publicly readable bucket
- ✅ `private-s3-bucket.json` - Restricted bucket
- ❌ `unrestricted-security-group.json` - Open database port
- ✅ `restricted-security-group.json` - Properly restricted

## Remediation Workflow

1. **Export current config**
   ```bash
   aws iam get-role-policy --role-name MyRole --policy-name MyPolicy \
     --query 'RolePolicyDocument' > policy.json
   ```

2. **Review with plugin**
   ```bash
   /plugin run aws-security-review iam-policy-reviewer
   # Paste policy.json content
   ```

3. **Apply fixes**
   - Update IAM policy to specific actions/resources
   - Enable S3 Block Public Access
   - Restrict security group rules

4. **Redeploy**
   ```bash
   aws iam put-role-policy --role-name MyRole \
     --policy-name MyPolicy --policy-document file://policy.json
   ```

## Standards Reference

This plugin enforces standards aligned with:

- **AWS Well-Architected Framework**: Security Pillar
  - Principle of least privilege
  - Threat model enforcement
  - Data protection at rest and in transit
  
- **AWS Security Best Practices**
  - IAM policy conditions
  - S3 access control
  - Security group rule management

- **CIS AWS Foundations Benchmark**
  - Access control policies
  - Data protection
  - Incident response

## Troubleshooting

### Plugin: "Invalid JSON/YAML"

**Cause**: Configuration has syntax errors  
**Fix**: Validate JSON:

```bash
jq . < policy.json  # Validates JSON
python -m json.tool < policy.json  # Alternative
```

### Plugin: "No policies found"

**Cause**: Input doesn't contain recognizable AWS config  
**Fix**: Provide valid:
- IAM policy document
- S3 bucket policy
- Security group rules
- CloudFormation template

### Plugin: "Ambiguous configuration"

**Cause**: File contains multiple resources  
**Fix**: Extract single resource type and re-submit

### False Positive: "Public HTTP Access Flagged"

**Note**: HTTP (port 80) from 0.0.0.0/0 is acceptable for public web apps

The plugin reports this as INFORMATIONAL (not blocking)

---

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review examples in `examples/` directory
3. See main marketplace README for general plugin help

---

**Version**: 1.0.0  
**Author**: DevOps Team  
**License**: MIT
