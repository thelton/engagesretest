module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = "main"
  cidr = "10.50.0.0/16"

  azs             = var.azs
  private_subnets = var.private_subnets
  database_subnets = var.database_subnets
  public_subnets = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}