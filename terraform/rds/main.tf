data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    key = "vpc.tfstate"
    bucket  = "terraform.engage.sretest.dev"
    region  = "us-east-1"
    profile = "default"
  }
}

data "terraform_remote_state" "sg" {
  backend = "s3"

  config = {
    key = "sg.tfstate"
    bucket  = "terraform.engage.sretest.dev"
    region  = "us-east-1"
    profile = "default"
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}
 
resource "aws_secretsmanager_secret" "secret" {
   name = "postgres-creds"
}
 
resource "aws_secretsmanager_secret_version" "sec_version" {
  secret_id = aws_secretsmanager_secret.secret.id
  secret_string = <<EOF
   {
    "username": "pguser",
    "password": "${random_password.password.result}"
   }
EOF
}
 
data "aws_secretsmanager_secret" "secret" {
  arn = aws_secretsmanager_secret.secret.arn
}
 
data "aws_secretsmanager_secret_version" "sec_version" {
  secret_id = data.aws_secretsmanager_secret.secret.arn
}
 
# locals {
#   db_creds = jsondecode(data.aws_secretsmanager_secret_version.sec_version.secret_string)
# }

# module "rds_sg" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "4.3.0"

#   name        = "rds-sg"
#   description = "Security group for RDS DB ports open within VPC"
#   vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

#   ingress_with_source_security_group_id = [
#     {
#       rule                     = "postgresql-tcp"
#       source_security_group_id = data.aws_security_group.default.id
#     }
#   ]

#   egress_with_cidr_blocks = [{
#       rule        = "all-all"
#       cidr_blocks = "0.0.0.0/0"
#   }]

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 5.9"

  identifier = "sre-testapp-db"

  engine            = "postgres"
  engine_version    = "15.3"
  family = "postgres15"
  major_engine_version = "15"

  instance_class    = "db.t3.micro"
  allocated_storage = 5

  multi_az = true

  db_name  = "students"
  username = jsondecode(data.aws_secretsmanager_secret_version.sec_version.secret_string).username
  password = jsondecode(data.aws_secretsmanager_secret_version.sec_version.secret_string).password
  port     = "5432"

  vpc_security_group_ids = [data.terraform_remote_state.sg.outputs.rds_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true
  backup_retention_period         = 1
  storage_encrypted = true

  # Deletion protection normally true but disabled for this purpose
  deletion_protection = false

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# module "replica" {
#   source = "../../"

#   identifier = "sre-testapp-db-replica"

#   # Source database. For cross-region use db_instance_arn
#   replicate_source_db    = module.db.db_instance_id
#   create_random_password = false

#   engine               = local.engine
#   engine_version       = local.engine_version
#   family               = local.family
#   major_engine_version = local.major_engine_version
#   instance_class       = local.instance_class

#   allocated_storage     = local.allocated_storage
#   max_allocated_storage = local.max_allocated_storage

#   port = local.port

#   multi_az               = false
#   vpc_security_group_ids = [module.security_group.security_group_id]

#   maintenance_window              = "Tue:00:00-Tue:03:00"
#   backup_window                   = "03:00-06:00"
#   enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

#   backup_retention_period = 0
#   skip_final_snapshot     = true
#   deletion_protection     = false
#   storage_encrypted       = true

#   tags = local.tags
# }


