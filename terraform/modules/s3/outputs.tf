output "frontend_bucket_id" {
  value = aws_s3_bucket.Frontend.id
}

output "backend_bucket_id" {
  value = aws_s3_bucket.Backend.id
}

output "frontend_bucket_domain_name" {
  value = aws_s3_bucket.Frontend.bucket_domain_name
}

output "backend_bucket_domain_arn" {
  value = aws_s3_bucket.Backend.arn
}

output "backend_bucket_name" {
  description = "Name of the backend S3 bucket"
  value       = aws_s3_bucket.Backend.id
}