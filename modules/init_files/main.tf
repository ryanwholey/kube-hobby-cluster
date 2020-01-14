resource "aws_s3_bucket" "launch_config" {
  bucket = "${var.cluster}-launch-config"
  acl    = "private"

  tags = {
    Name = "${var.cluster}-launch-config"
  }
}

resource "random_string" "encryption_seed" {
  length = 32
}

# CONTROLLER

resource "aws_s3_bucket_object" "controller_launch_config" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/init.sh"
  content = templatefile("${path.module}/controller_init.sh.tpl", {})
}

resource "aws_s3_bucket_object" "controller_encryption_config" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/encryption-config.yaml"
  content = templatefile("${path.module}/encryption_config.yaml.tpl", {
    ENCRYPTION_KEY = base64encode(random_string.encryption_seed.result)
  })
}

resource "aws_s3_bucket_object" "controller_ca_cert" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/ca-cert.pem"
  content = module.ca.cert
}

resource "aws_s3_bucket_object" "controller_ca_key" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/ca-key.pem"
  content = module.ca.key
}

resource "aws_s3_bucket_object" "controller_kubernetes_cert" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/kubernetes-cert.pem"
  content = module.kubernetes.cert
}

resource "aws_s3_bucket_object" "controller_kubernetes_key" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/kubernetes-key.pem"
  content = module.kubernetes.key
}

resource "aws_s3_bucket_object" "controller_service_account_cert" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/service-account-cert.pem"
  content = module.service_account.cert
}

resource "aws_s3_bucket_object" "controller_service_account_key" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/service-account-key.pem"
  content = module.service_account.key
}

resource "aws_s3_bucket_object" "controller_kube_apiserver_service" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/kube-apiserver.service"
  content = templatefile("${path.module}/templates/kube-apiserver.service.tpl", {
    APISERVER_PORT          = var.apiserver_port
    KUBERNETES_SERVICE_CIDR = var.kubernetes_service_cidr
    ETCD_DNS_NAME           = var.etcd_dns_name
    CONTROLLER_COUNT        = var.controller_count
  })
}

resource "aws_s3_bucket_object" "controller_kube_controller_manager_service" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/kube-controller-manager.service"
  content = templatefile("${path.module}/templates/kube-controller-manager.service.tpl", {
    KUBERNETES_SERVICE_CIDR = var.kubernetes_service_cidr
    CLUSTER_NAME            = var.cluster
    CLUSTER_CIDR            = var.cluster_cidr
  })
}

resource "aws_s3_bucket_object" "controller_kube_scheduler_config" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/kube-scheduler.yaml"
  content = templatefile("${path.module}/templates/kube-scheduler.yaml.tpl", {})
}

resource "aws_s3_bucket_object" "controller_kube_scheduler_service" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/kube-scheduler.service"
  content = templatefile("${path.module}/templates/kube-scheduler.service.tpl", {})
}


# WORKER

resource "aws_s3_bucket_object" "worker_launch_config" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/worker/init.sh"
  content = templatefile("${path.module}/worker_init.sh", {})
}

resource "aws_s3_bucket_object" "worker_ca_cert" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/worker/ca-cert.pem"
  content = module.ca.cert
}

resource "aws_s3_bucket_object" "worker_kubelet_cert" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/worker/kubelet-cert.pem"
  content = module.kubelet.cert
}

resource "aws_s3_bucket_object" "worker_kubelet_key" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/worker/kubelet-key.pem"
  content = module.kubelet.key
}




