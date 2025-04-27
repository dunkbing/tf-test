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
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "playground"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU units for the container"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory for the container in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of instances of the task to run"
  type        = number
  default     = 2
}

variable "container_image" {
  description = "The Docker Hub image to deploy (including tag)"
  type        = string
  default     = "your-dockerhub-username/bun-app:latest"
}
