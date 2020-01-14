variable "apiserver_dns_name" {
  type = string
}

variable "apiserver_port" {
  type    = string
}

variable "cluster" {
  type = string
}

variable "cluster_cidr" {
  type    = string
}

variable "etcd_dns_name" {
  type = string
}

variable "organization" {
  type = string
}

variable "hosted_zone" {
  type = string
}

variable "kubernetes_service_ip" {
  type    = string
  default = "10.32.0.1"
}

variable "kubernetes_service_cidr" {
  type    = string
  default = "10.32.0.0/24"
}

variable "controller_count" {
  type    = number
  default = 3
}
