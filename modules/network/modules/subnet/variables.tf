variable "is_public" {
  type    = bool
  default = false
}

variable "azs" {
  type = list(string)
}

variable "cidr" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "prefix" {
  type    = string
  default = ""
}
