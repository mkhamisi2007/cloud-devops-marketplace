# Quickstart: Cloud DevOps Plugin Marketplace

**Purpose**: End-to-end validation that the marketplace plugins work independently and as intended  
**Date**: 2026-06-22

This guide walks through installing and validating each plugin separately, demonstrating independent functionality.

---

## Prerequisites

- Claude Code CLI or Claude Code VS Code extension installed
- Git 2.0+ for terraform-standards hook
- kubectl available for k8s-troubleshooter validation
- Basic familiarity with Terraform, Kubernetes, and AWS

---

## Part 1: terraform-standards Plugin Validation

### 1.1 Installation

```bash
# Copy the plugin to your Claude Code installation
cp -r plugins/terraform-standards ~/.claude/plugins/terraform-standards

# Verify installation
ls ~/.claude/plugins/terraform-standards/.claude-plugin/plugin.json
```

**Expected Output**: File exists and contains plugin metadata

### 1.2 Validate: Pre-Apply Checklist Command

**Setup**: Create a test Terraform file with intentional violations

```hcl
# test-terraform/main.tf
resource "aws_s3_bucket" "MyBackupBucket" {  # ❌ Violation: PascalCase naming
  bucket = "backup-bucket-prod"
  
  # ❌ Violation: Missing encryption
  # Should have: server_side_encryption_configuration block
}

resource "aws_instance" "web_server" {
  # ❌ Violation: Missing tags
  ami           = "ami-12345678"
  instance_type = "t3.micro"
}

resource "aws_ebs_volume" "data_volume" {
  availability_zone = "us-east-1a"
  size              = 100
  # ❌ Violation: Missing encryption
  # Should have: encrypted = true
  
  # ✅ Correct: Has Owner tag (but missing Environment)
  tags = {
    Owner = "DevOps"
  }
}
```

**Run Checklist**:

```bash
claude code run terraform-standards pre-apply-checklist test-terraform/
```

**Expected Output**:
```
# terraform-standards Checklist Report

## ❌ Violations Found

### Missing Tags (2 violations)
- Resource: aws_s3_bucket "MyBackupBucket"
  Missing: Environment, Owner
  
- Resource: aws_instance "web_server"
  Missing: Environment, Owner

### Naming Violations (1 violation)
- Resource: aws_s3_bucket "MyBackupBucket"
  Current: MyBackupBucket
  Suggested: my-backup-bucket

### Encryption Violations (2 violations)
- Resource: aws_s3_bucket "MyBackupBucket"
  Missing: server_side_encryption_configuration
  
- Resource: aws_ebs_volume "data_volume"
  Missing: encrypted = true
```

**Verification**: ✅ Command correctly identified all 5 violations

### 1.3 Validate: Pre-Commit Hook

**Setup**: Initialize git repo and install hook

```bash
cd test-terraform
git init
cp ../plugins/terraform-standards/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Test Case 1: Hardcoded AWS Credential**

```hcl
# test-terraform/secret.tf
resource "aws_provider" "main" {
  region              = "us-east-1"
  access_key          = "AKIAIOSFODNN7EXAMPLE"        # ❌ Hardcoded!
  secret_access_key   = "wJalrXUtnFEMI/K7MDENG/EXAMPLE"  # ❌ Hardcoded!
}
```

**Run Commit**:

```bash
git add secret.tf
git commit -m "Add AWS configuration"
```

**Expected Output**:
```
[terraform-standards] ❌ Credentials detected in staged files

File: secret.tf, Line 4:
  access_key = "AKIAIOSFODNN7EXAMPLE"

File: secret.tf, Line 5:
  secret_access_key = "wJalrXUtnFEMI/K7MDENG/EXAMPLE"

Recovery:
  1. Remove hardcoded credentials
  2. Use environment variables: export AWS_ACCESS_KEY_ID=...
  3. Or use assume role: add assume_role block
  4. Stage corrected file and retry commit

Reference: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
```

**Verification**: ✅ Hook blocked commit and provided recovery steps

**Test Case 2: Clean Commit (No Credentials)**

```bash
# Remove hardcoded credentials, use provider config instead
rm secret.tf

# Clean commit
git add -A
git commit -m "Use AWS environment variables for credentials"
```

**Expected Output**:
```
[terraform-standards] ✅ No credentials detected. Commit allowed.
[main (root-commit) abc1234] Use AWS environment variables...
```

**Verification**: ✅ Hook allowed clean commit

---

## Part 2: k8s-troubleshooter Plugin Validation

### 2.1 Installation

```bash
# Copy the plugin
cp -r plugins/k8s-troubleshooter ~/.claude/plugins/k8s-troubleshooter

