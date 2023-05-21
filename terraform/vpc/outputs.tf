# VPC
# Network specific outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs for private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs for the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets_cidrs" {
  description = "CIDR Ranges of the private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

# AZs
output "azs" {
  description = "A list of availability zones spefified as argument to this module"
  value       = module.vpc.azs
}

# Default security group ID
output "default_security_group_id" {
  description = "The default security group of the VPC"
  value       = module.vpc.default_security_group_id
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = module.vpc.database_subnet_group
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = module.vpc.vpc_main_route_table_id
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = module.vpc.database_route_table_ids
}

output "default_vpc_default_route_table_id" {
  description = "The ID of the default route table"
  value       = module.vpc.default_vpc_default_route_table_id
}

output "default_vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = module.vpc.default_vpc_main_route_table_id
}