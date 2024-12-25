
## variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "greeting-app-demo"
  default = "greeting-app-demo"
  type        = string
}

variable "lambda_function_name" {
  description = "greeting-lambda"
  type        = string
  default     = "greeting-function"
}