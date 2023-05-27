
output "table_id" {
  description = "The ID of the routing table"
  value       = aws_route_table.route_tables.id
}