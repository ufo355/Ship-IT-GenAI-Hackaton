module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"
  version = "4.0.0"

  name          = "hackaton-rag-api-gateway"
  protocol_type = "HTTP"

  create_api_domain_name                = false
  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }


  integrations = {
    "POST /" = {
      lambda_arn             = aws_lambda_function.lex-integration-lambda.arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 30000
      authorization_type = "CUSTOM"
      authorizer_key     = "jwt"
    }
  }

  authorizers = {
    "jwt" = {
      name                                = "jwt-authorizer"
      authorizer_type                     = "REQUEST"
      authorizer_uri                      = aws_lambda_function.lambda-authorizer.invoke_arn
      authorizer_payload_format_version   = "2.0"
      identity_sources                    = ["$request.querystring.token"]
      enable_simple_responses             = true
    }
  }

  tags = {
    Name = "http-apigateway"
  }
}