provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    key = "sg.tfstate"

    bucket  = "terraform.engage.sretest.dev"
    region  = "us-east-1"
    encrypt = "true"

    dynamodb_table = "terraform-locking"
  }
}
