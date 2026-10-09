output "vpc_id" {
  description = "Identificador de la VPC privada creada para el proyecto."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Lista con los IDs de las dos subredes privadas."
  value       = local.private_subnet_ids
}

output "upload_lambda_sg_id" {
  description = "Identificador del grupo de seguridad de upload-lambda."
  value       = aws_security_group.upload_lambda.id
}

output "crop_lambda_sg_id" {
  description = "Identificador del grupo de seguridad de crop-lambda."
  value       = aws_security_group.crop_lambda.id
}

output "bucket_name" {
  description = "Nombre del bucket donde se almacenan las imágenes."
  value       = aws_s3_bucket.images.bucket
}

output "bucket_arn" {
  description = "ARN del bucket que guarda las imágenes."
  value       = aws_s3_bucket.images.arn
}

output "queue_url" {
  description = "URL de la cola principal que recibe las notificaciones de S3."
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "ARN de la cola principal que recibe las notificaciones de S3."
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "URL de la cola a la que llegan los mensajes agotados de intentos."
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN de la cola a la que llegan los mensajes agotados de intentos."
  value       = aws_sqs_queue.dlq.arn
}

output "upload_role_arn" {
  description = "ARN del rol IAM que asume upload-lambda."
  value       = aws_iam_role.upload_lambda.arn
}

output "crop_role_arn" {
  description = "ARN del rol IAM que asume crop-lambda."
  value       = aws_iam_role.crop_lambda.arn
}
