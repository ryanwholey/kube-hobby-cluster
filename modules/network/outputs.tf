output "public_subnets" {
  value = [ for subnet in module.public_subnets.subnets : subnet.id ]
}

output "private_subnets" {
  value = [ for subnet in module.private_subnets.subnets : subnet.id ]
}

output "vpc_id" {
  value = aws_vpc.network.id
}
