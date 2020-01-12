locals {
  type = var.is_public ? "public" : "private"
}

module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.cidr

  networks = [ for az in var.azs : 
    {
      name     = "${local.type}-${az}"
      new_bits = 7
    }
  ]
}

resource "aws_subnet" "subnets" {
  for_each = module.subnet_addrs.network_cidr_blocks

  vpc_id                  = var.vpc_id
  availability_zone       = join("-", slice(split("-", each.key), 1, length(split("-", each.key))))
  cidr_block              = each.value
  map_public_ip_on_launch = var.is_public

  tags = {
    Name = "${var.prefix}-${each.key}"
  }
}
