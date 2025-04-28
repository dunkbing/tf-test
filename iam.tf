resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.app_name}-${local.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-${local.environment}-ecs-execution-role"
    Environment = local.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app_name}-${local.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-${local.environment}-ecs-task-role"
    Environment = local.environment
  }
}

resource "aws_iam_policy" "s3_env_access_for_execution" {
  name        = "${var.app_name}-${local.environment}-s3-env-access-execution"
  description = "Policy to allow ECS execution role to access environment variables in S3 for ${local.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.env_bucket.arn,
          "${aws_s3_bucket.env_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach S3 access policy to the ECS execution role
resource "aws_iam_role_policy_attachment" "ecs_execution_s3_access" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.s3_env_access_for_execution.arn
}
