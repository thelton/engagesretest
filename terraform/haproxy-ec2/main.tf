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

# module "lb_ec2_sg" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "4.3.0"

#   name        = "rds-sg"
#   description = "Security group for RDS DB ports open within VPC"
#   vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

#   ingress_cidr_blocks      = ["0.0.0.0/0"]
#   ingress_rules            = ["https-443-tcp", "http-80-tcp", "ssh-tcp"]

#   egress_with_cidr_blocks = [{
#       rule        = "all-all"
#       cidr_blocks = "0.0.0.0/0"
#   }]

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }

module "lb_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "HAProxy-instance"

  instance_type          = "t2.micro"
  # key_name               = "user1"
  monitoring             = true
  vpc_security_group_ids = [data.terraform_remote_state.sg.outputs.ec2lb_security_group_id]
  subnet_id              = data.terraform_remote_state.vpc.outputs.public_subnets[0]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp2"
      volume_size = 30
      encrypted   = false
    }
  ]

  user_data = <<EOF
#!/bin/bash
sudo yum update
sudo yum install git -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
git clone git@github.com:thelton/sre-testapp.git
EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}