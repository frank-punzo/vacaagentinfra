variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "vacaagent"
}

# VPC Configuration
variable "vpc_id" {
  description = "Existing VPC ID to use"
  type        = string
  default     = "vpc-06afc2c5552066ee1"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs in the existing VPC"
  type        = list(string)
  default     = [] # Must be provided - at least 2 subnets in different AZs for RDS
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs in the existing VPC (optional)"
  type        = list(string)
  default     = []
}

# RDS Configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "vacaagent"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "vacaadmin"
}

variable "db_instance_class" {
  description = "RDS instance class (free tier: db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB (free tier: up to 20GB)"
  type        = number
  default     = 20
}

# Lambda Configuration
variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

# VPC Endpoint Configuration
variable "create_secretsmanager_endpoint" {
  description = "Create Secrets Manager VPC endpoint (set to false if endpoint already exists)"
  type        = bool
  default     = false  # Default to false since you already have one
}
