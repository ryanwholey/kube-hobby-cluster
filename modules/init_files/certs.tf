locals {
  kubernetes_profile = ["signing", "key encipherment", "server auth", "client auth"]
}

module "ca" {
  source = "./modules/ca_cert"

  common_name  = "kubernetes"
  organization = var.organization
}

module "admin" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "admin"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

module "kubelet" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "system:node:kubelet"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

module "kube_controller_manager" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "system:kube-controller-manager"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

module "kube_proxy" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "system:kube-proxy"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

module "kube_scheduler" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "system:kube-scheduler"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

module "kubernetes" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "kubernetes"
  organization = var.organization

  allowed_uses = local.kubernetes_profile

  dns_names =[
    var.apiserver_dns_name,
    "localhost",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.svc.cluster.local",
  ]

  ip_addresses = [
    "127.0.0.1",
    var.kubernetes_service_ip,
  ]
}

module "service_accounts" {
  source = "./modules/local_cert"

  ca_private_key_pem = module.ca.key
  ca_cert_pem        = module.ca.cert

  common_name  = "service-accounts"
  organization = var.organization

  allowed_uses = local.kubernetes_profile
}

