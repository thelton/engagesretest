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

data "terraform_remote_state" "ec2_app" {
  backend = "s3"

  config = {
    key     = "ec2-app.tfstate"
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

resource "aws_iam_role" "this" {
  name               = "haproxy-role"
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

data "aws_iam_policy_document" "haproxy-policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "s3:Get*",
      "s3:List*",
      "s3-object-lambda:Get*",
      "s3-object-lambda:List*"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "haproxy-policy" {
  name_prefix = "haproxy-policy"
  policy      = data.aws_iam_policy_document.haproxy-policy.json
  role        = aws_iam_role.this.name
}

resource "aws_iam_instance_profile" "profile" {
  name = "haproxy-role"
  role = aws_iam_role.this.name
}

resource "random_string" "this" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  bucket = "haproxy-sretest-bucket-${random_string.this.result}"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


resource "aws_s3_bucket_object" "config_file_object" {
  bucket = aws_s3_bucket.this.id
  key    = "fluent-bit.conf"
  content = templatefile("haproxy.cfg",
    {
      ip_addrs = data.terraform_remote_state.ec2_app.outputs.private_ip[0]
    }
  )

  etag = filemd5("haproxy.cfg")

  depends_on = [aws_s3_bucket.this]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "lb_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "HAProxy-instance"

  ami                         = "ami-090fa75af13c156b4"
  instance_type               = "t2.micro"
  key_name                    = "testing"
  monitoring                  = true
  vpc_security_group_ids      = [data.terraform_remote_state.sg.outputs.ec2lb_security_group_id]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnets[0]
  associate_public_ip_address = true

  iam_instance_profile = "haproxy-role"

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
yum update
yum install haproxy awslogs -y
systemctl enable haproxy.service
sed -i '0,/log_group_name = \/var\/log\/messages/s//log_group_name = HAProxy-server/' /etc/awslogs/awslogs.conf
systemctl start awslogsd
systemctl enable awslogsd.service
aws s3api get-object --bucket ${aws_s3_bucket_object.config_file_object.id} --key haproxy.cfg /etc/haproxy/haproxy.cfg
mkdir /var/lib/haproxy/dev
systemctl start haproxy.service
echo $'$AddUnixListenSocket /var/lib/haproxy/dev/log\n\n# Send HAProxy messages to a dedicated logfile\n:programname, startswith, "haproxy" {\n  /var/log/haproxy.log\n  stop\n}' > /etc/rsyslog.d/99-haproxy.conf
systemctl restart rsyslog
EOF

  depends_on = [
    aws_iam_instance_profile.profile,
    aws_s3_bucket_object.config_file_object
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
