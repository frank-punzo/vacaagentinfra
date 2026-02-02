# =============================================================================
# AUTH LAMBDA CONFIGURATION
# =============================================================================
# This Lambda runs OUTSIDE the VPC to call Cognito APIs without needing
# NAT Gateway or VPC endpoints. It handles user registration, login, etc.
# =============================================================================

# Package the Auth Lambda function code
data "archive_file" "auth_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../vacaagent/lambda/auth_src"
  output_path = "${path.module}/auth_lambda_function.zip"
}

# Auth Lambda IAM Role (separate from main Lambda role)
resource "aws_iam_role" "auth_lambda" {
  name_prefix = "${var.project_name}-auth-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-auth-lambda-role"
  }
}

# Basic execution policy for Auth Lambda
resource "aws_iam_role_policy_attachment" "auth_lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.auth_lambda.name
}

# Cognito permissions for Auth Lambda
resource "aws_iam_role_policy" "auth_lambda_cognito" {
  name_prefix = "${var.project_name}-auth-lambda-cognito"
  role        = aws_iam_role.auth_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:SignUp",
          "cognito-idp:ConfirmSignUp",
          "cognito-idp:ResendConfirmationCode",
          "cognito-idp:InitiateAuth",
          "cognito-idp:ForgotPassword",
          "cognito-idp:ConfirmForgotPassword",
          "cognito-idp:ChangePassword",
          "cognito-idp:GlobalSignOut"
        ]
        Resource = aws_cognito_user_pool.main.arn
      }
    ]
  })
}

# Auth Lambda Function (runs OUTSIDE VPC - no vpc_config block)
resource "aws_lambda_function" "auth" {
  filename         = data.archive_file.auth_lambda.output_path
  function_name    = "${var.project_name}-auth"
  role             = aws_iam_role.auth_lambda.arn
  handler          = "auth_lambda.lambda_handler"
  source_code_hash = data.archive_file.auth_lambda.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = 30
  memory_size      = 256

  # NO vpc_config - this Lambda runs outside VPC to access Cognito APIs

  environment {
    variables = {
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID    = aws_cognito_user_pool_client.main.id
      ENVIRONMENT          = var.environment
      LOGLEVEL             = var.lambda_log_level
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.auth_lambda_basic,
    aws_iam_role_policy.auth_lambda_cognito,
    aws_cognito_user_pool.main,
    aws_cognito_user_pool_client.main
  ]

  tags = {
    Name = "${var.project_name}-auth-lambda"
  }
}

# CloudWatch Log Group for Auth Lambda
resource "aws_cloudwatch_log_group" "auth_lambda" {
  name              = "/aws/lambda/${var.project_name}-auth"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-auth-lambda-logs"
  }
}

# Lambda permission for API Gateway to invoke Auth Lambda
resource "aws_lambda_permission" "auth_api_gateway" {
  statement_id  = "AllowAPIGatewayInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# =============================================================================
# API GATEWAY INTEGRATION FOR AUTH LAMBDA
# =============================================================================

resource "aws_apigatewayv2_integration" "auth_lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

# =============================================================================
# AUTH ROUTES (public - no authorization required)
# =============================================================================

resource "aws_apigatewayv2_route" "auth_register" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /auth/register"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "auth_confirm" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /auth/confirm"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "auth_resend_code" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /auth/resend-code"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "auth_login" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /auth/login"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "auth_refresh" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /auth/refresh"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "auth_forgot_password" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /auth/forgot-password"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "auth_confirm_forgot_password" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /auth/confirm-forgot-password"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

# Change password requires authentication (user must be logged in)
resource "aws_apigatewayv2_route" "auth_change_password" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /auth/change-password"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# OPTIONS routes for CORS preflight on auth endpoints
resource "aws_apigatewayv2_route" "options_auth_register" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /auth/register"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "options_auth_confirm" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /auth/confirm"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "options_auth_resend_code" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /auth/resend-code"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "options_auth_login" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /auth/login"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "options_auth_refresh" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /auth/refresh"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "options_auth_forgot_password" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /auth/forgot-password"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "options_auth_confirm_forgot_password" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /auth/confirm-forgot-password"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "options_auth_change_password" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /auth/change-password"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}
