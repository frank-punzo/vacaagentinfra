# =============================================================================
# VPC ENDPOINTS
# =============================================================================
# VPC Endpoints allow Lambda functions in private subnets to access AWS services
# without requiring a NAT Gateway, reducing costs while maintaining security.
# =============================================================================

# VPC Endpoint for Secrets Manager
# Allows Lambda to retrieve database credentials securely
# NOTE: If endpoint already exists in VPC, set create_secretsmanager_endpoint to false
resource "aws_vpc_endpoint" "secretsmanager" {
  count               = var.create_secretsmanager_endpoint ? 1 : 0
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = false  # Set to false to avoid conflicts with existing endpoint

  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${var.project_name}-secretsmanager-endpoint"
  }
}

# Data source to look up existing Secrets Manager endpoint if not creating one
data "aws_vpc_endpoint" "existing_secretsmanager" {
  count = var.create_secretsmanager_endpoint ? 0 : 1

  vpc_id       = local.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.secretsmanager"
}

# VPC Endpoint for S3
# Allows Lambda to access S3 for photo storage
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = data.aws_route_tables.private.ids

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}

# Security Group for VPC Endpoints (Interface endpoints only)
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
    description     = "Allow HTTPS from Lambda"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-vpc-endpoints-sg"
  }
}

# Get route tables for the private subnets
data "aws_route_tables" "private" {
  vpc_id = local.vpc_id

  filter {
    name   = "association.subnet-id"
    values = local.private_subnet_ids
  }
}
