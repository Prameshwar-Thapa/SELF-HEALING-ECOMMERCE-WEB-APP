# Development Environment
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Optional: Remote state for team collaboration
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "self-healing/dev/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Use the root module
module "self_healing_dev" {
  source = "../../"

  # Environment-specific variables
  project_name = "self-healing"
  environment  = "dev"
  aws_region   = "us-east-1"

  # Network Configuration
  vpc_cidr = "10.0.0.0/16"
  azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Database Configuration (Dev)
  aws_db_instance_class = "db.t3.micro"
  db_name               = "ecommerce_db"
  deletion_protection   = false

  # Compute Configuration (Dev)
  ec2_instance_type     = "t3.micro"
  bastion_instance_type = "t3.micro"

  # Auto Scaling Configuration (Dev)
  asg_min_size         = 1
  asg_max_size         = 2
  asg_desired_capacity = 1

  # Application Configuration
  api_url = ""

  # Tags
  tags = {
    Project     = "self-healing"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "development-team"
    CostCenter  = "development"
  }
}

# Development-specific outputs
output "dev_cloudfront_domain" {
  description = "Development CloudFront domain"
  value       = module.self_healing_dev.cloudfront_domain_name
}

output "dev_alb_dns" {
  description = "Development ALB DNS name"
  value       = module.self_healing_dev.alb_dns_name
}

output "dev_bastion_ip" {
  description = "Development bastion public IP"
  value       = module.self_healing_dev.bastion_public_ip
}
