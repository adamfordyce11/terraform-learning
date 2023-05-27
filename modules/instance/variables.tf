variable "ami" {
  description = "The AWS AMI ID to use when creating the instance"
  type        = string
}

variable "instance_type" {
  description = "The AWS Instance type to use"
  type        = string
  default     = "t3.nano"
}

variable "name" {
  description = "The Instance name"
}

variable "instance_num" {
  description = "The number of the instance"
}

variable "network" {
  description = "The name of the network to attach the instance onto"
}

variable "azs" {}
variable "account" {}
variable "environment" {}
variable "service" {}
variable "region" {}
variable "vpc_id" {}
variable "public_ip" {
  description = "Should a public IP be associated with the instance?"
  type        = bool
  default     = false
}