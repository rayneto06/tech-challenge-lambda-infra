output "invoke_url" {
  description = "URL de invocação da API Gateway"
  value       = aws_api_gateway_deployment.auth_deploy.invoke_url
}