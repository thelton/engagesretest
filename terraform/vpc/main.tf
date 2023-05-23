resource "aws_eip" "nat" {
  count = 3

  vpc = true
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = "main"
  cidr = "10.50.0.0/16"

  azs             = var.azs
  private_subnets = var.private_subnets
  database_subnets = var.database_subnets
  public_subnets = var.public_subnets
  external_nat_ip_ids = "${aws_eip.nat.*.id}"

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
  reuse_nat_ips       = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}