output "launch_config_bucket" {
  value = aws_s3_bucket.launch_config.id
}

output "launch_config_bucket_arn" {
  value = aws_s3_bucket.launch_config.arn
}

// CERTS 
output "ca_key" {
  value = module.ca.key
}

output "ca_cert" {
  value = module.ca.cert
}

output "admin_key" {
  value = module.admin.key
}

output "admin_cert" {
  value = module.admin.cert
}

output "kubelet_key" {
  value = module.kubelet.key
}

output "kubelet_cert" {
  value = module.kubelet.cert
}

output "kube_controller_manager_key" {
  value = module.kube_controller_manager.key
}

output "kube_controller_manager_cert" {
  value = module.kube_controller_manager.cert
}

output "kube_proxy_key" {
  value = module.kube_proxy.key
}

output "kube_proxy_cert" {
  value = module.kube_proxy.cert
}

output "kube_scheduler_key" {
  value = module.kube_scheduler.key
}

output "kube_scheduler_cert" {
  value = module.kube_scheduler.cert
}

output "kubernetes_key" {
  value = module.kubernetes.key
}

output "kubernetes_cert" {
  value = module.kubernetes.cert
}

output "service_account_key" {
  value = module.service_account.key
}

output "service_account_cert" {
  value = module.service_account.cert
}
