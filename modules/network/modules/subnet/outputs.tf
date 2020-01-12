output "subnets" {
  value = [ for key, value in aws_subnet.subnets : value ]
}
