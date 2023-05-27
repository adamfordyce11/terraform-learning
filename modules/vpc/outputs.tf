
output "vpc_id" {
  description = "The ID of the subnet that has been created"
  value       = aws_vpc.vpc.id
}

output "igw_id" {
  description = "The ID of the subnet that has been created"
  value       = aws_internet_gateway.igw.id
}