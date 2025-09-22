output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.bastion_key.key_name
}

output "private_key_secret_arn" {
  description = "ARN of the secret containing the private key"
  value       = aws_secretsmanager_secret.bastion_private_key.arn
}
