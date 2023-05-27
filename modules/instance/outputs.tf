output "instance_id" {
  value = aws_instance.vm.id
}

output "subnet_id" {
  value = data.aws_subnet.subnet.id
}