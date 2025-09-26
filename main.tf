# ===============================
# 1️⃣ Provider
# ===============================
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

# ===============================
# 2️⃣ VPC
# ===============================
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "demo-vpc" }
}

# ===============================
# 3️⃣ Public Subnet (EC2)
# ===============================
resource "aws_subnet" "demo_public_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = { Name = "demo-public-subnet" }
}

# ===============================
# 4️⃣ Private Subnets (RDS)
# ===============================
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

# ===============================
# 5️⃣ Internet Gateway
# ===============================
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id
  tags   = { Name = "demo-igw" }
}

# ===============================
# 6️⃣ Route Table for Public Subnet
# ===============================
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

# ===============================
# 7️⃣ Security Group for EC2
# ===============================
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg-demo"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.demo_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["208.127.30.55/32"]  # Replace with your public IP
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ===============================
# 8️⃣ Security Group for RDS
# ===============================
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-demo"
  description = "Allow MySQL from EC2"
  vpc_id      = aws_vpc.demo_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ===============================
# 9️⃣ IAM Role for EC2
# ===============================
resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-role-demo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy_attachment" "ec2_s3_attach" {
  name       = "ec2-s3-attach-demo"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile-demo"
  role = aws_iam_role.ec2_role.name
}

# ===============================
# 10️⃣ EC2 Instance
# ===============================
resource "aws_instance" "demo" {
  ami                    = "ami-08982f1c5bf93d976"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.demo_public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = { Name = "Tf-Demo-EC2" }
}

# ===============================
# 11️⃣ RDS Subnet Group
# ===============================
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-subnet-group-demo1"
  subnet_ids = [
    aws_subnet.demo_private_subnet_a.id,
    aws_subnet.demo_private_subnet_b.id
  ]
  tags = { Name = "rds-subnet-group-demo" }
}

# ===============================
# 12️⃣ RDS Instance
# ===============================
resource "aws_db_instance" "mydb" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "mydb"
  username               = "admin"
  password               = "Admin12345!"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
}
