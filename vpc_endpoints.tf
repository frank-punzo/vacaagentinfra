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

# VPC Endpoint for Cognito Identity Provider
# Allows Lambda to verify JWT tokens from Cognito
# NOTE: Cognito IdP endpoint only supports specific AZs, using only subnet in us-east-1b
resource "aws_vpc_endpoint" "cognito_idp" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.cognito-idp"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = ["subnet-0372d9741ca1e7f15"]  # Only us-east-1b supported
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${var.project_name}-cognito-idp-endpoint"
  }
}

# VPC Endpoint for Bedrock Runtime
# Allows Lambda to call Bedrock for AI recommendations
resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${var.project_name}-bedrock-runtime-endpoint"
  }
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

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["sg-04e5988ad026079b1"]
    description     = "Allow HTTPS from Stak Lambda"
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
