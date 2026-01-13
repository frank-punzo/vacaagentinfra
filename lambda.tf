# Lambda Layer for Python dependencies
resource "aws_lambda_layer_version" "dependencies" {
  filename            = "lambda_layer.zip"
  layer_name          = "${var.project_name}-dependencies"
  compatible_runtimes = [var.lambda_runtime]
  description         = "Python dependencies for VacaAgent Lambda functions"

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda functions will be created for each API endpoint
# This is a template for the main API handler

# Main API Lambda Function
resource "aws_lambda_function" "api" {
  filename         = "lambda_function.zip"
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.lambda.arn
  handler          = "index.lambda_handler"
  source_code_hash = fileexists("lambda_function.zip") ? filebase64sha256("lambda_function.zip") : ""
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  layers = [aws_lambda_layer_version.dependencies.arn]

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN     = aws_secretsmanager_secret.db_password.arn
      PHOTOS_BUCKET     = aws_s3_bucket.photos.id
      USER_POOL_ID      = aws_cognito_user_pool.main.id
      USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.main.id
      ENVIRONMENT       = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-api-lambda"
  }

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_api" {
  name              = "/aws/lambda/${aws_lambda_function.api.function_name}"
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
