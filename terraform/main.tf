# Terraform / OpenTofu Configuration for Local DevLab Cloud Infrastructure
# Connects to Floci (AWS Emulator running at http://localhost:4566)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider to direct all API calls to Floci local emulator
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sqs      = "http://localhost:4566"
    sns      = "http://localhost:4566"
    lambda   = "http://localhost:4566"
  }
}

# 1. Create a sample S3 Bucket in local Floci emulator
resource "aws_s3_bucket" "devlab_bucket" {
  bucket = "devlab-local-storage"
}

# 2. Create a sample DynamoDB Table in local Floci emulator
resource "aws_dynamodb_table" "devlab_table" {
  name           = "devlab-kv-store"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Outputs
output "s3_bucket_name" {
  value = aws_s3_bucket.devlab_bucket.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.devlab_table.name
}
