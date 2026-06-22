# Contract: aws-security-review Plugin

**Plugin**: aws-security-review  
**Version**: 1.0.0  
**Date**: 2026-06-22

## Overview

The aws-security-review plugin provides a skill for reviewing AWS resource configurations and flagging security gaps. It validates IAM policies, S3 buckets, and security groups against the AWS Well-Architected Framework Security Pillar.

---

## Skill Contract: `iam-policy-reviewer`

### Input

**Type**: AWS resource configuration (JSON or YAML)  
**Formats Supported**:
- IAM policy documents (inline or trust policies)
- S3 bucket policies
- Security group configurations (JSON or Terraform)
- CloudFormation templates (YAML/JSON)

**Example** (IAM Policy):
```json
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

**Validation**:
- Must be valid JSON or YAML
- Must contain at least one AWS resource or policy

### Processing

The skill reviews AWS configurations and flags security gaps per Well-Architected Security Pillar:

**Rules Enforced**:

#### 1. IAM Overly Permissive Policies

**Rule**: IAM policies must follow principle of least privilege.

**Violations Flagged**:

| Pattern | Severity | Issue | Fix |
|---------|----------|-------|-----|
| `"Action": "*"` | CRITICAL | Allows all actions on all resources | Narrow to specific actions (e.g., "s3:GetObject", "ec2:DescribeInstances") |
| `"Resource": "*"` with broad actions | HIGH | Allows actions on all resources | Limit to specific resource ARNs |
| `"Principal": "*"` (trust policy) | CRITICAL | Resource accessible to all AWS principals | Specify exact principal ARNs |
| Wildcard without conditions | HIGH | No conditions restrict access | Add Condition block (e.g., SourceIp, DateLessThan) |

**Example Output** (IAM violations):
```
## AWS Security Review

### IAM Policy Violations

#### Policy: "admin-access"
**Severity**: CRITICAL
**Issue**: Action is "*" (allows all actions)
**Risk**: Compromise of role allows full AWS account access
**Fix**: Replace with specific actions:
```json
"Action": [
  "s3:GetObject",
  "s3:PutObject",
  "ec2:DescribeInstances"
]
```

#### Trust Policy for Role "LambdaExecution"
**Severity**: CRITICAL
**Issue**: Principal is "*" (accessible to anyone)
**Risk**: Any AWS principal can assume this role
**Fix**: Specify principal ARN:
```json
"Principal": {
  "Service": "lambda.amazonaws.com",
  "AWS": "arn:aws:iam::123456789012:role/SpecificRole"
}
```
```

---

#### 2. S3 Bucket Public Access

**Rule**: S3 buckets must not be publicly readable/writable per AWS Well-Architected.

**Violations Flagged**:

| Configuration | Severity | Issue | Fix |
|---------------|----------|-------|-----|
| `"Principal": "*"` in bucket policy | CRITICAL | Public read access | Remove wildcard principal; use specific AWS accounts/roles |
| ACL set to "public-read" | CRITICAL | Public read access | Set ACL to "private"; use bucket policy with specific principals |
| ACL set to "public-read-write" | CRITICAL | Public read/write access | Set ACL to "private"; block all public access |
| Block Public Access disabled | HIGH | Settings allow public access | Enable "Block all public access" in bucket ACLs and policies |

**Example Output** (S3 violations):
```
#### S3 Bucket: "backup-vault"
**Severity**: CRITICAL
**Issue**: Bucket policy allows public read access
**Risk**: Sensitive backups are publicly readable; data breach likely
**Configuration**:
```json
"Principal": "*",
"Action": "s3:GetObject"
```
**Fix**: Restrict to specific principal:
```json
"Principal": {
  "AWS": "arn:aws:iam::123456789012:user/BackupOperator"
},
"Action": "s3:GetObject"
```

Also enable Block Public Access:
```
aws s3api put-public-access-block \
  --bucket backup-vault \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```
