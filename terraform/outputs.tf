output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.aws_internet_gateway
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

# RDS Outputs
output "db_instance_endpoint" {
  description = "The RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_port" {
  description = "The RDS instance port"
  value       = module.rds.db_instance_port
}

output "db_secret_arn" {
  description = "The ARN of the secret containing DB credentials"
  value       = module.rds.db_secret_arn
}

# IAM Outputs
output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = module.iam.ec2_role_arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = module.iam.ec2_instance_profile_name
}

# Bastion Outputs
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "bastion_private_key_secret_arn" {
  description = "ARN of the secret containing the bastion private key"
  value       = module.bastion.private_key_secret_arn
}

# Secrets Outputs
output "app_config_secret_arn" {
  description = "ARN of the application config secret"
  value       = module.secrets.app_config_secret_arn
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret"
  value       = module.secrets.jwt_secret_arn
}

# EC2 and ALB Outputs
output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.ec2.alb_dns_name
}

# CloudFront Outputs
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.cloudfront_distribution_id
}

# WAF Outputs
output "waf_cloudfront_web_acl_id" {
  description = "CloudFront WAF Web ACL ID"
  value       = module.waf.cloudfront_web_acl_id
}

output "waf_alb_web_acl_id" {
  description = "ALB WAF Web ACL ID"
  value       = module.waf.alb_web_acl_id
}

output "waf_cloudfront_log_group_name" {
  description = "WAF CloudFront CloudWatch log group name"
  value       = module.waf.waf_cloudfront_log_group_name
}

output "waf_alb_log_group_name" {
  description = "WAF ALB CloudWatch log group name"
  value       = module.waf.waf_alb_log_group_name
}

output "backend_bucket_name" {
  description = "Name of the backend S3 bucket"
  value       = module.s3.backend_bucket_name
}
