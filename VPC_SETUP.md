# VPC Configuration Guide

This guide will help you configure the VacaAgent infrastructure to use your existing VPC: **vpc-06afc2c5552066ee1**

## Step 1: Get Your Subnet Information

Run this command to list all subnets in your VPC:

```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-06afc2c5552066ee1" --query "Subnets[*].[SubnetId,AvailabilityZone,Tags[?Key=='Name'].Value|[0],CidrBlock,MapPublicIpOnLaunch]" --output table
```

This will show you:
- Subnet ID
- Availability Zone
- Name (if tagged)
- CIDR Block
- Whether it auto-assigns public IPs

## Step 2: Identify Your Subnets

You need to identify:

### Private Subnets (Required)
- At least **2 private subnets** in **different availability zones**
- Private subnets typically have:
  - `MapPublicIpOnLaunch: false`
  - Names like "private-subnet", "app-subnet", etc.
  - Routes to NAT Gateway instead of Internet Gateway

### Public Subnets (Optional)
- Public subnets typically have:
  - `MapPublicIpOnLaunch: true`
  - Names like "public-subnet", "web-subnet", etc.
  - Routes directly to Internet Gateway

## Step 3: Configure terraform.tfvars

Create `terraform.tfvars` from the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your subnet IDs:

```hcl
# VPC Configuration
vpc_id = "vpc-06afc2c5552066ee1"

# Replace with your actual private subnet IDs (must be in different AZs)
private_subnet_ids = [
  "subnet-abc123def456",  # Example: us-east-1a private subnet
  "subnet-xyz789ghi012"   # Example: us-east-1b private subnet
]

# Optional: Add public subnets if you need them
public_subnet_ids = []
```

## Important Notes

### For RDS:
- RDS requires at least **2 subnets in different availability zones**
- These subnets will be used to create the DB Subnet Group
- RDS will be placed in private subnets for security

### For Lambda:
- Lambda functions will be deployed in the private subnets
- They need internet access to reach AWS services (S3, Secrets Manager, etc.)
- Your private subnets should have a NAT Gateway for outbound internet access
- If you don't have NAT Gateway, Lambda functions will not be able to make outbound connections

### Checking NAT Gateway:

```bash
# Check route tables for your private subnets
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-06afc2c5552066ee1" --query "RouteTables[*].[RouteTableId,Routes[?NatGatewayId].NatGatewayId|[0],Associations[*].SubnetId]" --output table
```

If your private subnets don't have NAT Gateway routes, you have two options:
1. Create a NAT Gateway (costs ~$32/month)
2. Put Lambda in public subnets instead (less secure but works)

## Step 4: Verify Configuration

Before running Terraform, verify:

1. Your subnets exist:
```bash
aws ec2 describe-subnets --subnet-ids subnet-abc123def456 subnet-xyz789ghi012
```

2. They are in different AZs:
```bash
aws ec2 describe-subnets --subnet-ids subnet-abc123def456 subnet-xyz789ghi012 --query "Subnets[*].[SubnetId,AvailabilityZone]" --output table
```

3. Your VPC has DNS support enabled:
```bash
aws ec2 describe-vpc-attribute --vpc-id vpc-06afc2c5552066ee1 --attribute enableDnsSupport
aws ec2 describe-vpc-attribute --vpc-id vpc-06afc2c5552066ee1 --attribute enableDnsHostnames
```

Both should return `true`. If not, enable them:
```bash
aws ec2 modify-vpc-attribute --vpc-id vpc-06afc2c5552066ee1 --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id vpc-06afc2c5552066ee1 --enable-dns-hostnames
```

## Example Configuration

Here's an example of what your subnet configuration might look like:

```hcl
vpc_id = "vpc-06afc2c5552066ee1"

private_subnet_ids = [
  "subnet-0a1b2c3d4e5f67890",  # us-east-1a (10.0.1.0/24)
  "subnet-0f9e8d7c6b5a43210"   # us-east-1b (10.0.2.0/24)
]

public_subnet_ids = []  # Leave empty unless Lambda needs to be in public subnets
```

## Troubleshooting

### "No subnets found" error
- Verify the VPC ID is correct
- Check that subnets exist in the VPC
- Ensure your AWS credentials have permission to describe subnets

### "InvalidSubnet" error
- Verify subnet IDs are correct (no typos)
- Ensure subnets are in the specified VPC
- Check that subnets are in different availability zones

### Lambda can't connect to RDS
- Verify security group rules allow Lambda SG → RDS SG on port 5432
- Check that both Lambda and RDS are in the same VPC
- Verify private subnets have route to NAT Gateway

### Lambda can't access internet (AWS services)
- Verify private subnets have route to NAT Gateway
- Check NAT Gateway is in a public subnet
- Verify public subnet has route to Internet Gateway
- Consider using VPC endpoints for AWS services (S3, Secrets Manager, etc.)

## Next Steps

Once you've configured `terraform.tfvars`:

1. Initialize Terraform: `terraform init`
2. Review the plan: `terraform plan`
3. Apply the infrastructure: `terraform apply`
