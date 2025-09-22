variable "project_name" {
  description = "The name of the project"
  type        = string

}

variable "environment" {
  description = "The environment (e.g. dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string

}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)

}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}

}