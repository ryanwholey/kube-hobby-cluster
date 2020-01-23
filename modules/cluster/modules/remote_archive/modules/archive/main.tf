data "archive_file" "archive" {
  type        = "zip"
  output_path = "/tmp/${var.name}"

  dynamic "source" {
    for_each = var.content

    content {
      content  = source.value
      filename = source.key
    }
  }
}
