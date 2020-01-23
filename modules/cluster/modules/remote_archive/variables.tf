variable "content" {
  type = map(string)
}

variable "name" {
  type = string 
}

variable "dest" {
  type    = string 
  default = "/tmp/init.zip"
}

variable "ssh_hosts" {
  type = list(string)
}

variable "ssh_user" {
  type = string
}

variable "bastion_host" {
  type = string 
}

variable "bastion_user" {
  type = string 
}

variable "on_copy" {
  type    = list(string) 
  default = []
}

