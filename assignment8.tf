# Initialize Terraform
terraform {
  cloud {
    organization = "kaden-rip"

    workspaces {
      name = "Terraform"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.61.0"
    }
  }
}

# Set provider for terraform to download configs from
provider "aws" {
  region  = "us-east-1"
}

# Create a new VPC
resource "aws_vpc" "tf-vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "Terraform VPC" }
}

# Create a new subnet in the VPC
resource "aws_subnet" "tf-subnet" {
  vpc_id     = aws_vpc.tf-vpc.id
  cidr_block = "10.0.1.0/24"
  #availability_zone = "us-east-1a"
  tags = { Name = "Terraform Subnet" }
}

# Create a new security group that allows incoming traffic to ports 80 and 22 and all outgoing traffic
resource "aws_security_group" "tf-sg" {
  name   = "tf-sg"
  vpc_id = aws_vpc.tf-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "Terraform Security Group" }
}

# Create an internet gateway and attach it to the VPC
resource "aws_internet_gateway" "tf-ig" {
  vpc_id = aws_vpc.tf-vpc.id
  tags   = { Name = "Terraform Gateway" }
}

# Create a route table and add a default route to the internet gateway
resource "aws_route_table" "tf-r" {
  vpc_id = aws_vpc.tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf-ig.id
  }
  tags = { Name = "Terraform Route Table" }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "tf-r" {
  subnet_id      = aws_subnet.tf-subnet.id
  route_table_id = aws_route_table.tf-r.id
}

# Create an EC2 key pair
resource "aws_key_pair" "tf-key" {
  key_name   = "tf-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjw3/I+SEIooJ/tBBuqjw9rpyAhCJOIRGMxlCx9JzrxlAY74X4Ib+mgkHrk222SRiSzVeGHC8uwcZgLQ6b3IlB39B/Tu+NTpwDySSwhhbNCPhexzUEpb9M1kvncQ+6sxbadNwReC924wo+YguG7xGaq+dOC+1JlokpWE3kuKEjlreowpjy642OVGHqEZb1OnJ2FaGtenfy5RiGw9JUxze9YvFHdTnJ6e1EhwguFrmZ1nYH8YYRuToMn9dD4zF6dbuUcpyMjiGxkkiWlZAyj8iMhyF0YDVllT83yTBuQqCy4u+36KNsPMpc9tv4oTybAlhOu8oqf10Lq+hNuCUao5AuLmF7iLDp2JlKZgF5iAzVYCT9sjdf8tzYNL4D6khGFRbRQbiewSwqe/Bl5hosk+Smu+VBcA5X5IfqanuQnwyDlS1Dhz3mfjsIUuS2r/ijqNloowYWCLQlYOO8SgFWgObEmso5IHtBG5ISCFqPVw/rGMDkwcEtSeiUDWR6bmmUhhU= xcymy@Gemini"
}

# Create three EC2 instances
resource "aws_instance" "dev" {
  ami                         = "ami-007855ac798b5175e"
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.tf-sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.tf-key.key_name
  subnet_id                   = aws_subnet.tf-subnet.id
  user_data                   = <<-EOF
         #!/bin/bash
         wget http://computing.utahtech.edu/it/3110/notes/2021/terraform/install.sh -O /tmp/install.sh
         chmod +x /tmp/install.sh
         source /tmp/install.sh
         EOF
  tags                        = { Name = "Terraform EC2 dev VM" }
}

resource "aws_instance" "test" {
  ami                         = "ami-007855ac798b5175e"
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.tf-sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.tf-key.key_name
  subnet_id                   = aws_subnet.tf-subnet.id
  user_data                   = <<-EOF
         #!/bin/bash
         wget http://computing.utahtech.edu/it/3110/notes/2021/terraform/install.sh -O /tmp/install.sh
         chmod +x /tmp/install.sh
         source /tmp/install.sh
         EOF
  tags                        = { Name = "Terraform EC2 test VM" }
}

resource "aws_instance" "prod" {
  ami                         = "ami-007855ac798b5175e"
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.tf-sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.tf-key.key_name
  subnet_id                   = aws_subnet.tf-subnet.id
  user_data                   = <<-EOF
         #!/bin/bash
         wget http://computing.utahtech.edu/it/3110/notes/2021/terraform/install.sh -O /tmp/install.sh
         chmod +x /tmp/install.sh
         source /tmp/install.sh
         EOF
  tags                        = { Name = "Terraform EC2 prod VM" }
}

# Output the public IPs of the instances
output "dev_public_ip" {
  value = aws_instance.dev.public_ip
}

output "test_public_ip" {
  value = aws_instance.test.public_ip
}

output "prod_public_ip" {
  value = aws_instance.prod.public_ip
}