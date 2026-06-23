# ❌ VIOLATIONS: Examples of common terraform-standards violations

terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = "us-east-1"
}

# ❌ VIOLATION 1: Missing mandatory tags (Environment, Owner)
resource "aws_s3_bucket" "LegacyDataStore" {
  bucket = "legacy-data-store-bucket"

  tags = {
    Name = "Legacy Data Store"
    # Missing: Environment, Owner
  }
}

# ❌ VIOLATION 2: PascalCase naming (should be kebab-case)
resource "aws_s3_bucket" "BackupVault" {
  bucket = "backup-vault"

  tags = {
    Name        = "Backup Vault"
    Environment = "staging"
    Owner       = "ops-team@company.com"
  }
}

# ❌ VIOLATION 3: No encryption on S3 bucket
resource "aws_s3_bucket" "temp-storage" {
  bucket = "temp-storage"

  tags = {
    Name        = "Temporary Storage"
    Environment = "development"
    Owner       = "dev-team@company.com"
  }
  # Missing: server_side_encryption_configuration
}

# ❌ VIOLATION 4: EC2 instance with no tags
resource "aws_instance" "WebServer" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  # Missing: tags with Environment and Owner
}

# ❌ VIOLATION 5: EBS volume without encryption
resource "aws_ebs_volume" "DataVolume" {
  availability_zone = "us-east-1a"
  size              = 50
  # Missing: encrypted = true

  tags = {
    Name        = "data-volume"
    Environment = "production"
    Owner       = "storage-team@company.com"
  }
}

# ❌ VIOLATION 6: Mixed case naming and missing tags
resource "aws_rds_instance" "CompanyDatabase" {
  identifier     = "company_db"
  engine         = "mysql"
  instance_class = "db.t2.micro"

  allocated_storage = 20
  # Missing: tags with Environment and Owner
  # Missing: storage_encrypted = true
}

# ❌ VIOLATION 7: Hardcoded AWS credentials (detected by pre-commit hook)
resource "aws_iam_access_key" "deployment_user" {
  user = aws_iam_user.deploy.name
}

resource "aws_iam_user" "deploy" {
  name = "deployment-service"

  # ❌ HOOK VIOLATION: Hardcoded secret key (blocked at commit time)
  # In a real scenario, this would be:
  # aws_secret_access_key = "AKIAIOSFODNN7EXAMPLE"
  # Never include hardcoded credentials in Terraform!

  tags = {
    Name        = "deployment-service"
    Environment = "production"
    Owner       = "devops-team@company.com"
  }
}

# ❌ VIOLATION 8: Password in resource configuration (hook violation)
resource "aws_db_instance" "legacy-mysql" {
  identifier = "legacy-db"
  engine     = "mysql"

  # ❌ HOOK VIOLATION: Hardcoded password
  # password = "MySecurePassword123!"
  # Use environment variables or AWS Secrets Manager instead

  tags = {
    Name = "legacy-db"
  }
}

# ❌ VIOLATION 9: VPC with incorrect naming
resource "aws_vpc" "MainVpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "main-vpc"
    Environment = "production"
    # Missing: Owner tag
  }
}

# ❌ VIOLATION 10: Subnet with missing tags
resource "aws_subnet" "PrivateSubnet" {
  vpc_id            = aws_vpc.MainVpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet"
    # Missing: Environment, Owner
  }
}

# ❌ VIOLATION 11: Multiple violations - missing tags and encryption
resource "aws_ebs_volume" "AppStorage" {
  availability_zone = "us-east-1b"
  size              = 100
  # Missing: encrypted = true
  # Missing: tags with Environment, Owner
}

# ❌ VIOLATION 12: ElastiCache cluster without tags
resource "aws_elasticache_cluster" "RedisCache" {
  cluster_id           = "app-redis-cache"
  engine               = "redis"
  node_type            = "cache.t3.small"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  # Missing: tags with Environment, Owner

  tags = {
    Name = "redis-cache"
  }
}

# ❌ VIOLATION 13: API Gateway with naming and tagging violations
resource "aws_api_gateway_rest_api" "CompanyAPI" {
  name        = "company-api"
  description = "Main API for company services"

  # Missing: tags with Environment, Owner
}

# ❌ VIOLATION 14: SNS Topic with missing tags
resource "aws_sns_topic" "AlertTopic" {
  name = "alert-topic"

  # Missing: tags with Environment, Owner
}

# ✅ COMMENT: This resource is EXEMPT from tag requirement (data source)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# ✅ COMMENT: Local values are EXEMPT from tag requirement
locals {
  environment = "production"
  region      = "us-east-1"
}

# ✅ COMMENT: Variables and outputs are NOT resource definitions, exempt from tag requirement
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.medium"
}

output "vpc_id" {
  value       = aws_vpc.MainVpc.id
  description = "VPC ID"
}
