
variable "ca_private_key_pem" {
  type    = string
}

variable "ca_cert_pem" {
  type    = string
}

variable "common_names" {
  type = list(string)
}

variable "organization" {
  type = string
}

variable "allowed_uses" {
  type = list(string)
}

variable "algorithm" {
  type    = string
  default = "RSA"
}

variable "ca_key_algorithm" {
  type    = string
  default = "RSA"
}

variable "dns_names" {
  type    = list(string)
  default = []
}

variable "ip_addresses" {
  type    = list(string)
  default = []
}

variable "rsa_bits" {
  type    = string
  default = "2048"
}

variable "validity_period_hours" {
  type    = string
  default = "8760"
}

variable "cert_count" {
  type    = number
  default = 1
}