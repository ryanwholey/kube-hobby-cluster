resource "aws_security_group" "controller" {
  name        = "${var.cluster}-controller"
  vpc_id      = var.vpc_id

  # ssh
  ingress {
    from_port     = 22
    to_port       = 22
    protocol      = "tcp"
    cidr_blocks   = [var.cidr]
  }

  # http
  ingress {
    from_port     = 80
    to_port       = 80
    protocol      = "tcp"
    cidr_blocks   = [var.cidr]
  }

  # https
  ingress {
    from_port     = 443
    to_port       = 443
    protocol      = "tcp"
    cidr_blocks   = [var.cidr]
  }

  # etcd
  ingress {
    from_port     = 2379
    to_port       = 2379
    protocol      = "tcp"
    cidr_blocks   = [var.cidr]
  }

  # kube-scheduler 
  ingress {
    from_port     = 10251
    to_port       = 10251
    protocol      = "tcp"
    cidr_blocks   = [var.cidr]
  }

  # kubernetes
  ingress {
    from_port     = 6443
    to_port       = 6443
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

resource "aws_autoscaling_group" "controller" {
  name = "${var.cluster}-controller-${aws_launch_configuration.controller.name}"

  desired_capacity          = var.controller_count
  min_size                  = var.controller_count
  max_size                  = var.controller_count + 1
  default_cooldown          = 30
  health_check_grace_period = 30
  vpc_zone_identifier       = var.private_subnets
  launch_configuration      = aws_launch_configuration.controller.name

  tag {
    key                 = "Name"
    value               = "${var.cluster}-controller"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "controller" {
  image_id             = data.aws_ami.ubuntu.image_id
  instance_type        = var.controller_instance_type
  security_groups      = [aws_security_group.controller.id]
  iam_instance_profile = aws_iam_instance_profile.controller.name
  key_name             = var.key_name

  user_data = templatefile("${path.module}/launch_script.tpl", {
    NODE_TYPE = "controller"
    BUCKET    = var.launch_config_bucket 
  })
}

resource "aws_iam_role" "controller" {
  name               = "${var.cluster}-controller"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "controller_read_ec2" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.instance_read_ec2.arn
}

resource "aws_iam_role_policy_attachment" "controller_read_launch_config" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.instance_read_launch_config.arn
}

resource "aws_iam_instance_profile" "controller" {
  name = "${var.cluster}-controller"
  role = aws_iam_role.controller.id
}

resource "aws_route53_record" "kubernetes_api" {
  zone_id = var.zone_id
  name    = var.apiserver_dns_name
  type    = "A"

  alias {
    name                   = aws_lb.kubernetes_api.dns_name
    zone_id                = aws_lb.kubernetes_api.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb" "kubernetes_api" {
  name               = "${var.cluster}-kubernetes"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnets

  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "forwarder" {
  load_balancer_arn = aws_lb.kubernetes_api.arn
  port              = var.apiserver_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controller.arn
  }
}

resource "aws_lb_target_group" "controller" {
  name        = "${var.cluster}-controllers-group"
  port        = var.apiserver_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

resource "aws_autoscaling_attachment" "workers" {
  autoscaling_group_name = aws_autoscaling_group.controller.id
  alb_target_group_arn   = aws_lb_target_group.controller.arn
}
