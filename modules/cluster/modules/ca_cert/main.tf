resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = var.rsa_bits
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm     = tls_private_key.ca.algorithm
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.allowed_uses

  subject {
    common_name  = var.common_name
    organization = var.organization
  }
}
