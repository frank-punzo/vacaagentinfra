# Package the Lambda function code automatically from source
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../vacaagent/lambda/src"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Layer for Python dependencies
resource "aws_lambda_layer_version" "dependencies" {
  count               = fileexists("lambda_layer.zip") ? 1 : 0
  filename            = "lambda_layer.zip"
  layer_name          = "${var.project_name}-dependencies"
  compatible_runtimes = [var.lambda_runtime]
  description         = "Python dependencies for VacaAgent Lambda functions"
  source_code_hash    = filebase64sha256("lambda_layer.zip")

  lifecycle {
    create_before_destroy = true
  }
}

# Main API Lambda Function
resource "aws_lambda_function" "api" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.lambda.arn
  handler          = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  layers = fileexists("lambda_layer.zip") ? [
    aws_lambda_layer_version.dependencies[0].arn
  ] : []

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN       = aws_secretsmanager_secret.db_password.arn
      PHOTOS_BUCKET       = aws_s3_bucket.photos.id
      USER_POOL_ID        = aws_cognito_user_pool.main.id
      USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.main.id
      ENVIRONMENT         = var.environment
      LOGLEVEL            = var.lambda_log_level
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_cognito_user_pool.main,
    aws_cognito_user_pool_client.main
  ]

  tags = {
    Name = "${var.project_name}-api-lambda"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_api" {
  name              = "/aws/lambda/${var.project_name}-api"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-lambda-logs"
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
