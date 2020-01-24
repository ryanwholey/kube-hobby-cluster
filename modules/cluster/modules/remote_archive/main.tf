module "archive" {
  source = "./modules/archive"

  name    = var.name
  content = var.content
}

module "remote_copy" {
  source = "./modules/remote_copy"

  archive_sha = module.archive.archive_sha

  name = var.name
  dest = var.dest

  ssh_user  = var.ssh_user
  ssh_hosts = var.ssh_hosts

  bastion_host = var.bastion_host
  bastion_user = var.bastion_user

  on_copy = var.on_copy
}
