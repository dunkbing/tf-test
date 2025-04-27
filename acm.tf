variable "domain_name" {
  description = "The domain name for your application"
  type        = string
  default     = "eagleload.com"
}

variable "subdomain" {
  description = "The subdomain for your application"
  type        = string
  default     = "playground"
}

locals {
  fqdn = "${var.subdomain}.${var.domain_name}"
}

# Create an SSL certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = local.fqdn
  validation_method = "DNS"

  subject_alternative_names = [
    # "www.${local.fqdn}"  # Optional: Add www subdomain
  ]

  # Ensure proper key algorithm
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  tags = {
    Name        = "${var.app_name}-certificate"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create a DNS validation record set in Route53
# (This is optional - if you're using Cloudflare, you'll add these records there)
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_acm_certificate.cert.domain_validation_options : record.resource_record_name]

  # Comment out the above line and uncomment the following if not using Route53
  # timeouts {
  #   create = "60m"
  # }
}
