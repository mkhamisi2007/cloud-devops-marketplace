# Testing Guide: terraform-standards Plugin

This document describes how to test the terraform-standards plugin to ensure it correctly validates Terraform files and blocks commits with credentials.

## Test Environment Setup

### Prerequisites

- Claude Code (with plugin support)
- Git (2.0+)
- Terraform (0.12+)
- Bash shell (for running test scripts)

### Quick Setup

```bash
# 1. Navigate to a test directory
mkdir -p /tmp/terraform-test
cd /tmp/terraform-test

# 2. Initialize a git repository
git init
git config user.email "test@example.com"
git config user.name "Test User"

# 3. Copy example Terraform files
cp plugins/terraform-standards/examples/*.tf .
```

---

## Test Suite

### Test 1: Pre-Apply Checklist - All Pass

**Purpose**: Verify the command reports no violations when Terraform is compliant

**Steps**:
1. Copy `compliant.tf` to test directory
2. Run the checklist command
3. Verify exit code 0 and "All Checks Pass" message

**Command**:
```bash
/plugin run terraform-standards pre-apply-checklist
# Enter: ./compliant.tf
```

**Expected Output**:
- Exit code: 0
- Report: "✅ All Checks Pass"
- No violations listed

**Validation**:
```bash
if [ $? -eq 0 ]; then
    echo "✅ Test 1 PASSED: Compliant file returns exit code 0"
else
    echo "❌ Test 1 FAILED: Expected exit code 0"
fi
```

---

### Test 2: Pre-Apply Checklist - Missing Tags

**Purpose**: Verify the command flags resources missing mandatory Environment and Owner tags

**Steps**:
1. Create test file with missing tags:
   ```terraform
   resource "aws_s3_bucket" "test_bucket" {
     bucket = "test-bucket"
     # Missing: tags with Environment, Owner
   }
   ```
2. Run the checklist command
3. Verify violation is reported

**Command**:
```bash
/plugin run terraform-standards pre-apply-checklist
# Enter: ./test_missing_tags.tf
```

**Expected Output**:
- Exit code: 1
- Section: "Missing Tags"
- Resource: `aws_s3_bucket "test_bucket"`
- Violation message: "Missing: Environment, Owner"

**Validation**:
```bash
OUTPUT=$(/plugin run terraform-standards pre-apply-checklist 2>&1)
if echo "$OUTPUT" | grep -q "Missing Tags"; then
    echo "✅ Test 2 PASSED: Missing tags detected"
else
    echo "❌ Test 2 FAILED: Missing tags not detected"
fi
```

---

### Test 3: Pre-Apply Checklist - Naming Violations

**Purpose**: Verify the command flags resources with non-kebab-case names

**Steps**:
1. Create test file with PascalCase resource name:
   ```terraform
   resource "aws_s3_bucket" "S3BucketProd" {
     bucket = "s3-bucket-prod"
     tags = {
       Environment = "prod"
       Owner = "team@company.com"
     }
   }
   ```
2. Run the checklist command
3. Verify naming violation is reported

**Command**:
```bash
/plugin run terraform-standards pre-apply-checklist
# Enter: ./test_naming.tf
```

**Expected Output**:
- Exit code: 1
- Section: "Naming Violations"
- Current: `S3BucketProd`
- Suggested: `s3-bucket-prod`

**Validation**:
```bash
OUTPUT=$(/plugin run terraform-standards pre-apply-checklist 2>&1)
if echo "$OUTPUT" | grep -q "Naming Violations" && echo "$OUTPUT" | grep -q "s3-bucket-prod"; then
    echo "✅ Test 3 PASSED: Naming violations detected"
else
    echo "❌ Test 3 FAILED: Naming violations not detected"
fi
```

---

### Test 4: Pre-Apply Checklist - Encryption Violations

**Purpose**: Verify the command flags storage resources without encryption

**Steps**:
1. Create test file with unencrypted S3 bucket:
   ```terraform
   resource "aws_s3_bucket" "data-store" {
     bucket = "data-store"
     tags = {
       Environment = "prod"
       Owner = "team@company.com"
     }
     # Missing: server_side_encryption_configuration
   }
   ```
2. Run the checklist command
3. Verify encryption violation is reported

**Command**:
```bash
/plugin run terraform-standards pre-apply-checklist
# Enter: ./test_encryption.tf
```

**Expected Output**:
- Exit code: 1
- Section: "Encryption Violations"
- Resource: `aws_s3_bucket "data-store"`
- Violation: "Missing: server_side_encryption_configuration"

---

### Test 5: Pre-Apply Checklist - Multiple Violations

**Purpose**: Verify the command reports all violation types in one file

**Steps**:
1. Use `violations.tf` from examples directory
2. Run the checklist command
3. Verify all three violation types are reported

**Command**:
```bash
/plugin run terraform-standards pre-apply-checklist
# Enter: plugins/terraform-standards/examples/violations.tf
```

**Expected Output**:
- Exit code: 1
- Sections: "Missing Tags", "Naming Violations", "Encryption Violations"
- Multiple violations in each section
- Total violations count > 5

---

### Test 6: Pre-Commit Hook - Block Credentials

**Purpose**: Verify the hook blocks commits with hardcoded AWS credentials

**Steps**:
1. Initialize git repository in test directory:
   ```bash
   cd /tmp/terraform-test
   git init
   git config user.email "test@example.com"
   git config user.name "Test User"
   ```

