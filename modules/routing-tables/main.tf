# Create the routing tables
resource "aws_route_table" "route_tables" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.environment}-${var.account}-${var.route_tables[var.iteration]}"
    Account = var.account
    Environment = var.environment
  }
}

resource "aws_route" "igw" {
  count                     = "${var.route_tables[var.iteration] == "public" ? 1 : 0}"
  route_table_id            = aws_route_table.route_tables.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = var.igw_id
  depends_on                = [aws_route_table.route_tables]
}

