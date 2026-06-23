# Skill: iam-policy-reviewer

Review AWS resource configurations (IAM, S3, Security Groups) for security gaps aligned with AWS Well-Architected Security Pillar.

## Description

Analyzes AWS configurations and flags security violations using principle of least privilege. Reviews IAM policies, S3 bucket configurations, and security group rules.

## Input

**Type**: AWS resource configuration (JSON or YAML)

**Accepted Formats**:
- IAM policy documents (inline or trust policies)
- S3 bucket policies
- S3 ACL configurations
- Security group rules (EC2 format)
- Security group in Terraform HCL
- CloudFormation templates
- Multi-resource files

**Example Inputs**:

IAM Policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
```

S3 Bucket Policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::mybucket/*"
    }
  ]
}
```

Security Group (EC2 format):
```json
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

**Validation**:
- Must be valid JSON or YAML
- Must contain at least one AWS resource or policy

## Processing

### 1. Parse Configuration
Extract IAM policies, S3 bucket policies, and security group rules

### 2. Flag Three Violation Types

#### Violation Type 1: Overly Permissive IAM Policies

**Patterns Flagged**:

| Pattern | Severity | Description | Fix |
|---------|----------|-------------|-----|
| `"Action": "*"` | CRITICAL | All API actions allowed | Specify exact actions (e.g., "s3:GetObject") |
| `"Resource": "*"` with broad actions | HIGH | Affects all AWS resources | Limit to specific ARNs |
| `"Principal": "*"` in trust policy | CRITICAL | Anyone can assume role | Specify service or account |
| No `Condition` block with wildcards | HIGH | No restrictions on time/IP | Add conditions (SourceIp, DateLessThan) |

**Report Format**:

```
#### Issue: Overly Permissive IAM Policy
**Severity**: CRITICAL
**Statement**: 
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}
**Risk**: Compromise of this role grants full AWS account access
**Root Cause**: Policy uses wildcard for actions and resources

**Fix**: Narrow to specific actions and resources:
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject",
    "dynamodb:GetItem"
  ],
  "Resource": [
    "arn:aws:s3:::mybucket/documents/*",
    "arn:aws:dynamodb:us-east-1:123456789012:table/Users"
  ]
}

**Best Practice**: Review AWS documentation for required actions
- S3: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-iam-policies.html
- DynamoDB: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/access-control-overview.html
```

**Recommended Patterns**:

For S3 (common example):
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": "arn:aws:s3:::mybucket/documents/*"
}
```

For EC2:
```json
{
  "Effect": "Allow",
  "Action": [
    "ec2:DescribeInstances",
    "ec2:DescribeSecurityGroups"
  ],
  "Resource": "*"  // OK - read-only APIs don't require specific resources
}
```

---

#### Violation Type 2: Public S3 Bucket Access

**Patterns Flagged**:

| Pattern | Severity | Issue | Fix |
|---------|----------|-------|-----|
| `"Principal": "*"` in bucket policy | CRITICAL | Public read access | Remove wildcard; specify account/role |
| `"Principal": "*"` with PutObject | CRITICAL | Public write access | Remove wildcard; enable Block Public Access |
| ACL: "public-read" | CRITICAL | Public read via ACL | Change ACL to "private" |
| ACL: "public-read-write" | CRITICAL | Public read/write | Change ACL to "private"; block public access |
| Block Public Access disabled | HIGH | Settings can be overridden | Enable all Block Public Access settings |

**Report Format**:

```
#### Issue: Public S3 Bucket Read Access
**Severity**: CRITICAL
**Resource**: S3 Bucket "backup-vault"
**Configuration**:
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
**Risk**: Backup files are publicly readable; sensitive data exposed

**Fix**: 
1. Restrict Principal to specific account/role:
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::123456789012:user/BackupOperator"
  },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::backup-vault/*"
}

2. Enable Block Public Access:
aws s3api put-public-access-block \
  --bucket backup-vault \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

3. (Optional) Use S3 encryption:
aws s3api put-bucket-encryption \
  --bucket backup-vault \
  --server-side-encryption-configuration \
  'Rules=[{ApplyServerSideEncryptionByDefault={SSEAlgorithm=AES256}}]'
```

