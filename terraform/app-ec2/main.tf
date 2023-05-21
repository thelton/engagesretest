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

module "app_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  count = 2

  name = "app-ec2-${each.key}"

  ami = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  key_name               = "user1"
  monitoring             = true
  vpc_security_group_ids = [data.terraform_remote_state.sg.outputs.ec2app_security_group_id]
  subnet_id              = subnet_id = tolist(data.terraform_remote_state.vpc.outputs.private_subnets)[count.index % length(data.terraform_remote_state.vpc.outputs.vpc_id)]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp2"
      volume_size = 30
      encrypted   = true
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
git clone https://github.com/Unleash/unleash-docker.git /home/ec2-user
docker volume create postgresdata
EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
