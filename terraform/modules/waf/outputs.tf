output "cloudfront_web_acl_arn" {
  description = "ARN of the CloudFront WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront.arn
}

output "cloudfront_web_acl_id" {
  description = "ID of the CloudFront WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront.id
}

output "alb_web_acl_arn" {
  description = "ARN of the ALB WAF Web ACL"
  value       = aws_wafv2_web_acl.alb.arn
}

output "alb_web_acl_id" {
  description = "ID of the ALB WAF Web ACL"
  value       = aws_wafv2_web_acl.alb.id
}

output "waf_cloudfront_log_group_name" {
  description = "Name of the WAF CloudFront CloudWatch log group"
  value       = aws_cloudwatch_log_group.waf_cloudfront_log_group.name
}

output "waf_alb_log_group_name" {
  description = "Name of the WAF ALB CloudWatch log group"
  value       = aws_cloudwatch_log_group.waf_alb_log_group.name
}
