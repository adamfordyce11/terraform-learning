variable "vpc_cidr_block" {
  description = "Supernet CIDR for VPC"
  type = string
}

variable "region" {
  description = "AWS Region where resources will be created"
  type        = string
}

variable "region_short" {
  description = "AWS Region short name where resources will be created"
  type        = string
}

variable "environment" {
  description = "The name of the envronment being created"
  type = string
}

variable "account" {
  description = "The name of the account"
  type = string
}