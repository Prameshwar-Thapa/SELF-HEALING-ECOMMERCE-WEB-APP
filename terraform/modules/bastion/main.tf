# Generate key pair
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# AWS Key Pair
resource "aws_key_pair" "bastion_key" {
  key_name   = "${var.project_name}-${var.environment}-bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-bastion-key"
  })
}

# Store private key in AWS Secrets Manager
resource "aws_secretsmanager_secret" "bastion_private_key" {
  name = "${var.project_name}-${var.environment}-bastion-private-key-${random_string.suffix.result}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-bastion-private-key"
  })
}

# Random suffix for secret name
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_secretsmanager_secret_version" "bastion_private_key" {
  secret_id     = aws_secretsmanager_secret.bastion_private_key.id
  secret_string = tls_private_key.bastion_key.private_key_pem
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.public_subnet_id
  iam_instance_profile   = var.iam_instance_profile_name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-bastion"
  })
}

# Elastic IP for Bastion
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-bastion-eip"
  })

  depends_on = [aws_instance.bastion]
}
