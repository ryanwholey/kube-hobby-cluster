resource "null_resource" "remote_copy" {
  count = length(var.ssh_hosts)

  triggers = {
    archive_sha = var.archive_sha
  }

  provisioner "file" {
    source      = "/tmp/${var.name}"
    destination = var.dest

    connection {
      type = "ssh"
      user = var.ssh_user
      host = element(var.ssh_hosts, count.index)
      bastion_host = var.bastion_host
      bastion_user = var.bastion_user
    }
  }

  provisioner "remote-exec" {
    inline = concat(
      ["echo ${count.index} > /tmp/instance_index"],
      var.on_copy,
    )

    connection {
      type = "ssh"
      user = var.ssh_user
      host = element(var.ssh_hosts, count.index)
      bastion_host = var.bastion_host
      bastion_user = var.bastion_user
    }
  }
}
