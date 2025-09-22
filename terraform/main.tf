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
  }

  backend "s3" {
    bucket = "aws-terraform-backend-bucket-123"
    key    = "self-healing-terraform/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  azs          = var.azs
  tags         = var.tags
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  tags         = var.tags
}

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  api_url      = var.api_url
  tags         = var.tags
}

module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_ids    = [module.security.rds_security_group_id]
  aws_db_instance_class = var.aws_db_instance_class
  db_name               = var.db_name
  deletion_protection   = var.deletion_protection
  tags                  = var.tags
}

module "iam" {
  source = "./modules/iam"

  project_name                   = var.project_name
  environment                    = var.environment
  aws_region                     = var.aws_region
  account_id                     = data.aws_caller_identity.current.account_id
  s3_bucket_name                 = module.s3.backend_bucket_name
  db_secret_arn                  = module.rds.db_secret_arn
  app_config_secret_arn          = module.secrets.app_config_secret_arn
  jwt_secret_arn                 = module.secrets.jwt_secret_arn
  bastion_private_key_secret_arn = module.bastion.private_key_secret_arn
  tags                           = var.tags
}

module "bastion" {
  source = "./modules/bastion"

  project_name              = var.project_name
  environment               = var.environment
  instance_type             = var.bastion_instance_type
  public_subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_id         = module.security.bastion_security_group_id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  tags                      = var.tags
}

module "ec2" {
  source = "./modules/ec2"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_subnet_ids     = module.vpc.private_subnet_ids
  alb_security_group_id  = module.security.alb_security_group_id
  ec2_security_group_id  = module.security.ec2_security_group_id
  instance_profile_name  = module.iam.ec2_instance_profile_name
  backend_bucket_name    = module.s3.backend_bucket_name
  db_endpoint            = module.rds.db_instance_endpoint
  aws_region             = var.aws_region
  db_secret_name         = module.rds.db_secret_name
  app_config_secret_name = module.secrets.app_config_secret_name
  jwt_secret_name        = module.secrets.jwt_secret_name
  min_size               = var.asg_min_size
  max_size               = var.asg_max_size
  desired_capacity       = var.asg_desired_capacity
  instance_type          = var.ec2_instance_type
  tags                   = var.tags
}

# WAF Module
module "waf" {
  source = "./modules/waf"

  project_name      = var.project_name
  environment       = var.environment
  alb_arn           = module.ec2.alb_arn
  blocked_countries = var.blocked_countries
  tags              = var.tags
}

module "cloudfront" {
  source = "./modules/cloudfront"

  project_name                = var.project_name
  environment                 = var.environment
  frontend_bucket_name        = module.s3.frontend_bucket_id
  frontend_bucket_domain_name = module.s3.frontend_bucket_domain_name
  alb_dns_name                = module.ec2.alb_dns_name
  waf_web_acl_arn             = module.waf.cloudfront_web_acl_arn
  tags                        = var.tags
}
