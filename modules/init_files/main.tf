resource "aws_s3_bucket" "launch_config" {
  bucket = "${var.cluster}-launch-config"
  acl    = "private"

  tags = {
    Name = "${var.cluster}-launch-config"
  }
}

resource "aws_s3_bucket_object" "controller_launch_config" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/controller/init.sh"
  content = templatefile("${path.module}/controller_init.sh", {})
}

resource "aws_s3_bucket_object" "worker_launch_config" {
  bucket  = aws_s3_bucket.launch_config.id
  key     = "/worker/init.sh"
  content = templatefile("${path.module}/worker_init.sh", {})
}

