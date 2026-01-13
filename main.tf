# =============================================================================
# VacaAgent Infrastructure - AWS Lambda + API Gateway + RDS
# =============================================================================
# Architecture Overview:
# - API Gateway (HTTP API) - PUBLIC, accessible from internet
# - Lambda Functions - PRIVATE SUBNETS, access RDS and AWS services
# - RDS PostgreSQL - PRIVATE SUBNETS
# - VPC Endpoints - Allow Lambda to access AWS services without NAT Gateway
# - S3 - Photo storage
# - Cognito - User authentication
#
# Network Flow:
# 1. Mobile App → API Gateway (public, no VPC)
# 2. API Gateway → Lambda (in private subnets)
# 3. Lambda → RDS (via security groups)
# 4. Lambda → AWS Services (via VPC endpoints - no NAT Gateway needed)
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Optional: Configure S3 backend for state management
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "vacaagent/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "VacaAgent"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
