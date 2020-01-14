variable "cluster" {
  type = string
}

variable "organization" {
  type = string
}

variable "apiserver_dns_name" {
  type = string
}

variable "kubernetes_service_ip" {
  type    = string
  default = "10.32.0.1"
}
