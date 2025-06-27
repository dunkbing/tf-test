# RDS PostgreSQL Database Configuration

# Create a DB subnet group using the default VPC subnets
resource "aws_db_subnet_group" "postgres" {
  name       = "${var.app_name}-${local.environment}-db-subnet-group"
  subnet_ids = data.aws_subnets.all.ids

  tags = {
    Name        = "${var.app_name}-${local.environment}-db-subnet-group"
    Environment = local.environment
  }
}

# Security group for RDS PostgreSQL
resource "aws_security_group" "postgres" {
  name        = "${var.app_name}-${local.environment}-postgres-sg"
  description = "Security group for PostgreSQL database"
  vpc_id      = data.aws_vpc.default.id

  # PostgreSQL port access from anywhere (for external connections)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "PostgreSQL access from anywhere"
  }

  # Allow access from ECS tasks
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
    description     = "PostgreSQL access from ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${local.environment}-postgres-sg"
    Environment = local.environment
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier = "${var.app_name}-${local.environment}-postgres"

  # Database configuration
  engine         = "postgres"
  engine_version = "17.5"
  instance_class = local.db_instance_class

  # Storage configuration
  allocated_storage     = local.db_allocated_storage
  max_allocated_storage = local.db_max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  # Database credentials
  db_name  = local.db_name
  username = local.db_username
  password = local.db_password

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  publicly_accessible    = true

  # Backup configuration
  backup_retention_period = local.environment == "production" ? 7 : 1
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Deletion protection
  deletion_protection = local.environment == "production" ? true : false
  skip_final_snapshot = local.environment == "playground" ? true : false
  final_snapshot_identifier = local.environment == "production" ? "${var.app_name}-${local.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  # Performance insights
  performance_insights_enabled = local.environment == "production" ? true : false

  tags = {
    Name        = "${var.app_name}-${local.environment}-postgres"
    Environment = local.environment
  }
}

# Create a parameter group for custom PostgreSQL settings (optional)
resource "aws_db_parameter_group" "postgres" {
  family = "postgres15"
  name   = "${var.app_name}-${local.environment}-postgres-params"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # Log queries taking longer than 1 second
  }

  tags = {
    Name        = "${var.app_name}-${local.environment}-postgres-params"
    Environment = local.environment
  }
}
