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

# variables.tf
variable "jwt_secret" {
  type        = string
  description = "Segredo para assinar JWT"
}

variable "customers_table_name" {
  type        = string
  description = "Nome da tabela DynamoDB de clientes"
}
