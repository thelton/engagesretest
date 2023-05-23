provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    key = "ec2-lb.tfstate"

    bucket  = "terraform.engage.sretest.dev1234"
    region  = "us-east-1"
    encrypt = "true"

    dynamodb_table = "terraform-locking"
  }
}
