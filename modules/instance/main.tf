
resource "aws_instance" "vm" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name        = var.name
    Account     = var.account
    Environment = var.environment
    Service     = var.service
  }
  subnet_id = data.aws_subnet.subnet.id
}