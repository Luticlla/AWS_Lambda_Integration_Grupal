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