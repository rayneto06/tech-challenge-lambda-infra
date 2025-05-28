terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Use qualquer 5.x ou deixe em branco para pegar a última:
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Arquivo ZIP da Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/auth_handler.zip"
  source_file = "${path.module}/auth_handler.js"
}

data "aws_iam_role" "lambda_exec" {
  name = "LabRole"
}

resource "aws_lambda_function" "auth" {
  function_name = "authByCpf"
  filename      = data.archive_file.lambda_zip.output_path
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = data.aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      JWT_SECRET = var.jwt_secret
    }
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "auth_api" {
  name        = "authByCpfAPI"
  description = "API para autenticar cliente por CPF"
}

# Resource /auth
resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_rest_api.auth_api.root_resource_id
  path_part   = "auth"
}

# Método POST /auth
resource "aws_api_gateway_method" "auth_post" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.auth_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integração Lambda
resource "aws_api_gateway_integration" "auth_integration" {
  rest_api_id             = aws_api_gateway_rest_api.auth_api.id
  resource_id             = aws_api_gateway_resource.auth_resource.id
  http_method             = aws_api_gateway_method.auth_post.http_method   # método da API (POST)
  integration_http_method = "POST"                                         # método da integração
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

# Deploy da API
resource "aws_api_gateway_deployment" "auth_deploy" {
  depends_on  = [ aws_api_gateway_integration.auth_integration ]
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  stage_name  = "prod"
}