2. Install the hook:
   ```bash
   bash plugins/terraform-standards/hooks/install.sh
   ```

3. Create a file with hardcoded credentials:
   ```terraform
   resource "aws_iam_user" "test" {
     name = "test-user"
   }
   
   # Hardcoded AWS Secret Key
   output "secret_key" {
     value = "AKIAIOSFODNN7EXAMPLE"
   }
   ```

4. Attempt to commit:
   ```bash
   git add test.tf
   git commit -m "Add test file"
   ```

5. Verify commit is blocked

**Expected Output**:
- Exit code: 1 (commit blocked)
- Message: `[terraform-standards] ❌ Credentials detected in staged files`
- File and line number shown
- Recovery instructions provided

**Validation**:
```bash
git add test.tf
if ! git commit -m "Add test file" 2>&1 | grep -q "Credentials detected"; then
    echo "❌ Test 6 FAILED: Hook did not block credentials"
else
    echo "✅ Test 6 PASSED: Hook blocked credentials"
fi
```

---

### Test 7: Pre-Commit Hook - Allow Clean Commit

**Purpose**: Verify the hook allows commits without credentials

**Steps**:
1. Create a clean Terraform file (no hardcoded credentials):
   ```terraform
   resource "aws_s3_bucket" "test-bucket" {
     bucket = "test-bucket"
     tags = {
       Environment = "test"
       Owner = "test@company.com"
     }
   }
   ```

2. Commit the file:
   ```bash
   git add clean.tf
   git commit -m "Add clean Terraform file"
   ```

3. Verify commit succeeds

**Expected Output**:
- Exit code: 0 (commit allowed)
- Message: `[terraform-standards] ✅ No credentials detected. Commit allowed.`

**Validation**:
```bash
git add clean.tf
if git commit -m "Add clean file" 2>&1 | grep -q "No credentials detected"; then
    echo "✅ Test 7 PASSED: Hook allowed clean commit"
else
    echo "❌ Test 7 FAILED: Hook rejected clean commit"
fi
```

---

### Test 8: Syntax Error Handling

**Purpose**: Verify the command handles invalid Terraform syntax gracefully

**Steps**:
1. Create file with invalid HCL:
   ```terraform
   resource "aws_s3_bucket" "test" {
     bucket = "test"
     invalid_syntax = [
   }
   ```

2. Run the checklist command
3. Verify appropriate error message and exit code 2

**Expected Output**:
- Exit code: 2 (syntax error)
- Error message mentions syntax error and line number
- Suggestion to run `terraform validate`

---

### Test 9: Data Source Exemption

**Purpose**: Verify that data sources are exempt from tagging requirements

**Steps**:
1. Create file with data source (no tags) and resource with tags:
   ```terraform
   data "aws_ami" "ubuntu" {
     most_recent = true
   }
   
   resource "aws_instance" "app" {
     ami = data.aws_ami.ubuntu.id
     tags = {
       Environment = "prod"
       Owner = "team@company.com"
     }
   }
   ```

2. Run checklist
3. Verify no violation for data source

**Expected Output**:
- Exit code: 0 (no violations)
- Data source not flagged for missing tags

---

### Test 10: Performance Test

**Purpose**: Verify command completes in acceptable time

**Steps**:
1. Create large Terraform file (>500 lines, 50+ resources)
2. Run checklist and measure execution time
3. Verify completion in <10 seconds

**Command**:
```bash
time /plugin run terraform-standards pre-apply-checklist
# Enter: ./large_terraform_file.tf
```

**Expected Output**:
- Real time: < 10 seconds
- CPU time: < 5 seconds

---

## Automated Test Script

Create `test_terraform_standards.sh`:

```bash
#!/bin/bash
set -e

TEST_DIR="/tmp/terraform-test"
PASSED=0
FAILED=0

run_test() {
    local TEST_NAME="$1"
    local TEST_CMD="$2"
    local EXPECTED_RESULT="$3"
    
    echo "Running: $TEST_NAME"
    
    if eval "$TEST_CMD"; then
        echo "✅ $TEST_NAME PASSED"
        ((PASSED++))
    else
        echo "❌ $TEST_NAME FAILED"
        ((FAILED++))
    fi
}

# Run all tests
run_test "Test 1: Compliant file passes" "..."
run_test "Test 2: Missing tags detected" "..."
run_test "Test 3: Naming violations detected" "..."
# ... continue for all tests

echo ""
echo "════════════════════════════════════════"
echo "Test Results: $PASSED passed, $FAILED failed"
echo "════════════════════════════════════════"

exit $FAILED
```

---

## Manual Testing Checklist

- [ ] Pre-apply checklist identifies all missing tags
- [ ] Pre-apply checklist flags kebab-case violations
- [ ] Pre-apply checklist detects encryption gaps
- [ ] Pre-apply checklist exits with correct codes (0, 1, 2)
- [ ] Pre-commit hook blocks credentials
- [ ] Pre-commit hook allows clean commits
- [ ] Hook provides recovery instructions
- [ ] Plugin handles invalid Terraform gracefully
- [ ] Data sources are exempt from tagging
- [ ] Performance is acceptable (<10 seconds)

---

## Regression Testing

Before each release:

1. Run full test suite against compliant.tf and violations.tf
2. Verify exit codes are correct
3. Test hook on real git repository
4. Verify no false positives in credential detection
5. Performance test on large files (>1000 lines)

