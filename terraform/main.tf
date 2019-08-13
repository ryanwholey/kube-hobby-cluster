variable "access_key" {}

variable "secret_key" {}

variable "region" {
  default = "us-west-1"
}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_key_pair" "ryan-mac-air" {
  key_name   = "ryan-mac-air"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_vpc" "kube-vpc" {
  cidr_block = "10.10.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "kube"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.kube-vpc.id}"
}

resource "aws_route_table" "kube-rt" {
  vpc_id = "${aws_vpc.kube-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  depends_on = [ "aws_internet_gateway.gw" ]

  tags {
    Name = "kube-rt"
  }
}

resource "aws_subnet" "kube-pods-subnet" {
  vpc_id     = "${aws_vpc.kube-vpc.id}"
  cidr_block = "10.10.30.0/24"
  map_public_ip_on_launch = true

  depends_on = [ "aws_internet_gateway.gw" ]

  tags = {
    Name = "kube-pods"
  }
}

resource "aws_subnet" "kube-control-subnet" {
  vpc_id     = "${aws_vpc.kube-vpc.id}"
  cidr_block = "10.10.40.0/24"
  map_public_ip_on_launch = true

  depends_on = [ "aws_internet_gateway.gw" ]

  tags = {
    Name = "kube-control-plane"
  }
}

resource "aws_route_table_association" "kube-control-route-assoc" {
  subnet_id      = "${aws_subnet.kube-control-subnet.id}"
  route_table_id = "${aws_route_table.kube-rt.id}"

  depends_on = [ "aws_subnet.kube-control-subnet", "aws_route_table.kube-rt"]
}

resource "aws_route_table_association" "kube-pod-route-assoc" {
  subnet_id      = "${aws_subnet.kube-pods-subnet.id}"
  route_table_id = "${aws_route_table.kube-rt.id}"

  depends_on = [ "aws_subnet.kube-pods-subnet", "aws_route_table.kube-rt"]
}

resource "aws_security_group" "kube-internal-security-group" {
  name        = "kube-internal-security-group"
  description = "Allow traffic for control plane"
  vpc_id      = "${aws_vpc.kube-vpc.id}"

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "kube-external-security-group" {
  name        = "kube-external-security-group"
  description = "Allow traffic for workers"
  vpc_id      = "${aws_vpc.kube-vpc.id}"

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "load-balancer" {
  count         = 1
  ami           = "ami-059ac57b261e8332d"
  instance_type = "t2.medium"
  subnet_id     = "${aws_subnet.kube-control-subnet.id}"
  private_ip    = "10.10.40.93"
  key_name      = "ryan-mac-air"
  vpc_security_group_ids = [ "${aws_security_group.kube-worker-sg.id}" ]

  depends_on = [ "aws_key_pair.ryan-mac-air", "aws_security_group.kube-worker-sg" ]

  tags {
    Name = "load-balancer"
  }
}

resource "aws_instance" "kube-master" {
  count         = 3
  ami           = "ami-059ac57b261e8332d"
  instance_type = "t2.medium"
  subnet_id     = "${aws_subnet.kube-control-subnet.id}"
  private_ip    = "10.10.40.9${count.index}"
  key_name      = "ryan-mac-air"
  vpc_security_group_ids = [ "${aws_security_group.kube-worker-sg.id}" ]

  depends_on = [ "aws_key_pair.ryan-mac-air", "aws_security_group.kube-worker-sg" ]

  tags {
    Name = "kube-master-${count.index + 1}"
  }
}

resource "aws_instance" "kube-worker" {
  count         = 3
  ami           = "ami-059ac57b261e8332d"
  instance_type = "t2.medium"
  subnet_id     = "${aws_subnet.kube-control-subnet.id}"
  private_ip    = "10.10.40.10${count.index}"
  key_name      = "ryan-mac-air"
  vpc_security_group_ids = [ "${aws_security_group.kube-worker-sg.id}" ]

  depends_on = [ "aws_key_pair.ryan-mac-air", "aws_security_group.kube-worker-sg" ]

  tags {
    Name = "kube-worker-${count.index  + 1}"
  }
}

resource "aws_eip" "load-balancer-eip" {
  vpc = true

  instance                  = "${aws_instance.load-balancer.id}"
  associate_with_private_ip = "10.10.40.93"
}

resource "aws_eip" "kube-master-1-eip" {
  vpc = true
  count = 3

  instance = "${element(aws_instance.kube-master.*.id, count.index)}"
}

resource "aws_eip" "kube-worker-1-eip" {
  vpc = true
  count = 3

  instance = "${element(aws_instance.kube-worker.*.id, count.index)}"
}

output "worker_instance_ips" {
  value = ["${aws_instance.kube-worker.*.public_ip}"]
}

output "master_instance_ips" {
  value = ["${aws_instance.kube-master.*.public_ip}"]
}

output "loadbalancer_instance_ips" {
  value = ["${aws_instance.load-balancer.*.public_ip}"]
}