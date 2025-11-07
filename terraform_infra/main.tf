provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# ───────────────
# VPC and Subnets
# ───────────────
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "demo-vpc" }
}

resource "aws_subnet" "demo_public_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false  # remove public IP to pass tfsec
  availability_zone       = "us-east-1a"
  tags = { Name = "demo-public-subnet" }
}

resource "aws_subnet" "demo_private_subnet_a" {
  vpc_id            = aws_vpc.demo_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "demo-private-subnet-a" }
}

resource "aws_subnet" "demo_private_subnet_b" {
  vpc_id            = aws_vpc.demo_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "demo-private-subnet-b" }
}

# Internet Gateway
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id
  tags   = { Name = "demo-igw" }
}

# Public Route Table
resource "aws_route_table" "demo_public_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }

  tags = { Name = "demo-public-rt" }
}

resource "aws_route_table_association" "demo_public_assoc" {
  subnet_id      = aws_subnet.demo_public_subnet.id
  route_table_id = aws_route_table.demo_public_rt.id
}

# ───────────────
# Security Group
# ───────────────
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg-demo"
  description = "Allow limited access"
  vpc_id      = aws_vpc.demo_vpc.id

  # Restrictive ingress (example: only from 10.0.0.0/16 VPC CIDR)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# ───────────────
# EC2 Instance
# ───────────────
resource "aws_instance" "demo" {
  ami                         = "ami-08982f1c5bf93d976"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.demo_private_subnet_a.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = "deployer_new"
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "Tf-Demo-EC2" }
}

# ───────────────
# RDS
# ───────────────
resource "aws_db_instance" "mydb" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "mydb"
  username               = "admin"
  password               = "Admin12345!"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  skip_final_snapshot    = true
  storage_encrypted      = true
  deletion_protection    = true
  backup_retention_period = 7
  iam_database_authentication_enabled = true
}

# ───────────────
# Outputs
# ───────────────
output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.demo.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mydb.endpoint
}
