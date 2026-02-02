# Amazon Bedrock Configuration
#
# IMPORTANT: Bedrock model access must be manually enabled in the AWS Console.
# This is an AWS requirement and cannot be automated via Terraform.
#
# Steps to enable Claude 3.5 Haiku:
# 1. Go to AWS Console > Amazon Bedrock
# 2. Navigate to "Model access" in the left sidebar
# 3. Click "Manage model access"
# 4. Find "Anthropic" > "Claude 3.5 Haiku" and request access
# 5. Wait for access to be granted (usually instant for Claude models)
# 6. Set the variable bedrock_model_access_enabled = true
#
# The Lambda function uses Claude 3.5 Haiku for AI-powered vacation recommendations.

variable "bedrock_model_access_enabled" {
  description = "Set to true after manually enabling Bedrock model access in AWS Console"
  type        = bool
  default     = false
}

variable "bedrock_model_id" {
  description = "The Bedrock model ID to use for recommendations"
  type        = string
  default     = "anthropic.claude-3-5-haiku-20241022-v1:0"
}

# This check ensures the user has acknowledged they need to enable Bedrock model access
resource "null_resource" "bedrock_access_check" {
  count = var.bedrock_model_access_enabled ? 0 : 1

  provisioner "local-exec" {
    command = "echo 'WARNING: Bedrock model access has not been enabled. The AI Tips feature will not work until you enable Claude 3.5 Haiku in the AWS Bedrock console and set bedrock_model_access_enabled=true' && exit 0"
  }
}

# Output to remind users about Bedrock setup
output "bedrock_setup_reminder" {
  value = var.bedrock_model_access_enabled ? "Bedrock model access is configured" : "REMINDER: Enable Claude 3.5 Haiku in AWS Bedrock Console and set bedrock_model_access_enabled=true"
}
