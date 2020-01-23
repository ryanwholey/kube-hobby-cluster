output "worker_private_ips" {
  value = module.instances.worker_ips
}

output "controller_private_ips" {
  value = module.instances.controller_ips
}
