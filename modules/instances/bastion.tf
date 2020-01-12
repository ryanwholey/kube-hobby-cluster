resource "aws_security_group" "bastion" {
  name        = "${var.cluster}-bastion"
  vpc_id      = var.vpc_id

  # ssh
  ingress {
    from_port     = 22
    to_port       = 22
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  # http
  ingress {
    from_port     = 80
    to_port       = 80
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  # https
  ingress {
    from_port     = 443
    to_port       = 443
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.bastion_instance_type
  key_name        = var.key_name
  subnet_id       = element(var.public_subnets, 0) 

  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.cluster}-bastion"
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = var.zone_id
  name    = "bastion.${var.cluster}.${var.hosted_zone}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.bastion.public_ip]
}
