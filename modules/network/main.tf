locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count)
  subnet_split = cidrsubnets(var.cidr, 1, 1)
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "network" {
  cidr_block = var.cidr

  tags = {
    Name = "${var.cluster}-network"
  }
}

module "public_subnets" {
  source = "./modules/subnet"

  vpc_id    = aws_vpc.network.id
  azs       = local.azs
  is_public = true
  cidr      = element(local.subnet_split, 0)
  prefix    = var.cluster
}

module "private_subnets" {
  source = "./modules/subnet"

  vpc_id    = aws_vpc.network.id
  azs       = local.azs
  is_public = false
  cidr      = element(local.subnet_split, 1)
  prefix    = var.cluster
}
