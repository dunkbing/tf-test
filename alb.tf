resource "aws_lb" "main" {
  name               = "${var.app_name}-${local.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = local.environment == "production" ? true : false

  tags = {
    Name        = "${var.app_name}-${local.environment}-alb"
    Environment = local.environment
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-${local.environment}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-302"
    interval            = 60  # Increased from 30
    timeout             = 30  # Increased from 5
    healthy_threshold   = 2   # Reduced from 3
    unhealthy_threshold = 5   # Increased from 3
  }

  tags = {
    Name        = "${var.app_name}-${local.environment}-tg"
    Environment = local.environment
  }
}

# HTTP listener (port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTPS listener (port 443) - Will be created after certificate validation
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"  # Modern, secure policy

  # Wait for certificate validation
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  # This ensures the HTTPS listener is only created after the certificate is validated
  depends_on = [
    aws_acm_certificate_validation.cert
  ]
}
