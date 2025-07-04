output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "container_image" {
  description = "Docker image being used"
  value       = var.container_image
}

output "environment" {
  description = "Current environment"
  value       = local.environment
}

# Output the full domain name
output "fqdn" {
  description = "Fully qualified domain name for the application"
  value       = local.fqdn
}

# Output the validation records for configuration in Cloudflare
output "certificate_validation_details" {
  description = "DNS records required for certificate validation"
  value = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

# Simple outputs for script use
output "domain_name" {
  description = "Domain name for the application"
  value       = var.domain_name
}

output "subdomain" {
  description = "Subdomain for the application"
  value       = local.subdomain_value
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.cert.arn
}

output "s3_env_bucket" {
  description = "S3 bucket for environment variables"
  value       = aws_s3_bucket.env_bucket.bucket
}

# Database outputs
output "db_endpoint" {
  description = "PostgreSQL database endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "db_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.postgres.db_name
}

output "db_username" {
  description = "PostgreSQL database username"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "db_password" {
  description = "PostgreSQL database password"
  value       = local.db_password
  sensitive   = true
}

output "db_port" {
  description = "PostgreSQL database port"
  value       = aws_db_instance.postgres.port
}

output "db_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${aws_db_instance.postgres.username}:${local.db_password}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
  sensitive   = true
}
