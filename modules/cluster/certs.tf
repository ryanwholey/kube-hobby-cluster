locals {
  kubernetes_profile = [
    "signing",
    "key encipherment",
    "server auth",
    "client auth",
  ]
}

module "ca" {
  source = "./modules/ca_cert"

  common_name  = "kubernetes_ca"
  organization = var.organization
}

module "admin_cert" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "admin"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

module "kubelet_cert" {
  source = "./modules/multi_local_certs"

  cert_count = length(var.worker_ips)

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_names = local.worker_node_names
  organization = var.organization

  dns_names = concat(
    ["localhost"],
    local.worker_node_names,
  )

  ip_addresses = concat(
    ["127.0.0.1"],
    var.worker_ips,
  )

  allowed_uses = local.kubernetes_profile
}

module "kube_controller_manager_cert" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "system:kube-controller-manager"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

module "kube_proxy_cert" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "system:kube-proxy"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

module "kube_scheduler_cert" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "system:kube-scheduler"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

module "kubernetes_cert" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "kubernetes"
  organization = var.organization

  allowed_uses = local.kubernetes_profile

  dns_names = [
    aws_route53_record.kubernetes_api.name,
    "localhost",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.svc.cluster.local",
  ]

  ip_addresses = concat(
    [
      "127.0.0.1",
      local.kubernetes_service_ip,
    ],
    var.controller_ips
  )
}

module "service_account_cert" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "service-accounts"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

