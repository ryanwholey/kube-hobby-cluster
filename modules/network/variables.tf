variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zone_count" {
  type    = number
  default = 2
}

variable "cluster" {
  type    = string
  default = "kube"
}