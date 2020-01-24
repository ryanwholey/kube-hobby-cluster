resource "aws_security_group" "controller" {
  name   = "${var.cluster}-controller"
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

  # etcd
  ingress {
    from_port     = 2379
    to_port       = 2380
    protocol      = "tcp"
    cidr_blocks   = [data.aws_vpc.network.cidr_block]
  }

  # kube-controller-services
  ingress {
    from_port     = 10250
    to_port       = 10260
    protocol      = "tcp"
    cidr_blocks   = [data.aws_vpc.network.cidr_block]
  }

  # kubernetes
  ingress {
    from_port     = 6443
    to_port       = 6443
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

resource "aws_instance" "controller" {
  count         = var.controller_count
  ami           = data.aws_ami.ubuntu.image_id
  instance_type = var.controller_instance_type
  subnet_id     = element(var.private_subnets, count.index % length(var.private_subnets))

  vpc_security_group_ids = [aws_security_group.controller.id]
  iam_instance_profile   = aws_iam_instance_profile.controller_instance.id

  key_name = aws_key_pair.instance_ssh_key.key_name

  tags = {
    Name = "${var.cluster}-controller-${count.index}"
    "kubernetes.io/cluster/${var.cluster}" = "owned"
  }
}

resource "aws_iam_instance_profile" "controller_instance" {
  name = "${var.cluster}-controller"
  role = aws_iam_role.controller_instance.name
}

data "aws_iam_policy_document" "controller_instance_profile" {
  statement {
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "controller_instance" {
  name = "${var.cluster}-controller-instance"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.instance_assume_role.json
}

resource "aws_iam_role_policy" "controller_instance_policy" {
  name   = "${var.cluster}-controller-intance"
  role   = aws_iam_role.controller_instance.id
  policy = data.aws_iam_policy_document.controller_instance_profile.json
}