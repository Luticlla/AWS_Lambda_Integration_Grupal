# Aquí aterrizan los mensajes que la cola principal descartó tras 3 intentos;
# se guardan 14 días para alcanzar a diagnosticar qué salió mal.
resource "aws_sqs_queue" "dlq" {
  name                      = "${local.name_prefix}-image-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "main" {
  name = "${local.name_prefix}-image-queue"

  # 6 veces el timeout de crop-lambda: evita que un mensaje se entregue a otra
  # instancia mientras la primera todavía lo está procesando.
  visibility_timeout_seconds = 360

  message_retention_seconds = 86400
  receive_wait_time_seconds = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

data "aws_caller_identity" "current" {}

resource "aws_sqs_queue_policy" "s3_to_sqs" {
  queue_url = aws_sqs_queue.main.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowS3ToSendMessages"
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = ["sqs:SendMessage"]
      Resource  = aws_sqs_queue.main.arn
      Condition = {
        ArnLike      = { "aws:SourceArn" = local.bucket_arn }
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
      }
    }]
  })
}
