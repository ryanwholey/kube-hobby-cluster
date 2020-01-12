
resource "aws_security_group" "worker" {
  name        = "${var.cluster}-worker"
  vpc_id      = var.vpc_id

  ingress {
    from_port     = 22
    to_port       = 22
    protocol      = "tcp"
    cidr_blocks   = [var.cidr]
  }

  ingress {
    from_port     = 80
    to_port       = 80
    protocol      = "tcp"
    cidr_blocks   = [var.cidr]
  }

  ingress {
    from_port     = 443
    to_port       = 443
    protocol      = "tcp"
    cidr_blocks   = [var.cidr]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "workers" {
  name = "${var.cluster}-worker-${aws_launch_configuration.worker.name}"

  desired_capacity          = var.worker_count
  min_size                  = var.worker_count
  max_size                  = var.worker_count + 1
  default_cooldown          = 30
  health_check_grace_period = 30

  vpc_zone_identifier = var.private_subnets

  launch_configuration = aws_launch_configuration.worker.name

  tag {
    key                 = "Name"
    value               = "${var.cluster}-worker"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "worker" {
  image_id             = data.aws_ami.ubuntu.image_id
  instance_type        = var.worker_instance_type
  security_groups      = [aws_security_group.worker.id]
  iam_instance_profile = aws_iam_instance_profile.worker.name
  key_name             = var.key_name
}

resource "aws_iam_role" "worker" {
  name               = "${var.cluster}-worker"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "worker_read_ec2" {
  role       = aws_iam_role.worker.name
  policy_arn = aws_iam_policy.instance_read_ec2.arn
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.cluster}-worker"
  role = aws_iam_role.worker.id
}
