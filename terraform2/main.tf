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

resource "aws_key_pair" "ryan-key" {
  key_name   = "ryan-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_vpc" "kube-vpc" {
  cidr_block = "10.240.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "kube-vpc"
  }
}

resource "aws_internet_gateway" "kube-gateway" {
  vpc_id = "${aws_vpc.kube-vpc.id}"
}

resource "aws_route_table" "kube-route-table" {
  vpc_id = "${aws_vpc.kube-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.kube-gateway.id}"
  }

  depends_on = [ "aws_internet_gateway.kube-gateway" ]

  tags {
    Name = "kube-route-table"
  }
}


resource "aws_subnet" "kube-subnet" {
  vpc_id     = "${aws_vpc.kube-vpc.id}"
  cidr_block = "10.240.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "kube-subnet"
  }
}

resource "aws_route_table_association" "kube-route-assoc" {
  subnet_id      = "${aws_subnet.kube-subnet.id}"
  route_table_id = "${aws_route_table.kube-route-table.id}"

  depends_on = [ "aws_subnet.kube-subnet", "aws_route_table.kube-route-table"]
}


resource "aws_security_group" "kube-internal-security-group" {
  name        = "kube-controller-security-group"
  description = "Allow traffic for control plane"
  vpc_id      = "${aws_vpc.kube-vpc.id}"

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["10.240.0.0/24", "10.200.0.0/16"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["10.240.0.0/24", "10.200.0.0/16"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["10.10.10.0/24", "10.10.20.0/24"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["10.10.10.0/24", "10.10.20.0/24"]
  }

}

resource "aws_security_group" "kube-external-security-group" {
  name        = "kube-worker-security-group"
  description = "Allow traffic for worker"
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
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "kube-controller" {
  count         = 3
  ami           = "ami-059ac57b261e8332d"
  instance_type = "t2.medium"
  subnet_id     = "${aws_subnet.kube-subnet.id}"
  private_ip    = "10.240.0.1${count.index}"
  key_name      = "ryan-key"
  vpc_security_group_ids = [ "${aws_security_group.kube-internal-security-group.id}" ]

  depends_on = [ "aws_key_pair.ryan-key", "aws_security_group.kube-internal-security-group" ]

  tags {
    Name = "kube-controller-${count.index + 1}"
  }
}

resource "aws_instance" "kube-worker" {
  count         = 3
  ami           = "ami-059ac57b261e8332d"
  instance_type = "t2.medium"
  subnet_id     = "${aws_subnet.kube-subnet.id}"
  private_ip    = "10.240.0.2${count.index}"
  key_name      = "ryan-key"
  vpc_security_group_ids = [ "${aws_security_group.kube-external-security-group.id}" ]

  depends_on = [ "aws_key_pair.ryan-key", "aws_security_group.kube-external-security-group" ]

  tags {
    Name = "kube-worker-${count.index + 1}"
  }
}

output "kube-worker-public-ips" {
  value = ["${aws_instance.kube-worker.*.public_ip}"]
}

output "kube-worker-private-ips" {
  value = ["${aws_instance.kube-worker.*.private_ip}"]
}

output "kube-controller-public-ips" {
  value = ["${aws_instance.kube-controller.*.public_ip}"]
}

output "kube-controller-private-ips" {
  value = ["${aws_instance.kube-controller.*.private_ip}"]
}

// resource "null_resource" "create-ca-certs" {
//   provisioner "local-exec" {
//     command = "cd .. && ./gencerts.py"
//     interpreter = ["sh", "-c"]
//   }
// }


// null resource might be a good place to start bootstrapping https://www.terraform.io/docs/provisioners/null_resource.html
// use terraform local-exec to run gen-ca-cert.sh  https://www.terraform.io/docs/provisioners/local-exec.html
// use terraform provisioner to copy certs to instances https://www.terraform.io/docs/provisioners/file.html