**Recommended Pattern**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/BackupRole"
      },
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::mybucket/backups/*"
    }
  ]
}
```

---

#### Violation Type 3: Security Group Unrestricted Access

**Patterns Flagged**:

| Port | Protocol | Severity | Issue | Fix |
|------|----------|----------|-------|-----|
| 22 | TCP | CRITICAL | Unrestricted SSH access | Limit to specific IPs or SG |
| 3306 | TCP | CRITICAL | MySQL database exposed | Restrict to app tier SG |
| 5432 | TCP | CRITICAL | PostgreSQL exposed | Restrict to app tier SG |
| 3389 | TCP | CRITICAL | RDP exposed | Limit to bastion or VPN |
| 25 | TCP | HIGH | SMTP exposed | Restrict to mail servers |
| 80 | TCP | INFORMATIONAL | HTTP public (normal) | OK; recommend HTTPS on 443 |
| 443 | TCP | ACCEPTABLE | HTTPS public (normal) | OK for web apps |

**Report Format**:

```
#### Issue: Database Port Exposed to Internet
**Severity**: CRITICAL
**Security Group**: sg-database
**Configuration**:
{
  "IpPermissions": [
    {
      "FromPort": 3306,
      "ToPort": 3306,
      "IpProtocol": "tcp",
      "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "MySQL"}]
    }
  ]
}
**Risk**: MySQL database exposed to internet scanning; credentials at risk

**Fix**: Restrict to application tier security group:
{
  "IpPermissions": [
    {
      "FromPort": 3306,
      "ToPort": 3306,
      "IpProtocol": "tcp",
      "UserIdGroupPairs": [
        {
          "GroupId": "sg-app-tier",
          "Description": "App tier MySQL access"
        }
      ]
    }
  ]
}

**AWS CLI Command**:
aws ec2 revoke-security-group-ingress \
  --group-id sg-database \
  --ip-permissions IpProtocol=tcp,FromPort=3306,ToPort=3306,IpRanges='[{CidrIp=0.0.0.0/0}]'

aws ec2 authorize-security-group-ingress \
  --group-id sg-database \
  --source-group sg-app-tier \
  --group-owner-id 123456789012 \
  --protocol tcp \
  --port 3306
```

**Recommended Pattern**:

```json
{
  "GroupId": "sg-database",
  "IpPermissions": [
    {
      "FromPort": 3306,
      "ToPort": 3306,
      "IpProtocol": "tcp",
      "UserIdGroupPairs": [
        {
          "GroupId": "sg-app-tier",
          "Description": "Application tier MySQL access"
        }
      ]
    }
  ]
}
```

## Output

**Format**: Markdown security review report

**Exit Code**:
- `0` = No critical violations (may have medium/low)
- `1` = Critical violations found

### Example Output (With Violations)

```markdown
## AWS Security Review

### Summary
- Total resources reviewed: 3
- Critical violations: 2
- High violations: 1
- Medium violations: 0
- Acceptable findings: 1

### Critical Violations

#### Issue 1: Overly Permissive IAM Policy
[Details as shown above]

#### Issue 2: Public S3 Bucket
[Details as shown above]

### High Violations

#### Issue 3: SMTP Open to Internet
[Details...]

### Acceptable Findings

- Web Security Group allows HTTP/HTTPS from 0.0.0.0/0 (normal for public web)

### Overall Risk Assessment

**RISK LEVEL**: HIGH

**Timeline**: Address critical violations within 48 hours

**Priority Actions**:
1. Fix IAM policy: Replace "*" with specific actions/resources
2. Block public access to S3 bucket
3. Restrict database security group to internal subnets

**Follow-up Steps**:
1. Review all IAM policies with `Action: "*"`
2. Audit all S3 buckets for public access
3. Review all security group rules for unrestricted access
4. Enable CloudTrail for audit logging
5. Set up AWS Config rules for continuous compliance
```

### Example Output (All Pass)

```markdown
## AWS Security Review

**Resource**: IAM Policy[ReadOnlyS3Access]

## ✅ No Critical Violations

This configuration follows the principle of least privilege:
- ✅ Actions are specific (GetObject, ListBucket only)
- ✅ Resources are restricted to specific bucket
- ✅ No overly permissive wildcards
- ✅ Conditions restrict access appropriately

Recommendation: Approved for production use.
```

## Error Handling

| Error | Cause | Recovery |
|-------|-------|----------|
| "Invalid JSON/YAML" | Syntax error | Fix JSON/YAML formatting; validate with `jq` or `python -m json.tool` |
| "No policies found" | Empty input | Provide valid IAM policy, S3 bucket policy, or security group config |
| "Ambiguous configuration" | Multiple resources | Extract single resource type (or separate by type) and re-submit |
| "Unsupported resource type" | Custom AWS resource | Focus on standard resources: IAM, S3, EC2 security groups |

## Related Operations

**Combine with other tools**:

```bash
# 1. Export current IAM policy
aws iam get-role-policy --role-name MyRole --policy-name MyPolicy \
  --query 'RolePolicyDocument' > policy.json

# 2. Review with plugin
/plugin run aws-security-review iam-policy-reviewer
# Paste policy.json content

# 3. Apply fixes from recommendation
# Edit policy to follow least privilege

# 4. Update IAM policy
aws iam put-role-policy --role-name MyRole \
  --policy-name MyPolicy --policy-document file://policy.json

# 5. Verify changes
aws iam get-role-policy --role-name MyRole --policy-name MyPolicy
```

## Standards Reference

This skill enforces:

**AWS Well-Architected Framework - Security Pillar**:
- Identity and access management
- Data protection
- Infrastructure protection
- Threat detection and response
- Compliance

**AWS Security Best Practices**:
- Principle of least privilege
- IAM policy conditions
- S3 access control
- Security group rule management

**CIS AWS Foundations Benchmark**:
- IAM access control
- Data protection
- Logging and monitoring
- Networking and access

## Assumptions

- Configurations provided as JSON (AWS standard) or YAML
- No live AWS API calls; analysis is static
- User understands AWS IAM and security concepts
- Least privilege is baseline security requirement

## Performance Target

Review typical AWS configuration in <10 seconds (SC-004)
