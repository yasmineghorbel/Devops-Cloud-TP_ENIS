# Terraform block specifying required providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "custom-terraform-state-bucket-123456-4b50f5d0" # Replace with your S3 bucket name
    key            = "aws-backend/terraform.tfstate"                 # Location of the state file in the bucket
    region         = "us-east-1"                                     # AWS region
    dynamodb_table = "custom-terraform-state-locks-123456"           # Replace with your DynamoDB table name
    encrypt        = true                                            # Enables encryption for the state file
  }
}

# AWS provider configuration
provider "aws" {
  region = "us-east-1"
}

# Generate a random suffix for the S3 bucket name to ensure uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for storing Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.s3_bucket_name}-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
