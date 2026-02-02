# =============================================================================
# SECURITY GROUPS
# =============================================================================

# Security Group for Lambda
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = local.vpc_id

  # Outbound to RDS - use VPC CIDR to avoid circular dependency
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
    description = "PostgreSQL access to RDS"
  }

  # Outbound HTTPS for AWS services (via VPC endpoints)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for AWS services (Secrets Manager, S3)"
  }

  tags = {
    Name = "${var.project_name}-lambda-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
    description     = "Allow PostgreSQL access from Lambda"
  }

  # Allow access from EC2 instance for database administration
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["sg-06378ce57d8707d40"]  # allow_ssh_access SG
    description     = "Allow PostgreSQL access from EC2 admin instance"
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
