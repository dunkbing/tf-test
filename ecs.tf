resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-${local.environment}-cluster"

  tags = {
    Name        = "${var.app_name}-${local.environment}-cluster"
    Environment = local.environment
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.app_name}-${local.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.app_name}-${local.environment}-log-group"
    Environment = local.environment
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${local.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.cpu_value
  memory                   = local.memory_value
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-${local.environment}"
      image     = local.container_image_value
      essential = true
      cpu       = local.cpu_value
      memory    = local.memory_value

      # Use environmentFiles to load from S3
      environmentFiles = [
        {
          value = "arn:aws:s3:::${aws_s3_bucket.env_bucket.bucket}/.env"
          type  = "s3"
        }
      ]

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.app_name}-${local.environment}-task-def"
    Environment = local.environment
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-${local.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = local.desired_count_value
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = data.aws_subnets.all.ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.app_name}-${local.environment}"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http
  ]

  tags = {
    Name        = "${var.app_name}-${local.environment}-service"
    Environment = local.environment
  }
}
