output "key" {
  value = tls_private_key.ca.private_key_pem
}

output "cert" {
  value = tls_self_signed_cert.ca.cert_pem
}

output "algorithm" {
  value = tls_private_key.ca.algorithm
}
