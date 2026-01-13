# VacaAgent Infrastructure Architecture

## Overview

VacaAgent uses a serverless architecture on AWS with Lambda functions in private subnets accessing RDS, while API Gateway remains public. This design eliminates the need for expensive NAT Gateways by using VPC endpoints for AWS service access.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         PUBLIC INTERNET                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │   Mobile App (Expo)  │
                  │  React Native Client │
                  └──────────┬───────────┘
                             │ HTTPS
                             ▼
                  ┌──────────────────────┐
                  │   API Gateway        │
                  │   (HTTP API)         │
                  │   - PUBLIC           │
                  │   - JWT Auth         │
                  └──────────┬───────────┘
                             │
                             │ Invokes
                             ▼
┌────────────────────────────────────────────────────────────────┐
│                    VPC (vpc-06afc2c5552066ee1)                 │
│                                                                 │
│  ┌─────────────────────── PRIVATE SUBNETS ─────────────────┐  │
│  │                                                           │  │
│  │  ┌──────────────────────┐                               │  │
│  │  │   Lambda Functions   │                               │  │
│  │  │   - VacaAgent API    │                               │  │
│  │  │   - Python 3.12      │                               │  │
│  │  │   - psycopg2 layer   │                               │  │
│  │  └─────────┬────────────┘                               │  │
│  │            │                                              │  │
│  │            ├─────────────────┐                           │  │
│  │            │                 │                           │  │
│  │            ▼                 ▼                           │  │
│  │  ┌──────────────────┐  ┌──────────────────┐            │  │
│  │  │   RDS PostgreSQL │  │  VPC Endpoints   │            │  │
│  │  │   - db.t3.micro  │  │  - Secrets Mgr   │            │  │
│  │  │   - Private only │  │  - S3 Gateway    │            │  │
│  │  └──────────────────┘  └──────────────────┘            │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ VPC Endpoints
                             ▼
                  ┌──────────────────────┐
                  │   AWS Services       │
                  │   - Secrets Manager  │
                  │   - S3 (photos)      │
                  │   - Cognito          │
                  └──────────────────────┘
