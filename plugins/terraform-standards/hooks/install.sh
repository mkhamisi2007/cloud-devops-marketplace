#!/bin/bash
# Install terraform-standards pre-commit hook
# This script sets up the credential-blocking pre-commit hook for Terraform files

set -e

HOOK_DIR=".git/hooks"
HOOK_NAME="pre-commit"
HOOK_FILE="$HOOK_DIR/$HOOK_NAME"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    echo "   Initialize a git repo first: git init"
    exit 1
fi

# Create hooks directory if it doesn't exist
if [ ! -d "$HOOK_DIR" ]; then
    mkdir -p "$HOOK_DIR"
    echo "✅ Created $HOOK_DIR directory"
fi

# Backup existing pre-commit hook if present
if [ -f "$HOOK_FILE" ]; then
    BACKUP_FILE="$HOOK_FILE.terraform-standards.bak"
    cp "$HOOK_FILE" "$BACKUP_FILE"
    echo "⚠️  Backed up existing pre-commit hook to $BACKUP_FILE"
fi

# Create the pre-commit hook script
cat > "$HOOK_FILE" << 'HOOK_SCRIPT'
#!/bin/bash
# terraform-standards pre-commit hook
# Blocks commits with hardcoded credentials in Terraform files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Patterns to detect credentials
PATTERNS=(
    "AKIA[0-9A-Z]{16}"                              # AWS Access Key ID
    "aws_secret_access_key\s*=\s*[\"']"            # AWS Secret Key
    "aws_access_key_id\s*=\s*[\"'][^\"']*[\"']"    # AWS Access Key ID assignment
    "password\s*=\s*[\"'][^\"']*[\"']"             # Hardcoded password
    "-----BEGIN (RSA |OPENSSH |EC |PRIVATE )?KEY"   # PEM private key
    "api_key\s*=\s*[\"'][^\"']*[\"']"              # API key
    "token\s*=\s*[\"'][^\"']*[\"']"                # Token
)

# Get staged Terraform files
STAGED_TF_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.tf$' || true)

if [ -z "$STAGED_TF_FILES" ]; then
    echo -e "${GREEN}[terraform-standards] ✅ No Terraform files in commit. Proceeding.${NC}"
    exit 0
fi

CREDENTIALS_FOUND=false
VIOLATIONS=""

# Check each staged Terraform file for credentials
while IFS= read -r FILE; do
    if [ -z "$FILE" ]; then
        continue
    fi

    LINE_NUM=1
    while IFS= read -r LINE; do
        for PATTERN in "${PATTERNS[@]}"; do
            if echo "$LINE" | grep -qP "$PATTERN"; then
                CREDENTIALS_FOUND=true
                VIOLATIONS="${VIOLATIONS}File: $FILE, Line $LINE_NUM:\n  ${LINE:0:80}\n"
            fi
        done
        ((LINE_NUM++))
    done < "$FILE"
done <<< "$STAGED_TF_FILES"

if [ "$CREDENTIALS_FOUND" = true ]; then
    echo -e "${RED}[terraform-standards] ❌ Credentials detected in staged files${NC}"
    echo ""
    echo -e "Violations:\n$VIOLATIONS"
    echo ""
    echo "Recovery:"
    echo "  1. Remove the hardcoded credential from the file"
    echo "  2. Use one of these alternatives instead:"
    echo "     - AWS provider variable: var.aws_secret"
    echo "     - Environment variable: export AWS_SECRET_ACCESS_KEY=..."
    echo "     - AWS credentials file: ~/.aws/credentials"
    echo "     - AssumeRole: Use IAM role with credentials provider"
    echo "     - AWS Secrets Manager: Use aws_secretsmanager_secret resource"
    echo "  3. Stage the corrected file: git add <file>"
    echo "  4. Retry commit: git commit -m \"...\""
    echo ""
    echo -e "${YELLOW}Reference: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html${NC}"
    echo ""
    echo -e "${YELLOW}To override this check (not recommended): git commit --no-verify${NC}"
    exit 1
else
    echo -e "${GREEN}[terraform-standards] ✅ No credentials detected. Commit allowed.${NC}"
    exit 0
fi
HOOK_SCRIPT

# Make the hook executable
chmod +x "$HOOK_FILE"
echo "✅ Hook installed and made executable: $HOOK_FILE"

echo ""
echo "═════════════════════════════════════════════════════════════"
echo "terraform-standards pre-commit hook installed successfully!"
echo "═════════════════════════════════════════════════════════════"
echo ""
echo "What this hook does:"
echo "  • Runs before each git commit"
echo "  • Scans staged .tf files for hardcoded credentials"
echo "  • Blocks commit if credentials are detected"
echo "  • Provides recovery instructions"
echo ""
echo "Patterns detected:"
echo "  ✓ AWS Access Keys (AKIA...)"
echo "  ✓ AWS Secret Keys"
echo "  ✓ Hardcoded passwords"
echo "  ✓ PEM private keys"
echo "  ✓ API keys and tokens"
echo ""
echo "To bypass this hook (not recommended):"
echo "  git commit --no-verify"
echo ""
echo "To uninstall:"
echo "  rm $HOOK_FILE"
echo ""
