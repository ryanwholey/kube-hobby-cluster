variable "bastion_url" {
  type = string
}

variable "cluster" {
  type = string
}

variable "cluster_cidr" {
  type = string
}

variable "controller_count" {
  type = number 
}

variable "controller_ips" {
  type = list(string)
}

variable "hosted_zone" {
  type = string
}

variable "organization" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "service_cidr" {
  type = string
}

variable "worker_ips" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "apiserver_port" {
  type    = string
  default = "6443"
}
