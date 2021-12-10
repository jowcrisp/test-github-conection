terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  cloud {
    organization = "beroot"

    workspaces {
      name = "test-github-conection"
    }
  }
}

provider "aws" {
  region     = "us-east-2"
}

resource "tls_private_key" "test_tls" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "test_key" {
  key_name   = "test-key"
  public_key = tls_private_key.test_tls.public_key_openssh
}

resource "aws_network_interface" "test_interface" {
  subnet_id = "subnet-055776e7cd7e652da"

  tags = {
    Name = "test-interface"
  }
}

resource "aws_security_group" "test_sg" {
  name = "test-sg"
  ingress {
    from_port   = 22 
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test_instance" {
  ami           = "ami-0629230e074c580f2"
  instance_type = "t2.micro"
  key_name      = "test-key" 
  vpc_security_group_ids  = [aws_security_group.test_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo apt-get install nginx -y
              EOF

  network_interface {
    network_interface_id = aws_network_interface.test_interface.id
    device_index         = 0
  }

  tags = {
    Name = "test-instance"
  }
}

output "web-address" {
  value = aws_instance.test_instance.public_dns
}
