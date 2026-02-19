# HTTP API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "VacaAgent REST API"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
    allow_headers = ["*"]
    expose_headers = ["*"]
    max_age       = 300
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

# API Gateway Authorizer (Cognito)
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.main.id]
    issuer   = "https://${aws_cognito_user_pool.main.endpoint}"
  }
}

# API Gateway Integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "Lambda integration"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.api.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

# API Gateway Routes
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Health check route (no auth required)
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Vacation routes with JWT authorization
resource "aws_apigatewayv2_route" "get_vacations" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "post_vacations" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /vacations"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "get_vacation_id" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "put_vacation_id" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /vacations/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "delete_vacation_id" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "DELETE /vacations/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# OPTIONS routes for CORS preflight (no auth required)
resource "aws_apigatewayv2_route" "options_vacations" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /vacations"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "options_vacations_id" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /vacations/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"
}

# Event routes
resource "aws_apigatewayv2_route" "get_events" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{vacation_id}/events"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "post_events" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /vacations/{vacation_id}/events"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "put_event" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /vacations/{vacation_id}/events/{event_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "delete_event" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "DELETE /vacations/{vacation_id}/events/{event_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "get_event_attendees" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{vacation_id}/events/{event_id}/attendees"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "put_event_attendees" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /vacations/{vacation_id}/events/{event_id}/attendees"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Excursion routes
resource "aws_apigatewayv2_route" "get_excursions" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{vacation_id}/excursions"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "post_excursions" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /vacations/{vacation_id}/excursions"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "put_excursion" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /vacations/{vacation_id}/excursions/{excursion_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "delete_excursion" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "DELETE /vacations/{vacation_id}/excursions/{excursion_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "get_excursion_attendees" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{vacation_id}/excursions/{excursion_id}/attendees"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "put_excursion_attendees" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /vacations/{vacation_id}/excursions/{excursion_id}/attendees"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Photo routes
resource "aws_apigatewayv2_route" "get_photos" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{vacation_id}/photos"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "post_photos" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /vacations/{vacation_id}/photos"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "post_photos_upload_url" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /vacations/{vacation_id}/photos/upload-url"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "put_photo" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /vacations/{vacation_id}/photos/{photo_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "delete_photo" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "DELETE /vacations/{vacation_id}/photos/{photo_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Packing list routes
resource "aws_apigatewayv2_route" "get_packing" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{vacation_id}/packing"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "post_packing" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /vacations/{vacation_id}/packing"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "put_packing_item" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "PUT /vacations/{vacation_id}/packing/{item_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "delete_packing_item" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "DELETE /vacations/{vacation_id}/packing/{item_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Member routes
resource "aws_apigatewayv2_route" "get_members" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{vacation_id}/members"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "delete_member" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "DELETE /vacations/{vacation_id}/members/{member_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Invite routes
resource "aws_apigatewayv2_route" "get_invites" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{vacation_id}/invites"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "post_invites" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /vacations/{vacation_id}/invites"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "delete_invite" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "DELETE /vacations/{vacation_id}/invites/{invite_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Join vacation route
resource "aws_apigatewayv2_route" "post_join" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /join"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Recommendations route
resource "aws_apigatewayv2_route" "get_recommendations" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{vacation_id}/recommendations"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# Saved tips routes
resource "aws_apigatewayv2_route" "get_saved_tips" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "GET /vacations/{vacation_id}/saved-tips"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "post_saved_tips" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /vacations/{vacation_id}/saved-tips"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "delete_saved_tip" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "DELETE /vacations/{vacation_id}/saved-tips/{tip_id}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-stage"
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-api-gateway-logs"
  }
}
