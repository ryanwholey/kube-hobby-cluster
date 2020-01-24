resource "tls_private_key" "cert" {
  count = var.cert_count

  algorithm   = var.algorithm
  rsa_bits    = var.rsa_bits
}

resource "tls_cert_request" "cert" {
  count = var.cert_count

  key_algorithm   = tls_private_key.cert[count.index].algorithm
  private_key_pem = tls_private_key.cert[count.index].private_key_pem

  dns_names    = var.dns_names
  ip_addresses = var.ip_addresses

  subject {
    common_name  = var.common_names[count.index]
    organization = var.organization
  }
}

resource "tls_locally_signed_cert" "cert" {
  count = var.cert_count

  cert_request_pem = tls_cert_request.cert[count.index].cert_request_pem

  ca_key_algorithm   = var.ca_key_algorithm
  ca_private_key_pem = var.ca_private_key_pem
  ca_cert_pem        = var.ca_cert_pem

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.allowed_uses
}