```

---

#### 3. Security Groups Unrestricted Access

**Rule**: Security groups must not allow unrestricted inbound access (0.0.0.0/0) on sensitive ports.

**Violations Flagged**:

| Port | Severity | Condition | Issue | Fix |
|------|----------|-----------|-------|-----|
| 22 (SSH) | CRITICAL | 0.0.0.0/0 inbound | Unrestricted SSH access | Limit CIDR to specific IPs or security groups |
| 3306 (MySQL) | CRITICAL | 0.0.0.0/0 inbound | Database exposed to internet | Restrict to application security groups only |
| 5432 (PostgreSQL) | CRITICAL | 0.0.0.0/0 inbound | Database exposed to internet | Restrict to application security groups only |
| 3389 (RDP) | CRITICAL | 0.0.0.0/0 inbound | Unrestricted RDP access | Limit CIDR or require bastion host |
| 80 (HTTP) | ACCEPTABLE | 0.0.0.0/0 inbound | Public web traffic (normal) | OK for public-facing web apps |
| 443 (HTTPS) | ACCEPTABLE | 0.0.0.0/0 inbound | Public web traffic (normal) | OK for public-facing web apps; prefer 443 over 80 |
| 25 (SMTP) | HIGH | 0.0.0.0/0 inbound | Public email access | Restrict to mail servers; consider SES instead |

**Example Output** (Security Group violations):
```
#### Security Group: "database-sg"
**Severity**: CRITICAL
**Issue**: Allows inbound on port 3306 from 0.0.0.0/0
**Risk**: MySQL database exposed to internet scanning; credentials at risk
**Configuration**:
```
IpPermission:
  FromPort: 3306
  ToPort: 3306
  IpProtocol: tcp
  IpRanges: [{CidrIp: "0.0.0.0/0"}]
```
**Fix**: Restrict to application security group:
```
IpPermission:
  FromPort: 3306
  ToPort: 3306
  IpProtocol: tcp
  UserIdGroupPairs: [{GroupId: "sg-app-tier"}]
```

#### Security Group: "web-sg"
**Severity**: ACCEPTABLE (Informational)
**Allows**: HTTP (port 80) from 0.0.0.0/0
**Note**: Normal for public-facing web applications; however, recommend using HTTPS (443) instead of HTTP.
**Fix** (recommended, not required):
```
IpPermission:
  FromPort: 443
  ToPort: 443
  IpProtocol: tcp
  IpRanges: [{CidrIp: "0.0.0.0/0"}]
```
```

---

### Output

**Format**: Markdown security review report  
**Exit Code**:
- `0`: No critical violations (may have medium/low)
- `1`: Critical violations found (security risk)

**Report Structure**:
```
## AWS Security Review

### Summary
- Total resources reviewed: [N]
- Critical violations: [N]
- High violations: [N]
- Medium violations: [N]
- Acceptable findings: [N]

### Violations by Type

#### IAM Policies
[Violations listed]

#### S3 Buckets
[Violations listed]

#### Security Groups
[Violations listed]

### Overall Recommendation
[Risk assessment and priority fixes]
```

**Example Full Report**:
```
## AWS Security Review

### Summary
- Total resources reviewed: 5
- Critical violations: 3
- High violations: 1
- Medium violations: 0
- Acceptable findings: 1

### Critical Violations

#### Issue 1: Overly Permissive IAM Policy
[Details...]

#### Issue 2: Public S3 Bucket
[Details...]

#### Issue 3: Database Security Group Exposed
[Details...]

### High Violations

#### Issue 4: SMTP Open to Internet
[Details...]

### Acceptable Findings

- Web Security Group allows HTTP/HTTPS from 0.0.0.0/0 (normal for public web)

### Overall Recommendation

**RISK LEVEL**: HIGH

Address critical violations immediately:
1. Fix IAM policy: Remove "*" Actions and Resources
2. Block public access to S3 bucket
3. Restrict database security group to internal subnets

Timeline: Complete within 48 hours.
```

---

## Success Criteria

**Skill Success**:
- ✅ Flags 100% of overly permissive IAM policies (Action: "*")
- ✅ Detects all public S3 bucket configurations
- ✅ Identifies unrestricted security group access on sensitive ports (22, 3306, 5432, 3389)
- ✅ Distinguishes between critical and acceptable configurations (HTTP/HTTPS on 80/443)
- ✅ Provides clear remediation steps for each violation
- ✅ Performance: <10 seconds to review typical AWS configuration (SC-004)

---

## Error Handling

| Error | Cause | User Action |
|-------|-------|-------------|
| "Invalid JSON/YAML" | Configuration syntax error | Fix JSON/YAML formatting |
| "Unsupported resource type" | CRD or custom resource | Focus on standard AWS resources (IAM, S3, EC2) |
| "No policies found" | Empty input | Provide valid IAM policy, S3 bucket policy, or security group config |
| "Ambiguous configuration" | Multi-resource file | Extract single resource and re-submit (or fix will be improved in v1.1) |

---

## Assumptions

- Configurations provided as JSON (AWS standard) or YAML (for readability)
- No live AWS API calls; analysis is static (provided configs only)
- User understands AWS Well-Architected Framework context
- Principle of least privilege is security baseline (not relaxed for convenience)
