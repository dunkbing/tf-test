resource "aws_s3_bucket" "env_bucket" {
  bucket = "${var.app_name}-env-${local.environment}"

  tags = {
    Name        = "${var.app_name}-env-${local.environment}-bucket"
    Environment = local.environment
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "env_bucket_access" {
  bucket = aws_s3_bucket.env_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "env_bucket_encryption" {
  bucket = aws_s3_bucket.env_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "env_bucket_policy" {
  bucket = aws_s3_bucket.env_bucket.id

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
        Principal = {
          AWS = aws_iam_role.ecs_execution_role.arn
        }
      }
    ]
  })
}
