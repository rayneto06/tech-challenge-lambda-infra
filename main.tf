terraform {
  required_providers {
    aws = { source="hashicorp/aws", version="~>5.0" }
    archive = { source="hashicorp/archive" }
  }
}
provider "aws" { region = var.aws_region }

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/auth_handler.js"
  output_path = "${path.module}/auth_handler.zip"
}

data "aws_iam_role" "lambda_exec" {
  name = "LabRole"
}

resource "aws_api_gateway_rest_api" "auth_api" {
  name        = "authByCpfAPI"
  description = "Authenticate by CPF"
}

resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_rest_api.auth_api.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_method" "auth_post" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.auth_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_integration" {
  rest_api_id             = aws_api_gateway_rest_api.auth_api.id
  resource_id             = aws_api_gateway_resource.auth_resource.id
  http_method             = aws_api_gateway_method.auth_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

resource "aws_api_gateway_deployment" "auth_deploy" {
  depends_on  = [aws_api_gateway_integration.auth_integration]
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  stage_name  = "prod"
}

resource "aws_lambda_function" "auth" {
  function_name = "authByCpf"
  filename      = data.archive_file.lambda_zip.output_path
  handler       = var.lambda_handler    # ex: "auth_handler.handler"
  runtime       = var.lambda_runtime    # ex: "nodejs18.x"
  role          = data.aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      JWT_SECRET      = var.jwt_secret
      CUSTOMERS_TABLE = var.customers_table_name
    }
  }
}

resource "aws_iam_policy" "lambda_dynamodb" {
  count       = var.skip_policy_creation ? 0 : 1
  name        = "lambda-dynamodb-read-customers"
  description = "Permite que a lambda consulte o DynamoDB Customers"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["dynamodb:GetItem"],
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.customers_table_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  count      = var.skip_policy_creation ? 0 : 1
  role       = data.aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_dynamodb[0].arn
}

data "aws_caller_identity" "current" {}