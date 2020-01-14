variable cidr {
  type    = string
}

variable vpc_id {
  type = string
}

variable public_subnets {
  type = list(string)
}

variable private_subnets {
  type = list(string)
}

variable "cluster" {
  type = string
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "controller_count" {
  type    = number
  default = 3
}

variable "controller_instance_type" {
  type    = string
  default = "t3.small"
}

variable "worker_count" {
  type    = number
  default = 3
}

variable "worker_instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type    = string
  default = "kube-admin"
}

variable "zone_id" {
  type = string
}

variable "apiserver_port" {
  type    = string
}

variable "hosted_zone" {
  type = string
}

variable "launch_config_bucket" {
  type = string
}

variable "launch_config_bucket_arn" {
  type = string
}

variable "apiserver_dns_name" {
  type = string
}