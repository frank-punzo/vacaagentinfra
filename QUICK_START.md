# VacaAgent Infrastructure - Quick Start Guide

## Prerequisites Checklist

- [ ] AWS CLI configured with credentials
- [ ] Terraform installed
- [ ] VPC ID and Subnet IDs ready
- [ ] Lambda source code is in `../vacaagent/lambda/src` (Terraform will auto-package)

## 1-Minute Deploy

```bash
cd /c/homestuff/code/vacaagentinfra

# Initialize (first time only)
terraform init

# Deploy (Terraform automatically packages Lambda code)
terraform apply -auto-approve

# Get API endpoint
terraform output api_gateway_url
```

## Update Frontend Config

After deployment, update `src/config/aws-config.js`:

```javascript
export const AWS_CONFIG = {
  cognito: {
    userPoolId: '<paste terraform output cognito_user_pool_id>',
    userPoolClientId: '<paste terraform output cognito_user_pool_client_id>',
    region: 'us-east-1',
  },
  api: {
    endpoint: '<paste terraform output api_gateway_url>',
  },
};
```

## Initialize Database

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)

# Get password from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id vacaagent-db-password \
  --query SecretString --output text | jq -r .password)

# Connect and initialize (from EC2/bastion in VPC)
psql -h $RDS_ENDPOINT -U vacaadmin -d vacaagent -f /path/to/schema.sql
```

## Verify Deployment

```bash
# Test API
curl $(terraform output -raw api_gateway_url)/vacations

# Check Lambda logs
aws logs tail /aws/lambda/vacaagent-api --follow
```

## Common Commands

```bash
# Update Lambda code (edit source files, then apply)
cd /c/homestuff/code/vacaagentinfra
terraform apply

# Change log level
aws lambda update-function-configuration \
  --function-name vacaagent-api \
  --environment "Variables={LOGLEVEL=DEBUG,DB_SECRET_ARN=$(terraform output -raw db_secret_arn),PHOTOS_BUCKET=$(terraform output -raw s3_photos_bucket),USER_POOL_ID=$(terraform output -raw cognito_user_pool_id),USER_POOL_CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id),ENVIRONMENT=dev}"

# Destroy everything
terraform destroy -auto-approve
```

## Troubleshooting

**Lambda can't connect to RDS:**
- Check security groups (Lambda → RDS on port 5432)
- Verify both in same VPC
- Check CloudWatch logs: `aws logs tail /aws/lambda/vacaagent-api`

**API returns 502:**
- Check Lambda function exists: `aws lambda get-function --function-name vacaagent-api`
- Check Lambda logs for errors
- Verify API Gateway permissions

**Frontend can't authenticate:**
- Verify Cognito IDs in frontend config
- Check CORS settings on API Gateway
- Test Cognito directly with AWS CLI

## Files to Update Before Deploy

1. **terraform.tfvars** - Set your VPC and subnet IDs
2. **Lambda source files** - Edit directly in `vacaagent/lambda/src/` (no zip needed)

## Current Infrastructure Status

✅ Lambda function includes:
- Vacations controller (full CRUD with logging)
- Events controller (full CRUD with logging)
- Stub controllers for other entities

✅ Terraform configured with:
- Automatic Lambda packaging from source (archive_file)
- LOGLEVEL environment variable
- All IAM permissions
- VPC and security groups
- RDS PostgreSQL
- S3 photos bucket
- Cognito user pool
- API Gateway

## Next Steps After Deploy

1. Initialize database schema
2. Update frontend configuration
3. Test authentication
4. Test vacation CRUD operations
5. Implement remaining entity controllers

---

For detailed instructions, see [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
