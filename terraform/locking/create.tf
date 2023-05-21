# Region
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# Terraform state locking setup (S3 bucket)
resource "aws_s3_bucket" "terraform-s3-state" {
  bucket = "terraform.engage.sretest.dev"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "terraform-s3-state"
  }
}

# DynamoDB Terraform State Lock Table
resource "aws_dynamodb_table" "terraform-locking" {
  name         = "terraform-locking"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-locking"
  }
}

