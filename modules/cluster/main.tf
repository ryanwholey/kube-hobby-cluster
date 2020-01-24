locals {
  kubernetes_service_ip = cidrhost(var.service_cidr, 1)
  kubernetes_version = "1.15.3"
  worker_node_names = [for ip in var.worker_ips: "system:node:ip-${replace(ip, ",", "-")}.${var.region}.compute.internal"]
  controller_node_names = [for ip in var.controller_ips: "system:node:ip-${replace(ip, ",", "-")}.${var.region}.compute.internal"]
}

data "aws_route53_zone" "primary" {
  name = var.hosted_zone
}

resource "random_string" "encryption_string" {
  length = 32
}

module "controller_init_files" {
  source = "./modules/remote_archive"

  content = {
    "ca-cert.pem"              = module.ca.cert
    "ca-key.pem"               = module.ca.key
    "kubernetes-cert.pem"      = module.kubernetes_cert.cert
    "kubernetes-key.pem"       = module.kubernetes_cert.key
    "service-account-cert.pem" = module.service_account_cert.cert
    "service-account-key.pem"  = module.service_account_cert.key

    "kube-controller-manager.kubeconfig" = templatefile("${path.module}/templates/kubeconfig.tpl", {
      CA_CERT             = base64encode(module.ca.cert)
      CLIENT_CERT         = base64encode(module.kube_controller_manager_cert.cert)
      CLIENT_KEY          = base64encode(module.kube_controller_manager_cert.key)
      KUBERNETES_API_HOST = "127.0.0.1"
      KUBERNETES_API_PORT = var.apiserver_port
      CLUSTER             = var.cluster
      USER_NAME           = "system:kube-controller-manager"
    })

    "kube-scheduler.kubeconfig" = templatefile("${path.module}/templates/kubeconfig.tpl", {
      CA_CERT             = base64encode(module.ca.cert)
      CLIENT_CERT         = base64encode(module.kube_scheduler_cert.cert)
      CLIENT_KEY          = base64encode(module.kube_scheduler_cert.key)
      KUBERNETES_API_HOST = "127.0.0.1"
      KUBERNETES_API_PORT = var.apiserver_port
      CLUSTER             = var.cluster
      USER_NAME           = "system:kube-scheduler"
    })

    "admin.kubeconfig" = templatefile("${path.module}/templates/kubeconfig.tpl", {
      CA_CERT             = base64encode(module.ca.cert)
      CLIENT_CERT         = base64encode(module.admin_cert.cert)
      CLIENT_KEY          = base64encode(module.admin_cert.key)
      KUBERNETES_API_HOST = "127.0.0.1"
      KUBERNETES_API_PORT = var.apiserver_port
      CLUSTER             = var.cluster
      USER_NAME           = "admin"
    })

    "encryption-config.yaml" = templatefile("${path.module}/templates/encryption-config.yaml.tpl", {
      ENCRYPTION_KEY = base64encode(random_string.encryption_string.result)
    })

    "etcd.service" = templatefile("${path.module}/templates/etcd.service.tpl", {
      CONTROLLER_IP_CONFIG = join(",", [for ip in var.controller_ips: "ip-${replace(ip, ".", "-")}=https://${ip}:2380"])
    })

    "kube-apiserver.service" = templatefile("${path.module}/templates/kube-apiserver.service.tpl", {
      ETCD_SERVERS            = join(",", [for ip in var.controller_ips: "https://${ip}:2379"])
      CONTROLLER_COUNT        = var.controller_count
      APISERVER_PORT          = var.apiserver_port
      KUBERNETES_SERVICE_CIDR = var.service_cidr
    })

    "kube-controller-manager.service" = templatefile("${path.module}/templates/kube-controller-manager.service.tpl", {
      CLUSTER                 = var.cluster
      CLUSTER_CIDR            = var.cluster_cidr
      KUBERNETES_SERVICE_CIDR = var.service_cidr
    })

    "kube-scheduler.yaml" = templatefile("${path.module}/templates/kube-scheduler.yaml.tpl", {})
    "kube-scheduler.service" = templatefile("${path.module}/templates/kube-scheduler.service.tpl", {})
    "kubernetes.default.svc.cluster.local" = templatefile("${path.module}/templates/nginx-api-health.tpl", {})

    "init.sh" = templatefile("${path.module}/templates/controller_init.sh.tpl", {
      KUBERNETES_VERSION = local.kubernetes_version
      ETCD_VERSION       = "3.4.0"
    })
  }

