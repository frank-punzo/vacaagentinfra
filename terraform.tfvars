# AWS Configuration
aws_region = "us-east-1"
environment = "dev"
project_name = "vacaagent"

# VPC Configuration (using existing VPC)
vpc_id = "vpc-06afc2c5552066ee1"

# IMPORTANT: You must provide at least 2 private subnet IDs in different availability zones for RDS
# Get your subnet IDs from AWS Console or CLI: aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-06afc2c5552066ee1"
private_subnet_ids = [
  "subnet-0fe083cb15ddb520f",  # Replace with your private subnet ID in AZ1
  "subnet-0372d9741ca1e7f15"   # Replace with your private subnet ID in AZ2
]

# Optional: Public subnet IDs (used for Lambda if private subnets don't have NAT gateway)
public_subnet_ids = []

# RDS Configuration
db_name = "vacaagent"
db_username = "vacaadmin"
db_instance_class = "db.t3.micro"
db_allocated_storage = 20

# Lambda Configuration
lambda_runtime = "python3.12"
lambda_memory_size = 512
lambda_timeout = 30
