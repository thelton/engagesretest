data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    key     = "vpc.tfstate"
    bucket  = "terraform.engage.sretest.dev1234"
    region  = "us-east-1"
    profile = "default"
  }
}

data "terraform_remote_state" "sg" {
  backend = "s3"

  config = {
    key     = "sg.tfstate"
    bucket  = "terraform.engage.sretest.dev1234"
    region  = "us-east-1"
    profile = "default"
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"

  config = {
    key     = "rds.tfstate"
    bucket  = "terraform.engage.sretest.dev1234"
    region  = "us-east-1"
    profile = "default"
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "sreTestApp"
  retention_in_days = 14

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "sreTestApp-ec2-stream"
  log_group_name = aws_cloudwatch_log_group.this.name
}

resource "aws_iam_role" "this" {
  name               = "app-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "policy1" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "policy2" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "policy3" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess"
}

resource "aws_iam_role_policy_attachment" "policy4" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

data "aws_iam_policy_document" "ec2-cloudwatch-policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "ec2-cloudwatch-policy" {
  name_prefix = "ec2-cloudwatch-policy"
  policy      = data.aws_iam_policy_document.ec2-cloudwatch-policy.json
  role        = aws_iam_role.this.name
}

resource "aws_iam_instance_profile" "profile" {
  name = "app-ec2-role"
  role = aws_iam_role.this.name
}

module "app_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  count = 2
  name  = "app-ec2-${count.index}"

  ami                    = "ami-090fa75af13c156b4"
  instance_type          = "t2.micro"
  key_name               = "testing"
  monitoring             = true
  vpc_security_group_ids = [data.terraform_remote_state.sg.outputs.ec2app_security_group_id]
  # subnet_id              = tolist(data.terraform_remote_state.vpc.outputs.private_subnets)[count.index % length(data.terraform_remote_state.vpc.outputs.private_subnets)]
  subnet_id                   = tolist(data.terraform_remote_state.vpc.outputs.public_subnets)[count.index % length(data.terraform_remote_state.vpc.outputs.public_subnets)]
  associate_public_ip_address = true

  iam_instance_profile = "app-ec2-role"

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
set -x 
yum update
yum install git jq -y
amazon-linux-extras install docker -y
service docker start
systemctl enable docker
usermod -a -G docker ec2-user
systemctl enable docker.service
systemctl enable containerd.service
curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
git clone https://github.com/thelton/sre-testapp.git /app
export DBHOST=${data.terraform_remote_state.rds.outputs.db_instance_endpoint}
cd /app
chown 
chmod +x launch.sh
./launch.sh
EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
