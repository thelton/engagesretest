data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    key     = "vpc.tfstate"
    bucket  = "terraform.engage.sretest.dev1234"
    region  = "us-east-1"
    profile = "default"
  }
}

module "lb_ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name        = "lb-ec2-sg"
  description = "Security group for LB"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp", "ssh-tcp"]

  egress_with_cidr_blocks = [{
    rule        = "all-all"
    cidr_blocks = "0.0.0.0/0"
  }]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "app_ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name        = "app-ec2-sg"
  description = "Security group for App ssh ports open and 80/443 only from LB SG"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.lb_ec2_sg.security_group_id
    },
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.lb_ec2_sg.security_group_id
    },
    {
      rule                     = "ssh-tcp"
      source_security_group_id = module.lb_ec2_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [{
    rule        = "all-all"
    cidr_blocks = "0.0.0.0/0"
  }]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name        = "rds-sg"
  description = "Security group for RDS DB ports open to App SG"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app_ec2_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [{
    rule        = "all-all"
    cidr_blocks = "0.0.0.0/0"
  }]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
