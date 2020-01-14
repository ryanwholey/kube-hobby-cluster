resource "aws_s3_bucket" "launch_config" {
  bucket = "${var.cluster}-launch-config"
  acl    = "private"

  tags = {
    Name = "${var.cluster}-launch-config"
  }
}

# CONTROLLER

resource "aws_s3_bucket_object" "controller_launch_config" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/init.sh"
  content = templatefile("${path.module}/controller_init.sh", {})
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

resource "aws_s3_bucket_object" "controller_service_accounts_cert" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/service-accounts-cert.pem"
  content = module.service_accounts.cert
}

resource "aws_s3_bucket_object" "controller_service_accounts_key" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/service-accounts-key.pem"
  content = module.service_accounts.key
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




