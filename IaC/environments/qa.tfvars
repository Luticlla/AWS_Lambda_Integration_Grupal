aws_region           = "us-east-1"
project_name         = "image-processor"
environment          = "qa"

lambda_runtime       = "nodejs20.x"
log_retention_days   = 14

vpc_cidr             = "10.1.0.0/16"
bucket_force_destroy = true

sqs_max_concurrency  = 3
