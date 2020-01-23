variable "archive_sha" {
  type = string
}

variable "dest" {
  type = string 
}

variable "name" {
  type = string 
}

variable "ssh_hosts" {
  type = list(string)
}

variable "ssh_user" {
  type = string 
}

variable "bastion_user" {
  type = string 
}

variable "bastion_host" {
  type = string 
}

variable "on_copy" {
  type    = list(string)
  default = []
}
