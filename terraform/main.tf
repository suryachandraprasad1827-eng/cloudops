terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.16.0"
}

provider "aws" {
  region = "ap-southeast-2"
}
resource "aws_ecr_repository" "cloudops_api" {
  name                 = "cloudops-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}
resource "aws_instance" "cloudops_server" {
  ami           = "ami-06259b63260eddc13"
  instance_type = "t3.micro"
  tags = {
    Name = "CloudOps-API-Server"
  }

  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_security_group" "cloudops_ec2" {
  name        = "CloudOps-EC2-SG"
  description = "CloudOps EC2 server security group"
  vpc_id      = "vpc-09b4574447c162125"

  lifecycle {
    prevent_destroy = true
  }
}
