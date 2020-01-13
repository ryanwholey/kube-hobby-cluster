output "launch_config_bucket" {
  value = aws_s3_bucket.launch_config.id
}

output "launch_config_bucket_arn" {
  value = aws_s3_bucket.launch_config.arn
}
