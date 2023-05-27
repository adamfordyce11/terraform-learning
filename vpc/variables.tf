variable "region" {
  description = "AWS Region"
  default     = "eu-west-1"
}

variable "region_short" {
  description = "The short name for the AWS Region"
  default     = "ew1"
}

variable "environment" {
  description = "Name of VPC"
}

variable "vpc_cidr_block" {
  description = "CIDR Block for the specified VPC"
}

variable "network_names" {
  description = "List of network names"
}

variable "network_cidrs" {
  description = "List of network cidrs"
}

variable "route_tables" {
  description = "List of network route_tables"
}

variable "availability_zones" {
  description = "List of availability zones where to create resources"
}

variable "account" {
  description = "Name of account"
  default     = "root"
}