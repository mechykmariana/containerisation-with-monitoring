terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.94.1"
    }
  }
}

provider "aws" {
  region = var.region
}

# SSH Key Pair
resource "aws_key_pair" "thesis_key_pair" {
  key_name   = var.key_name
  public_key = file("${path.module}/id_rsa_terraform.pub")
}

# Security Group
resource "aws_security_group" "allow_inbound" {
  name        = "allow-inbound"
  description = "Allow SSH, App, and Monitoring ports"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    description = "Frontend"
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Backend"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "thesis-app-sg"
  }
}

# Ubuntu AMI (Jammy 22.04)
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.thesis_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.allow_inbound.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  provisioner "file" {
  source      = "${path.module}/../../docker-compose.yml"
  destination = "/home/ubuntu/app/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../alertmanager"
    destination = "/home/ubuntu/app/alertmanager"
  }

  provisioner "file" {
    source      = "${path.module}/../../prometheus"
    destination = "/home/ubuntu/app/prometheus"
  }

  tags = {
    Name        = "thesis-monitoring-instance"
    Environment = "Dev"
  }

  connection {
  type        = "ssh"
  user        = "ubuntu"
  private_key = file(var.private_key_path)
  host        = self.public_ip
  }
}
