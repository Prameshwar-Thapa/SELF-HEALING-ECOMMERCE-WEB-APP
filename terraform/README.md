# Terraform Infrastructure

This directory contains all Terraform configuration files for the self-healing e-commerce infrastructure.

## 📁 Structure

```
terraform/
├── main.tf                    # Root module configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars.dev       # Development environment variables
├── terraform.tfvars.prod      # Production environment variables
├── modules/                   # Reusable Terraform modules
│   ├── vpc/                  # Network infrastructure
│   ├── security/             # Security groups
│   ├── s3/                   # Storage buckets
│   ├── secrets/              # Secrets management
│   ├── rds/                  # Database
│   ├── iam/                  # Identity and access
│   ├── bastion/              # Management host
│   ├── ec2/                  # Compute resources
│   ├── cloudfront/           # Content delivery
│   └── waf/                  # Web Application Firewall
└── environments/             # Environment-specific configurations
    ├── dev/                  # Development environment
    └── prod/                 # Production environment
```

## 🚀 Quick Deploy

### Development Environment
```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars.dev"
terraform apply -var-file="terraform.tfvars.dev"
```

### Production Environment
```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars.prod"
terraform apply -var-file="terraform.tfvars.prod"
```

### Using Environment Directories
```bash
# Development
cd terraform/environments/dev
terraform init
terraform apply

# Production
cd terraform/environments/prod
terraform init
terraform apply
```

## 🏗️ Infrastructure Components

### Network Layer
- **VPC** with 3 availability zones
- **9 Subnets** (3 public, 3 private, 3 database)
- **Internet Gateway** and **3 NAT Gateways**
- **Route Tables** and **Security Groups**

### Compute Layer
- **Auto Scaling Group** (1-6 instances)
- **Application Load Balancer**
- **Launch Template** with user data
- **Bastion Host** for management

### Database Layer
- **RDS MySQL 8.0** with automated backups
- **Multi-AZ** deployment (production)
- **Encrypted storage**
- **Performance Insights** (production)

### Storage & CDN
- **S3 Buckets** for frontend and backend
- **CloudFront Distribution** with global caching
- **Origin Access Control** for security

### Security
- **IAM Roles** with least privilege
- **AWS Secrets Manager** for credentials
- **Security Groups** with minimal access
- **AWS WAF** for web application protection

## 📊 Environment Comparison

| Feature | Development | Production |
|---------|-------------|------------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 |
| **EC2 Instance** | t3.micro | t3.small |
| **RDS Instance** | db.t3.micro | db.t3.small |
| **RDS Multi-AZ** | No | Yes |
| **Auto Scaling** | 1-2 instances | 2-6 instances |
| **Backup Retention** | 7 days | 30 days |
| **Monitoring** | Basic | Enhanced + Performance Insights |
| **Deletion Protection** | No | Yes |

## 💰 Estimated Costs

### Development: ~$88-101/month
- EC2: ~$7-15 (1-2 t3.micro)
- RDS: ~$15 (db.t3.micro, single AZ)
- ALB: ~$16
- NAT Gateways: ~$45
- Other: ~$5-10

### Production: ~$136-201/month
- EC2: ~$30-90 (2-6 t3.small)
- RDS: ~$30 (db.t3.small, Multi-AZ)
- ALB: ~$16
- NAT Gateways: ~$45
- Enhanced Monitoring: ~$5
- Other: ~$10-15

## 🔧 Configuration

### Variables
Key variables in `variables.tf`:
- `project_name` - Project identifier
- `environment` - Environment (dev/prod)
- `aws_region` - AWS region
- `vpc_cidr` - VPC CIDR block
- `ec2_instance_type` - EC2 instance type
- `aws_db_instance_class` - RDS instance class

### Outputs
Key outputs in `outputs.tf`:
- `cloudfront_domain_name` - Frontend URL
- `alb_dns_name` - Load balancer endpoint
- `bastion_public_ip` - Management access
- `db_instance_endpoint` - Database endpoint

## 🔐 Security Features

- **IAM roles** with least privilege access
- **Security groups** with minimal required access
- **Encrypted storage** (RDS, S3)
- **Secrets stored** in AWS Secrets Manager
- **VPC** with private subnets for application tier
- **Bastion host** for secure administrative access
- **AWS WAF** protection against web attacks

## 📋 Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Appropriate AWS permissions
- S3 bucket for remote state (optional)

## 🗑️ Cleanup

```bash
# Development
terraform destroy -var-file="terraform.tfvars.dev"

# Production (requires manual confirmation due to deletion protection)
terraform destroy -var-file="terraform.tfvars.prod"
```
