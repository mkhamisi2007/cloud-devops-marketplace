# ✅ COMPLIANT: Properly tagged, named, and encrypted resources

terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 Bucket with encryption and mandatory tags
resource "aws_s3_bucket" "data-warehouse" {
  bucket = "company-data-warehouse-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Data Warehouse Bucket"
    Environment = "production"
    Owner       = "data-team@company.com"
    CostCenter  = "analytics"
  }
}

# Enable encryption on S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "data-warehouse" {
  bucket = aws_s3_bucket.data-warehouse.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "data-warehouse" {
  bucket = aws_s3_bucket.data-warehouse.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# EC2 Instance with mandatory tags
resource "aws_instance" "app-server-primary" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.private-a.id
  iam_instance_profile   = aws_iam_instance_profile.app-server.name
  monitoring             = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true  # ✅ Encryption enabled
  }

  tags = {
    Name        = "app-server-primary"
    Environment = "production"
    Owner       = "platform-team@company.com"
    Role        = "application"
  }
}

# EBS Volume with encryption
resource "aws_ebs_volume" "backup-storage" {
  availability_zone = "us-east-1a"
  size              = 100
  type              = "gp3"
  encrypted         = true  # ✅ Encryption enabled

  tags = {
    Name        = "backup-storage"
    Environment = "production"
    Owner       = "backup-team@company.com"
  }
}

# RDS Database with mandatory tags
resource "aws_db_instance" "postgres-primary" {
  identifier     = "company-db-primary"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.medium"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true  # ✅ Encryption enabled

  db_name  = "companydb"
  username = var.db_master_user
  password = var.db_master_password  # ✅ Using variable, not hardcoded

  multi_az               = true
  publicly_accessible    = false
  skip_final_snapshot    = false
  final_snapshot_identifier = "company-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name        = "postgres-primary"
    Environment = "production"
    Owner       = "database-team@company.com"
    Backup      = "daily"
  }
}

# VPC Security Group with mandatory tags
resource "aws_security_group" "app-tier" {
  name        = "app-tier-sg"
  description = "Security group for application tier"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "app-tier-sg"
    Environment = "production"
    Owner       = "network-team@company.com"
  }
}

# Data source (exempt from mandatory tags)
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Variables
variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for instances"
}

variable "db_master_user" {
  type        = string
  description = "Database master username"
  sensitive   = true
}

variable "db_master_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
}

# Outputs
output "app-server-ip" {
  value       = aws_instance.app-server-primary.private_ip
  description = "Private IP of app server"
}

output "database-endpoint" {
  value       = aws_db_instance.postgres-primary.endpoint
  description = "RDS database endpoint"
}

# Data sources
data "aws_caller_identity" "current" {}

# Local values (exempt from mandatory tags)
locals {
  common_tags = {
    Terraform   = "true"
    Project     = "cloud-infrastructure"
    ManagedBy   = "terraform"
  }
}
