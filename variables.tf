variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-1"
}

variable "app_name" {
  description = "Name of your application"
  type        = string
  default     = "bun-app"
}

variable "environment" {
  description = "Environment name (e.g., playground, production)"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU units for the container"
  type        = map(number)
  default = {
    playground = 256
    production = 512
  }
}

variable "memory" {
  description = "Memory for the container in MiB"
  type        = map(number)
  default = {
    playground = 512
    production = 1024
  }
}

variable "desired_count" {
  description = "Number of instances of the task to run"
  type        = map(number)
  default = {
    playground = 1
    production = 1
  }
}

variable "container_image" {
  description = "The Docker Hub image to deploy (including tag)"
  type        = string
  default     = "080021083897.dkr.ecr.us-west-1.amazonaws.com/bun-app"
  # default     = "080021083897.dkr.ecr.us-west-1.amazonaws.com/bun-app:v1.9"
}

# Domain configuration
variable "domain_name" {
  description = "The domain name for your application"
  type        = string
  default     = "eagleload.com"
}

variable "subdomain" {
  description = "The subdomain for your application"
  type        = map(string)
  default = {
    playground = "playground"
    production = "api-v2"
  }
}

# Environment-specific variable lookups
locals {
  # Get the current Terraform workspace
  env = terraform.workspace

  # Normalize environment name for validation
  environment = local.env == "default" ? "playground" : local.env

  # Make sure we're using a valid environment
  valid_environments = ["playground", "production"]

  # Validate the environment
  validate_env = index(local.valid_environments, local.environment) >= 0 ? local.environment : "invalid"

  # CPU and memory values based on environment
  cpu_value           = var.cpu[local.environment]
  memory_value        = var.memory[local.environment]
  desired_count_value = var.desired_count[local.environment]
  subdomain_value     = var.subdomain[local.environment]

  # Extract the base ECR registry from the container_image variable
  # This assumes the format is "registry/image:tag"
  ecr_registry = split("/", var.container_image)[0]

  # Construct the environment-specific container image
  container_image_value = "${local.ecr_registry}/${var.app_name}-${local.environment}:v68"

  # Full domain name
  fqdn = "${local.subdomain_value}.${var.domain_name}"
}
