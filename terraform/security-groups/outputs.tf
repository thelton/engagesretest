output "ec2lb_security_group_id" {
  description = "The ID of the EC2 LB security group"
  value       = module.lb_ec2_sg.security_group_id
}

output "ec2app_security_group_id" {
  description = "The ID of the EC2 App security group"
  value       = module.app_ec2_sg.security_group_id
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group"
  value       = module.rds_sg.security_group_id
}