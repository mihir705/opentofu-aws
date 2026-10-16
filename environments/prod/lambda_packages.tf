locals {
  lambda_packages = {
    for name, fn in var.lambda_functions : name => fn
    if try(fn.package_source_dir, null) != null && fn.s3_bucket != null && fn.s3_key != null
  }

  lambda_package_versions = {
    for name, object in aws_s3_object.lambda_package : name => object.version_id
  }
}

data "archive_file" "lambda_package" {
  for_each = local.lambda_packages

  type        = "zip"
  source_dir  = "${path.module}/${each.value.package_source_dir}"
  output_path = "${path.module}/.build/${each.key}.zip"
}

resource "aws_s3_object" "lambda_package" {
  for_each = local.lambda_packages

  bucket = each.value.s3_bucket
  key    = each.value.s3_key
  source = data.archive_file.lambda_package[each.key].output_path
  etag   = data.archive_file.lambda_package[each.key].output_md5

  depends_on = [module.s3]
}
