# Production Environment
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

  # Remote state for production (recommended)
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "self-healing/prod/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Use the root module
module "self_healing_prod" {
  source = "../../"

  # Environment-specific variables
  project_name = "self-healing"
  environment  = "prod"
  aws_region   = "us-east-1"

  # Network Configuration (Different CIDR for prod)
  vpc_cidr = "10.1.0.0/16"
  azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Database Configuration (Prod - Better performance)
  aws_db_instance_class = "db.t3.small"
  db_name               = "ecommerce_db"
  deletion_protection   = true

  # Compute Configuration (Prod - Better performance)
  ec2_instance_type     = "t3.small"
  bastion_instance_type = "t3.micro"

  # Auto Scaling Configuration (Prod - Higher capacity)
  asg_min_size         = 2
  asg_max_size         = 6
  asg_desired_capacity = 3

  # Application Configuration
  api_url = ""

  # Tags
  tags = {
    Project     = "self-healing"
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = "production-team"
    CostCenter  = "production"
    Backup      = "required"
    Monitoring  = "critical"
  }
}

# Production-specific outputs
output "prod_cloudfront_domain" {
  description = "Production CloudFront domain"
  value       = module.self_healing_prod.cloudfront_domain_name
}

output "prod_alb_dns" {
  description = "Production ALB DNS name"
  value       = module.self_healing_prod.alb_dns_name
}

output "prod_bastion_ip" {
  description = "Production bastion public IP"
  value       = module.self_healing_prod.bastion_public_ip
}
