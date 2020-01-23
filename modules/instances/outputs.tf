output "worker_ips" {
  value = aws_instance.worker.*.private_ip
}

output "controller_ips" {
  value = aws_instance.controller.*.private_ip
}

output "bastion_url" {
  value = aws_route53_record.bastion.name
}