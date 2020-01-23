resource "aws_route53_record" "kubernetes_api" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "kubernetes.${var.cluster}.${var.hosted_zone}"
  type    = "A"

  alias {
    name                   = aws_lb.kubernetes_api.dns_name
    zone_id                = aws_lb.kubernetes_api.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb" "kubernetes_api" {
  name               = "${var.cluster}-kubernetes-api"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnets

  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "kubernetes_api" {
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
  target_type = "ip"
  vpc_id      = var.vpc_id
}

resource "aws_lb_target_group_attachment" "controller" {
  count = length(var.controller_ips)

  target_group_arn = aws_lb_target_group.controller.arn
  target_id        = element(var.controller_ips, count.index)
  port             = var.apiserver_port
}
