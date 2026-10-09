variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto."
  type        = string
  default     = "image-processor"
}

variable "environment" {
  description = "Entorno oficial de despliegue. Solo puede ser dev, qa o prod."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "El entorno debe ser uno de estos valores: dev, qa o prod."
  }
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC. Cambia según el entorno."
  type        = string
  default     = "10.0.0.0/16"
}

variable "bucket_force_destroy" {
  description = "Permite que Terraform vacíe el bucket antes de eliminarlo. En prod debe ser false para no perder datos."
  type        = bool
  default     = false
}

variable "lambda_runtime" {
  description = "Versión de Node.js con la que corren las funciones Lambda."
  type        = string
  default     = "nodejs20.x"
}

variable "log_retention_days" {
  description = "Cantidad de días que se conservan los registros de los grupos de logs."
  type        = number
  default     = 14
}

variable "sqs_max_concurrency" {
  description = "Número máximo de ejecuciones simultáneas de crop-lambda controlado por el Event Source Mapping de SQS."
  type        = number
  default     = 5

  validation {
    condition     = var.sqs_max_concurrency >= 2 && var.sqs_max_concurrency <= 1000
    error_message = "sqs_max_concurrency debe estar entre 2 y 1000."
  }
}