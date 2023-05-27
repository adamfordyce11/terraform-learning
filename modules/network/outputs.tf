
output "subnet_id" {
  description = "The ID of the subnet that has been created"
  value       = aws_subnet.networks[*].id
}