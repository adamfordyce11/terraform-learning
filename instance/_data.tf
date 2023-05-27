
data "aws_vpc" "current_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-${var.account}"]
  }
}