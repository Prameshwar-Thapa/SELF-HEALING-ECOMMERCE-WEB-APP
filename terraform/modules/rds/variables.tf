variable "project_name" {
  description = "The name of the project"
  type        = string

}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string

}

variable "vpc_id" {
  description = "The ID of the VPC where RDS will be deployed"
  type        = string

}
variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS subnet group"
  type        = list(string)

}
variable "security_group_ids" {
  description = "List of security group IDs to associate with the RDS instance"
  type        = list(string)

}

variable "aws_db_instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"

}

variable "db_name" {
  description = "The name of the initial database to create"
  type        = string
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the RDS instance"
  type        = bool
  default     = false
}
variable "tags" {
  description = "A map of tags to assign to the RDS resources"
  type        = map(string)
  default     = {}
}