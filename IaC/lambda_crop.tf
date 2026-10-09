resource "aws_cloudwatch_log_group" "crop" {
  name              = "/aws/lambda/${local.crop_function_name}"
  retention_in_days = var.log_retention_days
}

data "archive_file" "crop" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/crop/build"
  output_path = "${path.module}/build/crop.zip"
}

resource "aws_lambda_function" "crop" {
  function_name = local.crop_function_name
  role          = aws_iam_role.crop_lambda.arn
  handler       = "index.handler"
  runtime       = var.lambda_runtime
  architectures = ["x86_64"]
  memory_size   = 512
  timeout       = 60

  filename         = data.archive_file.crop.output_path
  source_code_hash = data.archive_file.crop.output_base64sha256

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.id
      UPLOAD_PREFIX    = local.upload_prefix
      PROCESSED_PREFIX = local.processed_prefix
      CROP_SIZE        = "40"
    }
  }

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.crop_lambda.id]
  }

  depends_on = [
    aws_cloudwatch_log_group.crop,
    aws_iam_role_policy_attachment.crop_basic,
    aws_iam_role_policy_attachment.crop_vpc,
    aws_iam_role_policy.crop_permissions,
  ]
}

resource "aws_lambda_event_source_mapping" "crop_sqs" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.crop.arn
  batch_size       = 5
  enabled          = true

  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.sqs_max_concurrency
  }

  depends_on = [aws_iam_role_policy.crop_permissions]
}

output "crop_function_name" {
  description = "Nombre de la función Lambda encargada de recortar las imágenes."
  value       = aws_lambda_function.crop.function_name
}
