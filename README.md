# VacaAgent Infrastructure

Terraform infrastructure code for the VacaAgent vacation planning application.

## Architecture

- **Cloud Provider**: AWS
- **Database**: RDS PostgreSQL (db.t3.micro - Free Tier)
- **Compute**: AWS Lambda (Python 3.12)
- **API**: API Gateway (HTTP API)
- **Authentication**: Amazon Cognito
- **Storage**: Amazon S3 (vacation photos)
- **Networking**: VPC with public and private subnets

## Prerequisites

1. AWS Account
2. AWS CLI configured with credentials
3. Terraform >= 1.0

## Setup

### 1. Install Terraform

Download and install Terraform from: https://www.terraform.io/downloads

### 2. Configure AWS Credentials

```bash
aws configure
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

## Lambda Function Deployment

Before deploying, you need to create the Lambda deployment packages:

### Create Lambda Layer (Python dependencies)

```bash
mkdir -p lambda_layer/python
pip install psycopg2-binary boto3 requests -t lambda_layer/python/
cd lambda_layer
zip -r ../lambda_layer.zip python/
cd ..
```

### Create Lambda Function Package

```bash
cd ../vacaagent/lambda
zip -r ../../vacaagentinfra/lambda_function.zip .
cd ../../vacaagentinfra
```

Then run `terraform apply` again to update the Lambda functions.

## Outputs

After deployment, Terraform will output:

- API Gateway URL
- Cognito User Pool ID
- Cognito User Pool Client ID
- S3 Photos Bucket name

Use these values to configure your mobile application.

## Database Schema

To initialize the database schema, connect to the RDS instance and run the SQL migrations located in `../vacaagent/database/migrations/`.

## Cost Optimization

This infrastructure is designed to stay within AWS Free Tier limits:

- RDS: db.t3.micro instance, 20GB storage
- Lambda: 1 million free requests per month
- API Gateway: 1 million API calls per month
- S3: 5GB storage, 20,000 GET requests, 2,000 PUT requests per month
- Cognito: 50,000 MAUs free

**Note**: Monitor your usage to avoid unexpected charges.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Security Notes

1. Database credentials are stored in AWS Secrets Manager
2. RDS is in private subnets (not publicly accessible)
3. S3 bucket has public access blocked
4. API Gateway uses Cognito JWT authorization
5. All traffic uses HTTPS/TLS

## Production Considerations

Before deploying to production:

1. Enable RDS deletion protection
2. Configure S3 backend for Terraform state
3. Enable RDS multi-AZ deployment
4. Configure proper backup retention
5. Enable AWS CloudTrail for audit logging
6. Review and adjust IAM policies
7. Enable advanced Cognito security features
8. Configure custom domain for API Gateway
9. Set up CloudWatch alarms for monitoring
10. Enable AWS WAF for API protection
