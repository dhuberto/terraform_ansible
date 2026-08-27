output "instance_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "DNS público da instância"
  value       = aws_instance.web.public_dns
}

output "application_url" {
  description = "URL para acessar a aplicação"
  value       = "http://${aws_instance.web.public_ip}:3000"
}

output "security_group_id" {
  description = "ID do Security Group"
  value       = aws_security_group.web_sg.id
}

output "workspace_atual" {
  description = "Workspace atual"
  value       = terraform.workspace
}
