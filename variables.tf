variable "aws_region" {
  description = "Região AWS para provisionamento"
  type        = string
  default     = "us-east-1"
}

variable "lambda_runtime" {
  description = "Runtime da função Lambda"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_handler" {
  description = "Arquivo.handler da Lambda"
  type        = string
  default     = "auth_handler.handler"
}

variable "jwt_secret" {
  description = "Segredo para assinar o JWT"
  type        = string
}