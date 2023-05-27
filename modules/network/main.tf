locals {
  az = "${substr(var.region, 0, length(var.region) - 2)}-${var.az}"
}

# Create a subnet
resource "aws_subnet" "networks" {
  count             = length(var.network_names) > 0 ? length(var.network_names) : 0
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.network_cidrs[count.index], 4, var.iteration + count.index)
  availability_zone = local.az
  tags = {
    Name = "${var.environment}-${var.account}-${var.network_names[count.index]}-${var.az}"
    Account = var.account
    Environment = var.environment
  }
}

# Associate subnet with routing table
resource "aws_route_table_association" "route_table_association" {
  count          = length(var.network_names) > 0 ? length(var.network_names) : 0
  subnet_id      = aws_subnet.networks[count.index].id
  route_table_id = element(var.tables[*], count.index)
}