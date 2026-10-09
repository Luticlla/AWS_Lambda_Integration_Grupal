resource "aws_cloudwatch_log_group" "upload" {
  name              = "/aws/lambda/${local.upload_function_name}"
  retention_in_days = var.log_retention_days
}

data "archive_file" "upload" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/upload/build"
  output_path = "${path.module}/build/upload.zip"
}

resource "aws_lambda_function" "upload" {
  function_name = local.upload_function_name
  role          = aws_iam_role.upload_lambda.arn
  handler       = "index.handler"
  runtime       = var.lambda_runtime
  architectures = ["x86_64"]
  memory_size   = 256
  timeout       = 30

  filename         = data.archive_file.upload.output_path
  source_code_hash = data.archive_file.upload.output_base64sha256

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.id
      UPLOAD_PREFIX    = local.upload_prefix
      MAX_UPLOAD_BYTES = "4194304"
    }
  }

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.upload_lambda.id]
  }

  depends_on = [
    aws_cloudwatch_log_group.upload,
    aws_iam_role_policy_attachment.upload_basic,
    aws_iam_role_policy_attachment.upload_vpc,
    aws_iam_role_policy.upload_s3,
  ]
}

output "upload_function_name" {
  description = "Nombre de la función Lambda que recibe las imágenes subidas."
  value       = aws_lambda_function.upload.function_name
}
