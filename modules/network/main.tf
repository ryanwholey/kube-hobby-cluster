locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count)
  subnet_split = cidrsubnets(var.cidr, 1, 1)
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "network" {
  cidr_block = var.cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

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

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.network.id

  tags = {
    Name = "${var.cluster}-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.network.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "${var.cluster}-public"
  }
}

resource "aws_route_table_association" "public" {
  count = length(local.azs)

  subnet_id      = element(module.public_subnets.subnets, count.index)["id"]
  route_table_id = aws_route_table.public.id
}

module "private_subnets" {
  source = "./modules/subnet"

  vpc_id    = aws_vpc.network.id
  azs       = local.azs
  is_public = false
  cidr      = element(local.subnet_split, 1)
  prefix    = var.cluster
}

resource "aws_route_table" "private" {
  count = length(local.azs)

  vpc_id = aws_vpc.network.id

  tags = {
    Name = "${var.cluster}-private-${element(local.azs, count.index)}"
  }
}

resource "aws_nat_gateway" "nats" {
  count = length(local.azs)

   allocation_id = element(aws_eip.nat_ips.*.id, count.index)
   subnet_id     = element(module.public_subnets.subnets, count.index)["id"]

   depends_on = [aws_internet_gateway.gateway]

  tags = {
    Name = "${var.cluster}-${element(local.azs, count.index)}"
  }
}

resource "aws_route" "nats" {
  count = length(local.azs)

  route_table_id = element(aws_route_table.private.*.id, count.index)

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nats.*.id, count.index)
}

resource "aws_eip" "nat_ips" {
  count = length(local.azs)

  vpc = true
}

resource "aws_route_table_association" "private" {
  count = length(module.private_subnets.subnets)

  subnet_id      = element(module.private_subnets.subnets, count.index)["id"]
  route_table_id = element(aws_route_table.private.*.id, count.index)
}
