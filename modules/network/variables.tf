variable "vpc_id" {}
variable "igw_id" {}
variable "tables" {}
variable "iteration" {}

variable "network_names" {
  description = "List of network names"
  type        = list(any)
}

variable "az" {
  description = "Name of AZ where resources will be located"
  type        = string
}

variable "network_cidrs" {
  description = "List of network CIDR blocks"
  type        = list(any)
}

variable "route_tables" {
  description = "List of AWS route tables"
  type        = list(any)
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