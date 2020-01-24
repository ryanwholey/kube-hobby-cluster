module "network" {
  source = "../modules/network"

  cidr    = var.cidr
  cluster = terraform.workspace
}

module "instances" {
  source = "../modules/instances"

  cluster     = terraform.workspace
  hosted_zone = var.hosted_zone

  private_subnets = module.network.private_subnets
  public_subnets  = module.network.public_subnets
  vpc_id          = module.network.vpc_id
}

module "cluster" {
  source = "../modules/cluster"

  cluster     = terraform.workspace
  hosted_zone = var.hosted_zone
  region      = var.region

  vpc_id          = module.network.vpc_id
  private_subnets = module.network.private_subnets
  controller_ips  = module.instances.controller_ips
  worker_ips      = module.instances.worker_ips
  bastion_url     = module.instances.bastion_url

  controller_count = var.controller_count
  organization     = var.organization
  service_cidr     = var.service_cidr
  cluster_cidr     = var.cluster_cidr
}
