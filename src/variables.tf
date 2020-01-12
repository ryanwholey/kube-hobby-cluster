variable "apiserver_port" {
  type    = string
  default = "6443"
}

variable cidr {
  type    = string
  default = "10.0.0.0/16"
}

variable "hosted_zone" {
  type = string
}
