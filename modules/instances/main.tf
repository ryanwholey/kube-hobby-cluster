data "aws_vpc" "network" {
  id = var.vpc_id
}

data "aws_route53_zone" "primary" {
  name = var.hosted_zone
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "instance_ssh_key" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}


