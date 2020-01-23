variable "common_name" {
  type = string
}

variable "organization" {
  type = string
}

variable "allowed_uses" {
  type = list(string)
  default = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

variable "rsa_bits" {
  type    = string
  default = "2048"
}

variable "validity_period_hours" {
  type    = string
  default = "8760"
}