```

## Component Details

### 1. API Gateway (HTTP API)
- **Location**: Public internet
- **Purpose**: Entry point for all API requests
- **Features**:
  - JWT-based authentication (Cognito)
  - CORS configuration
  - Request routing
  - Throttling
- **Cost**: ~$1.00 per million requests (first 300M requests free for 12 months)

### 2. Lambda Functions
- **Location**: Private subnets in existing VPC
- **Purpose**: Business logic and data access
- **Configuration**:
  - Runtime: Python 3.12
  - Memory: 512MB
  - Timeout: 30 seconds
  - Layer: psycopg2 for PostgreSQL
- **Network Access**:
  - Inbound: API Gateway only
  - Outbound: RDS (port 5432) and AWS services (port 443)
- **Cost**: Free tier includes 1M requests and 400,000 GB-seconds per month

### 3. RDS PostgreSQL
- **Location**: Private subnets (at least 2 AZs)
- **Purpose**: Persistent data storage
- **Configuration**:
  - Instance: db.t3.micro
  - Storage: 20GB gp2
  - Engine: PostgreSQL 16.3
- **Security**:
  - Only accessible from Lambda security group
  - Credentials in AWS Secrets Manager
- **Cost**: Free tier includes 750 hours per month for 12 months

### 4. VPC Endpoints
VPC endpoints eliminate the need for NAT Gateway, significantly reducing costs.

#### Secrets Manager Endpoint (Interface)
- **Type**: Interface endpoint (PrivateLink)
- **Purpose**: Lambda retrieves DB credentials
- **Cost**: ~$7.20/month + data processing
- **Why**: Secure credential access without internet

#### S3 Endpoint (Gateway)
- **Type**: Gateway endpoint
- **Purpose**: Lambda uploads/downloads vacation photos
- **Cost**: FREE
- **Why**: No data transfer charges within same region

### 5. Cognito User Pool
- **Location**: AWS managed service (not in VPC)
- **Purpose**: User authentication and management
- **Features**:
  - Email-based sign-up
  - JWT token generation
  - Password policies
  - MFA support (optional)
- **Cost**: Free for first 50,000 MAUs

### 6. S3 Bucket
- **Location**: AWS managed service
- **Purpose**: Store vacation photos
- **Features**:
  - Versioning enabled
  - Server-side encryption
  - CORS for mobile uploads
  - Lifecycle policies
- **Cost**: Free tier includes 5GB storage, 20K GET, 2K PUT requests

## Security Architecture

### Network Security

```
┌─────────────────────────────────────────────────────────┐
│ Security Group: Lambda                                  │
│                                                          │
│ Ingress: NONE (Lambda doesn't accept inbound traffic)  │
│                                                          │
│ Egress:                                                 │
│  - Port 5432 → RDS Security Group (PostgreSQL)        │
│  - Port 443 → 0.0.0.0/0 (AWS services via endpoints)  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Security Group: RDS                                     │
│                                                          │
│ Ingress:                                                │
│  - Port 5432 ← Lambda Security Group (PostgreSQL)      │
│                                                          │
│ Egress: NONE (RDS doesn't need outbound)               │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Security Group: VPC Endpoints                           │
│                                                          │
│ Ingress:                                                │
│  - Port 443 ← Lambda Security Group (HTTPS)            │
│                                                          │
│ Egress:                                                 │
│  - Port 443 → 0.0.0.0/0 (AWS services)                │
└─────────────────────────────────────────────────────────┘
```

### IAM Permissions

Lambda execution role has:
- `AWSLambdaBasicExecutionRole` - CloudWatch Logs
- `AWSLambdaVPCAccessExecutionRole` - VPC networking
- Custom policy for:
  - `secretsmanager:GetSecretValue` - Database credentials
  - `s3:GetObject`, `s3:PutObject` - Photo storage
  - `cognito-idp:AdminGetUser` - User verification

## Data Flow

### 1. User Authentication Flow
```
Mobile App → API Gateway → Cognito
          ← JWT Token ←
```

### 2. Vacation Creation Flow
```
Mobile App → API Gateway (with JWT) → Lambda → RDS
          ←    Success Response     ←
```

### 3. Photo Upload Flow
```
Mobile App → API Gateway (with JWT) → Lambda → S3 (via endpoint)
                                            → RDS (metadata)
          ←    Photo URL Response    ←
```

### 4. Database Query Flow
```
Lambda → Secrets Manager (via endpoint) [Get credentials]
       → RDS (private subnets) [Query data]
       ← Results ←
```

## Cost Analysis

### Monthly Cost Breakdown (Assuming moderate usage)

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| RDS PostgreSQL | db.t3.micro, 20GB | FREE (first 12 months) / $12-15 after |
| Lambda | 1M requests, 512MB, 30s avg | FREE |
| API Gateway | 1M API calls | FREE (first 12 months) / $1 after |
| Secrets Manager | 1 secret | $0.40 |
| VPC Endpoint (Secrets) | Interface endpoint | $7.20 |
| VPC Endpoint (S3) | Gateway endpoint | FREE |
| S3 | 5GB storage, 10K requests | FREE |
| Cognito | 10K MAUs | FREE |
| **Total (first 12 months)** | | **~$8/month** |
| **Total (after free tier)** | | **~$26/month** |

### Cost Optimization Tips

1. **No NAT Gateway** - Saves ~$32/month by using VPC endpoints
2. **db.t3.micro** - Smallest RDS instance for low traffic
3. **Gateway endpoint for S3** - Free data transfer
4. **Lambda in VPC** - Only when needed (can run some outside VPC)
5. **CloudWatch Logs** - 7-day retention to minimize storage

## Comparison: NAT Gateway vs VPC Endpoints

| Approach | Monthly Cost | Pros | Cons |
|----------|--------------|------|------|
| **NAT Gateway** | ~$32 + data transfer | Full internet access | Expensive, single point of failure |
| **VPC Endpoints** | ~$7-8 | Cost-effective, secure | Limited to specific AWS services |

**Recommendation**: VPC Endpoints for this use case since Lambda only needs AWS services (Secrets Manager, S3, Cognito).

## Deployment Prerequisites

### Required AWS Resources

1. **Existing VPC** with:
   - At least 2 private subnets in different AZs
   - DNS support enabled
   - DNS hostnames enabled

2. **Subnet Requirements**:
   - Private subnets for RDS and Lambda
   - Route tables configured (no NAT Gateway needed with VPC endpoints)

3. **AWS CLI** configured with credentials

4. **Terraform** >= 1.0 installed

### Configuration Steps

1. Get your subnet IDs:
```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-06afc2c5552066ee1" \
  --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]" \
  --output table
```

2. Create `terraform.tfvars`:
```hcl
vpc_id = "vpc-06afc2c5552066ee1"
private_subnet_ids = ["subnet-xxx", "subnet-yyy"]
```

3. Deploy:
```bash
terraform init
terraform plan
terraform apply
```

## Monitoring and Logging

### CloudWatch Logs

- `/aws/lambda/vacaagent-api` - Lambda function logs
- `/aws/apigateway/vacaagent` - API Gateway access logs

### Metrics to Monitor

- Lambda duration, errors, throttles
- API Gateway 4XX and 5XX errors
- RDS CPU and connection count
- VPC endpoint data processed

### Alarms (Recommended)

1. Lambda errors > 5% of invocations
2. API Gateway 5XX errors > 1% of requests
3. RDS CPU > 80%
4. RDS storage < 20% free

## Disaster Recovery

### Backup Strategy

1. **RDS**: Automatic backups (7-day retention)
2. **S3**: Versioning enabled for photos
3. **Database Schema**: Stored in Git (migrations)
4. **Infrastructure**: Terraform state in version control

### Recovery Time Objective (RTO)

- Infrastructure recreation: ~15 minutes (Terraform)
- Database restore: ~10 minutes (RDS snapshot)
- **Total RTO**: ~30 minutes

### Recovery Point Objective (RPO)

- RDS: 5-minute automated backups
- S3: Point-in-time with versioning

## Scaling Considerations

### Current Limits

- Lambda: 1,000 concurrent executions (can be increased)
- API Gateway: 10,000 requests per second (soft limit)
- RDS: db.t3.micro (2 vCPU, 1GB RAM)

### Scaling Path

1. **Phase 1** (0-1K users): Current setup
2. **Phase 2** (1K-10K users):
   - RDS: Scale to db.t3.small
   - Lambda: Increase memory to 1024MB
3. **Phase 3** (10K+ users):
   - RDS: Scale to db.r5.large with read replicas
   - Lambda: Provisioned concurrency
   - Add caching layer (ElastiCache)

## Security Best Practices

✅ **Implemented**:
- Lambda in private subnets
- RDS not publicly accessible
- Secrets Manager for credentials
- JWT authentication on API Gateway
- Security group least-privilege rules
- S3 bucket encryption
- VPC endpoints for service access

🔄 **Recommended for Production**:
- Enable RDS deletion protection
- Enable RDS encryption at rest
- Configure AWS WAF for API Gateway
- Enable CloudTrail for audit logging
- Set up GuardDuty for threat detection
- Implement AWS Config for compliance
- Use KMS for encryption key management
- Enable MFA on Cognito

## Troubleshooting

### Lambda can't connect to RDS

**Check**:
1. Lambda is in correct subnets
2. Security group allows Lambda → RDS on port 5432
3. RDS is in same VPC
4. Secrets Manager credentials are correct

### Lambda can't access Secrets Manager

**Check**:
1. VPC endpoint for Secrets Manager exists
2. Security group allows Lambda → Endpoint on port 443
3. IAM role has `secretsmanager:GetSecretValue` permission
4. Private DNS enabled on VPC endpoint

### API Gateway returns 502

**Check**:
1. Lambda function has proper permissions
2. Lambda function isn't timing out (increase timeout)
3. Check CloudWatch logs for Lambda errors
4. Verify Lambda handler name is correct

## References

- [AWS Lambda in VPC Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/vpc.html)
- [VPC Endpoints Pricing](https://aws.amazon.com/privatelink/pricing/)
- [RDS Free Tier](https://aws.amazon.com/rds/free/)
- [API Gateway HTTP APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
