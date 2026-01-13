# Use existing VPC
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Get subnet details for private subnets
data "aws_subnet" "private" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

# Get subnet details for public subnets (if provided)
data "aws_subnet" "public" {
  count = length(var.public_subnet_ids)
  id    = var.public_subnet_ids[count.index]
}

# Local values to reference subnets
locals {
  vpc_id             = data.aws_vpc.existing.id
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : var.private_subnet_ids
}

# DB Subnet Group using specified private subnets
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = local.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}
