variable "hosted_zone" {
  type = string
}



variable "organization" {
  type = string
}

variable "apiserver_port" {
  type    = string
  default = "6443"
}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "controller_count" {
  type    = number
  default = 3
}

variable "kubernetes_service_ip" {
  type    = string
  default = "10.32.0.1"
}

variable "service_cidr" {
  type    = string
  default = "10.32.0.0/24"
}

variable "cluster_cidr" {
  type = string
  default = "10.200.0.0/16"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