# Verify
ls ~/.claude/plugins/k8s-troubleshooter/.claude-plugin/plugin.json
```

### 2.2 Validate: Pod Diagnosis Agent

**Setup**: Get real (or sample) kubectl output

```bash
# If connected to real cluster:
kubectl describe pods --all-namespaces > test-k8s/pod-output.txt

# Or use sample output (simulated pod failure):
```

**Sample Input** (`test-k8s/pod-output.txt`):
```
Name:         api-server-1
Namespace:    production
Status:       CrashLoopBackOff
Container ID: docker://...
Last State:   Terminated (Exit Code: 1)
Reason:       Error
Log Tail:     panic: connection refused on port 8080

Name:         worker-pod-2
Namespace:    default
Status:       Pending
Events:
  - Type: Warning
    Reason: Insufficient Memory
    Message: 0/2 nodes are available: insufficient memory
```

**Run Diagnosis**:

```bash
claude code run k8s-troubleshooter k8s-diagnosis < test-k8s/pod-output.txt
```

**Expected Output**:
```
## Pod Diagnosis Report

### Pod: production/api-server-1
**State**: CrashLoopBackOff
**Likely Cause**: Application startup failure
**Evidence**: Logs show "panic: connection refused on port 8080"
**Remediation Steps**:
1. Verify application listens on port 8080 during startup
2. Check if liveness probe initialDelaySeconds is sufficient
3. View full logs: kubectl logs api-server-1 -c api
4. Fix application startup or increase probe delay

### Pod: default/worker-pod-2
**State**: Pending
**Likely Cause**: Insufficient cluster memory
**Evidence**: Events show "insufficient memory" warning for 5 minutes
**Remediation Steps**:
1. Check cluster resources: kubectl top nodes
2. Free memory or add nodes: kubectl scale...
3. Reduce worker memory request if safe
```

**Verification**: ✅ Agent correctly diagnosed both failures

### 2.3 Validate: Manifest Validation Skill

**Setup**: Create a Deployment manifest with violations

```yaml
# test-k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: api:latest                    # ❌ No tag specificity
        # ❌ Missing resource requests/limits
        # ❌ Missing health probes
        ports:
        - containerPort: 8080
```

**Run Validation**:

```bash
claude code run k8s-troubleshooter manifest-validator test-k8s/deployment.yaml
```

**Expected Output**:
```
# Kubernetes Manifest Validation Report

**Resource**: apps/v1/Deployment[api-server]

## ❌ Violations Found (3)

### Missing Resource Requests/Limits
**Severity**: HIGH
**Container**: api
**Fix**: Add to container spec:
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "256Mi"

### Missing Liveness Probe
**Severity**: HIGH
**Container**: api
**Fix**: Add to container spec:
  livenessProbe:
    httpGet:
      path: /health
      port: 8080
    initialDelaySeconds: 15

### Image Uses "latest" Tag
**Severity**: MEDIUM
**Container**: api
**Current**: api:latest
**Fix**: Use specific version: api:1.0.0
```

**Verification**: ✅ Skill correctly identified all three violations

---

## Part 3: aws-security-review Plugin Validation

### 3.1 Installation

```bash
# Copy the plugin
cp -r plugins/aws-security-review ~/.claude/plugins/aws-security-review

# Verify
ls ~/.claude/plugins/aws-security-review/.claude-plugin/plugin.json
```

### 3.2 Validate: IAM Policy Reviewer Skill

**Setup**: Create an overly permissive IAM policy

```json
# test-aws/policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",                    # ❌ Allows all actions
      "Resource": "*"                   # ❌ On all resources
    }
  ]
}
```

**Run Review**:

```bash
claude code run aws-security-review iam-policy-reviewer test-aws/policy.json
```

**Expected Output**:
```
## AWS Security Review

### Summary
- Total resources reviewed: 1
- Critical violations: 1
- High violations: 0

## ❌ Critical Violations

### IAM Policy (Statement 1)
**Severity**: CRITICAL
**Issue**: Action is "*" and Resource is "*"
**Risk**: Allows all AWS actions on all resources (admin access)

