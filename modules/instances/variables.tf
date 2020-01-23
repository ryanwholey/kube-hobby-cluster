variable "cluster" {
  type = string
}

variable "hosted_zone" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "vpc_id" {
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

variable "key_name" {
  type    = string
  default = "kube-admin"
}

variable "worker_count" {
  type    = number
  default = 3
}

variable "worker_instance_type" {
  type    = string
  default = "t3.small"
}