  on_copy = [
    "sudo apt-get install -y unzip",
    "unzip -o /tmp/init.zip -d /tmp",
    "chmod +x /tmp/init.sh",
    "sudo /tmp/init.sh"
  ]

  name         = "controller"
  ssh_hosts    = var.controller_ips
  ssh_user     = "ubuntu"
  bastion_host = var.bastion_url
  bastion_user = "ubuntu"
}

module "worker_init_files" {
  source = "./modules/remote_archive"

  content = merge(
    zipmap(
      [for i in range(length(var.worker_ips)) : "kubelet-cert-${i}.pem"],
      [for i in range(length(var.worker_ips)) : module.kubelet_cert.cert[i]]
    ), 
    zipmap(
      [for i in range(length(var.worker_ips)) : "kubelet-key-${i}.pem"],
      [for i in range(length(var.worker_ips)) : module.kubelet_cert.key[i]]
    ),
    zipmap(
      [for i in range(length(var.worker_ips)) : "kubelet-${i}.kubeconfig"],
      [for i in range(length(var.worker_ips)) : templatefile("${path.module}/templates/kubeconfig.tpl", {
        CA_CERT             = base64encode(module.ca.cert)
        CLIENT_CERT         = base64encode(module.kubelet_cert.cert[i])
        CLIENT_KEY          = base64encode(module.kubelet_cert.key[i])
        KUBERNETES_API_HOST = aws_route53_record.kubernetes_api.name
        KUBERNETES_API_PORT = var.apiserver_port
        CLUSTER             = var.cluster
        USER_NAME           = local.worker_node_names[i]
      })]
    ),
    {
      "ca-cert.pem"      = module.ca.cert

      "kube-proxy.kubeconfig" = templatefile("${path.module}/templates/kubeconfig.tpl", {
        CA_CERT             = base64encode(module.ca.cert)
        CLIENT_CERT         = base64encode(module.kube_proxy_cert.cert)
        CLIENT_KEY          = base64encode(module.kube_proxy_cert.key)
        KUBERNETES_API_HOST = aws_route53_record.kubernetes_api.name
        KUBERNETES_API_PORT = var.apiserver_port
        CLUSTER             = var.cluster
        USER_NAME           = "system:kube-proxy"
      })

      "10-bridge.conf" = templatefile("${path.module}/templates/10-bridge.conf.tpl", {
        POD_CIDR = replace(cidrsubnet(var.cluster_cidr, 8, 255), "255", "<%instance_index%>")
      })
      "99-loopback.conf" = templatefile("${path.module}/templates/99-loopback.conf.tpl", {})

      "containerd-config.toml" = templatefile("${path.module}/templates/containerd-config.toml.tpl", {})
      "containerd.service" = templatefile("${path.module}/templates/containerd.service.tpl", {})

      "kubelet-config.yaml" = templatefile("${path.module}/templates/kubelet-config.yaml.tpl", {
        CLUSTER_DNS_IP = cidrhost(var.service_cidr, 10)
        POD_CIDR       = replace(cidrsubnet(var.cluster_cidr, 8, 255), "255", "<%instance_index%>")
      })
      "kubelet.service" = templatefile("${path.module}/templates/kubelet.service.tpl", {})

      "kube-proxy.service" = templatefile("${path.module}/templates/kube-proxy.service.tpl", {})
      "kube-proxy-config.yaml" = templatefile("${path.module}/templates/kube-proxy-config.yaml.tpl", {
        CLUSTER_CIDR = var.cluster_cidr
      })

      "init.sh" = templatefile("${path.module}/templates/worker_init.sh.tpl", {
        KUBERNETES_VERSION = local.kubernetes_version
      })
    }
  )

  on_copy = [
    "sudo apt-get install -y unzip",
    "unzip -o /tmp/init.zip -d /tmp",
    "chmod +x /tmp/init.sh",
    "sudo /tmp/init.sh"
  ]

  name         = "worker"
  ssh_hosts    = var.worker_ips
  ssh_user     = "ubuntu"
  bastion_host = var.bastion_url
  bastion_user = "ubuntu"
}
