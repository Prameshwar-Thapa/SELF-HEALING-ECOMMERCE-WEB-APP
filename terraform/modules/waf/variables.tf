variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "blocked_countries" {
  description = "List of country codes to block (optional)"
  type        = list(string)
  default     = null
  # Example: ["CN", "RU", "KP"] to block China, Russia, North Korea
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