**Fix**: Narrow to specific actions and resources:
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "ec2:DescribeInstances"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket/*",
        "arn:aws:ec2:*:*:instance/*"
      ]
    }
  ]
}
```

**Verification**: ✅ Skill correctly flagged overly permissive policy

**Setup 2**: Create a public S3 bucket policy

```json
# test-aws/bucket-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",                 # ❌ Public access!
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::backup-vault/*"
    }
  ]
}
```

**Run Review**:

```bash
claude code run aws-security-review iam-policy-reviewer test-aws/bucket-policy.json
```

**Expected Output**:
```
## AWS Security Review

### Summary
- Total resources reviewed: 1
- Critical violations: 1

## ❌ Critical Violations

### S3 Bucket Policy
**Severity**: CRITICAL
**Issue**: Principal is "*" (public read access)
**Risk**: Anyone on the internet can download from s3://backup-vault/

**Fix**: Restrict to specific principal:
{
  "Principal": {
    "AWS": "arn:aws:iam::123456789012:user/BackupOperator"
  }
}

Also enable Block Public Access.
```

**Verification**: ✅ Skill correctly identified public bucket exposure

**Setup 3**: Create a security group with unrestricted SSH

```json
# test-aws/security-group.json
{
  "GroupName": "web-sg",
  "IpPermissions": [
    {
      "FromPort": 22,
      "ToPort": 22,
      "IpProtocol": "tcp",
      "IpRanges": [{"CidrIp": "0.0.0.0/0"}]  # ❌ SSH open to internet!
    }
  ]
}
```

**Run Review**:

```bash
claude code run aws-security-review iam-policy-reviewer test-aws/security-group.json
```

**Expected Output**:
```
## AWS Security Review

### Summary
- Total resources reviewed: 1
- Critical violations: 1

## ❌ Critical Violations

### Security Group: web-sg
**Severity**: CRITICAL
**Issue**: Allows SSH (port 22) from 0.0.0.0/0
**Risk**: SSH brute-force attacks possible; unauthorized access likely

**Fix**: Restrict to specific IPs:
{
  "FromPort": 22,
  "IpRanges": [{"CidrIp": "203.0.113.0/24"}]  # Your office IP
}
```

**Verification**: ✅ Skill correctly flagged unrestricted SSH

---

## Part 4: Plugin Independence Validation

**Objective**: Verify each plugin works independently without others installed

### 4.1 Remove terraform-standards

```bash
rm -rf ~/.claude/plugins/terraform-standards

# Try to run k8s-troubleshooter
claude code run k8s-troubleshooter k8s-diagnosis < test-k8s/pod-output.txt
```

**Expected Result**: ✅ k8s-troubleshooter works; no dependency on terraform-standards

### 4.2 Remove k8s-troubleshooter

```bash
rm -rf ~/.claude/plugins/k8s-troubleshooter

# Try to run aws-security-review
claude code run aws-security-review iam-policy-reviewer test-aws/policy.json
```

**Expected Result**: ✅ aws-security-review works; no dependency on k8s-troubleshooter

### 4.3 Remove aws-security-review

```bash
rm -rf ~/.claude/plugins/aws-security-review

# Reinstall terraform-standards
cp -r plugins/terraform-standards ~/.claude/plugins/terraform-standards

# Run checklist
claude code run terraform-standards pre-apply-checklist test-terraform/
```

**Expected Result**: ✅ terraform-standards works; no dependency on aws-security-review

---

## Summary: Acceptance Criteria

✅ **SC-001**: Each plugin installs independently  
✅ **SC-002**: terraform-standards blocks commits with hardcoded credentials  
✅ **SC-003**: k8s-troubleshooter diagnoses pod issues in <10 seconds  
✅ **SC-004**: aws-security-review identifies security gaps quickly  
✅ **SC-005**: All plugins have English documentation  
✅ **SC-006**: Hooks log clear messages when blocking actions  

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Plugin not found | Verify installation path matches Claude Code config |
| Command not recognized | Ensure plugin.json has correct entrypoint names |
| Git hook not running | Run `chmod +x .git/hooks/pre-commit` |
| kubectl command not found | Install kubectl or ensure it's in PATH |
| JSON parse error | Validate JSON/YAML syntax in test files |

---

## Next Steps

Once all acceptance criteria pass:
1. Run `/speckit-tasks` to generate implementation task list
2. Begin Phase 2 implementation of plugin functionality
3. Establish CI/CD validation for each plugin
4. Set up marketplace documentation site
