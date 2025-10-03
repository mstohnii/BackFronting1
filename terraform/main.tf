locals {
  name_prefix = var.project_name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Use default VPC and its first public subnet if none provided
data "aws_vpc" "selected" {
  count   = var.vpc_id == null ? 1 : 0
  default = true
}

locals {
  vpc_id_effective = var.vpc_id != null ? var.vpc_id : (length(data.aws_vpc.selected) > 0 ? data.aws_vpc.selected[0].id : null)
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id_effective]
  }
}

data "aws_subnet" "first" {
  id = var.subnet_id != null ? var.subnet_id : data.aws_subnets.selected.ids[0]
}

resource "aws_security_group" "instance" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for ${local.name_prefix} EC2"
  vpc_id      = local.vpc_id_effective

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg"
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name               = "${local.name_prefix}-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

data "template_cloudinit_config" "userdata" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/userdata.sh", {
      github_repo_url = var.github_repo_url
      compose_file    = var.use_prod_compose ? "deploy/docker-compose.prod.yml" : var.compose_file
      project_name    = var.project_name
    })
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.first.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_name

  user_data_base64 = data.template_cloudinit_config.userdata.rendered

  tags = {
    Name        = "${local.name_prefix}-ec2"
    Project     = local.name_prefix
    Environment = "prod"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "public_ip" {
  value       = aws_instance.app.public_ip
  description = "Public IP of the application EC2 instance"
}

output "public_dns" {
  value       = aws_instance.app.public_dns
  description = "Public DNS name of the application EC2 instance"
}

output "app_url" {
  value       = "http://${aws_instance.app.public_dns}"
  description = "Base URL of the frontend"
}

output "instance_id" {
  value       = aws_instance.app.id
  description = "ID of the EC2 instance"
}


