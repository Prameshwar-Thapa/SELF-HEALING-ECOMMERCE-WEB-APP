#!/bin/bash
yum update -y
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install useful tools for troubleshooting
yum install -y htop net-tools telnet nc mysql

# Configure CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Create log directory
mkdir -p /var/log/${project_name}

# Set hostname
hostnamectl set-hostname ${project_name}-${environment}-bastion

echo "Bastion host setup completed" > /var/log/${project_name}/setup.log
