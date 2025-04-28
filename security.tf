resource "aws_security_group" "alb" {
  name        = "${var.app_name}-${local.environment}-alb-sg"
  description = "Controls access to the ALB for ${local.environment} environment"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${local.environment}-alb-sg"
    Environment = local.environment
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-${local.environment}-ecs-tasks-sg"
  description = "Controls access to the ECS tasks for ${local.environment} environment"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${local.environment}-ecs-tasks-sg"
    Environment = local.environment
  }
}
