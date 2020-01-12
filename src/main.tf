data "aws_route53_zone" "primary" {
  name = var.hosted_zone
}

module "network" {
  source = "../modules/network"

  cidr    = var.cidr
  cluster = terraform.workspace
}

module "instances" {
  source = "../modules/instances"

  apiserver_port  = var.apiserver_port
  cidr            = var.cidr
  cluster         = terraform.workspace
  hosted_zone     = var.hosted_zone
  public_subnets  = module.network.public_subnets
  private_subnets = module.network.private_subnets
  vpc_id          = module.network.vpc_id
  zone_id         = data.aws_route53_zone.primary.zone_id
}
