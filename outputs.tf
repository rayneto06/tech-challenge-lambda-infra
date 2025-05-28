output "invoke_url" {
  description = "POST URL for /auth"
  value       = aws_api_gateway_deployment.auth_deploy.invoke_url
}
