
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "read_ec2" {
  statement {
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "instance_read_launch_config" {
  statement {
    actions   = ["s3:Get*"]
    resources = ["${var.launch_config_bucket_arn}/*"]
  }

  statement {
    actions   = ["s3:List*"]
    resources = [var.launch_config_bucket_arn]
  }
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

resource "aws_iam_policy" "instance_read_ec2" {
  name   = "${var.cluster}-read-ec2"
  policy = data.aws_iam_policy_document.read_ec2.json
}

resource "aws_iam_policy" "instance_read_launch_config" {
  name = "${var.cluster}-read-launch-config"
  policy = data.aws_iam_policy_document.instance_read_launch_config.json
}

resource "aws_key_pair" "instance_ssh_key" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}

