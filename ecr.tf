resource "aws_ecr_repository" "app" {
  name                 = "${var.app_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Enable encryption
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.app_name}-ecr"
  }
}

# Define a lifecycle policy to keep only the latest 10 images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Add ECR repository URL to outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

# Output the registry ID (AWS account ID) for convenience
output "ecr_registry_id" {
  description = "Registry ID (AWS account ID) for the ECR repository"
  value       = aws_ecr_repository.app.registry_id
}
