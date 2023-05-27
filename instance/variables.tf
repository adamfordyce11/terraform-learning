variable "name" {}
variable "service" {}
variable "ami" {}
variable "num_instances" {}
variable "azs" {}
variable "instance_type" {
  description = "Default instance type to use when creating AWS resource"
  type        = string
  default     = "t3.nano"
}
variable "network" {}