terraform {
  backend "s3" {
    bucket         = "visioncomp-terraform-state"
    key            = "vacaagentinfra/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "visioncomp-terraform-locks"
    encrypt        = true
  }
}
