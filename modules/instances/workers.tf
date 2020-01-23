resource "aws_security_group" "worker" {
  name   = "${var.cluster}-worker"
  vpc_id = var.vpc_id

  # ssh
  ingress {
    from_port     = 22
    to_port       = 22
    protocol      = "tcp"
    cidr_blocks   = [data.aws_vpc.network.cidr_block]
  }

  # http
  ingress {
    from_port     = 80
    to_port       = 80
    protocol      = "tcp"
    cidr_blocks   = [data.aws_vpc.network.cidr_block]
  }

  # https
  ingress {
    from_port     = 443
    to_port       = 443
    protocol      = "tcp"
    cidr_blocks   = [data.aws_vpc.network.cidr_block]
  }

  # kubelet 
  ingress {
    from_port     = 10250
    to_port       = 10250
    protocol      = "tcp"
    cidr_blocks   = [data.aws_vpc.network.cidr_block]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "worker" {
  count         = var.worker_count
  ami           = data.aws_ami.ubuntu.image_id
  instance_type = var.worker_instance_type
  subnet_id     = element(var.private_subnets, count.index % length(var.private_subnets))

  vpc_security_group_ids = [aws_security_group.worker.id]

  key_name = aws_key_pair.instance_ssh_key.key_name

  tags = {
    Name = "${var.cluster}-worker-${count.index}"

    "kubernetes.io/cluster/${var.cluster}" = "owned"
  }
}
