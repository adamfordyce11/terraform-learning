
output "vpc_id" {
  description = "AWS VPC ID"
  value       = module.vpc[*].vpc_id
}

output "igw_id" {
  description = "AWS IGW ID"
  value       = module.vpc[*].igw_id
}

output "subnets" {
  description = "AWS Subnet IDs"
  value       = module.network[*].subnet_id
}

output "route_tables" {
  description = "AWS Route Table IDs"
  value       = module.routing[*].table_id
}