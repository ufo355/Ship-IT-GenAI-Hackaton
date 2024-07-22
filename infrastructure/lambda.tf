resource "aws_lambda_function" "lex-integration-lambda" {
  filename      = "${path.module}/lambda_code/lex_integration_lambda/lambda_function.zip"
  function_name = "lex-integration-lambda"
  role          = aws_iam_role.lex-integration-lambda-role.arn
  timeout       = 30
  handler       = "index.lambda_handler"
  runtime       = "python3.10"
  memory_size   = 256

  source_code_hash = filebase64sha256("${path.module}/lambda_code/lex_integration_lambda/lambda_function.zip")
#   vpc_config {
#     subnet_ids         = [var.subnet1, var.subnet2]
#     security_group_ids = [aws_security_group.np-cyt-dna-chatbot-rag-lambda-sg.id]
#   }
  environment {
    variables = {
      "LOCALE_ID"    = "pl_PL"
      "BOT_ALIAS_ID" = "TSTALIASID"
      "BOT_ID"       = "UWFWVG2XNE"
    }
  }
}

data "archive_file" "zip_the_lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code/lex_integration_lambda/"
  output_path = "${path.module}/lambda_code/lex_integration_lambda/lambda_function.zip"
}



resource "aws_lambda_function" "lambda-authorizer" {
    filename      = "${path.module}/lambda_code/authorizer/lambda_function.zip"
    role          = aws_iam_role.authorization-lambda-role.arn
    function_name = "api-gateway-lambda-authorizer"
    handler       = "index.lambda_handler"
    runtime       = "python3.10"
    environment {
        variables = {
                "SECRET_MANAGER" = aws_secretsmanager_secret.jwt_secret.name
        }
    }
    layers        = [aws_lambda_layer_version.lambda_layer_py_jwt.arn]
    source_code_hash = filebase64sha256("${path.module}/lambda_code/authorizer/lambda_function.zip")
}

data "archive_file" "zip_the_lambda_code_auth" {
    type        = "zip"
    source_dir  = "${path.module}/lambda_code/authorizer/"
    output_path = "${path.module}/lambda_code/authorizer/lambda_function.zip"
 }


resource "aws_lambda_layer_version" "lambda_layer_py_jwt" {
  filename   = "${path.module}/lambda_layers/pyjwt_package.zip"
  layer_name = "py_jwt_layer"

  compatible_runtimes = ["python3.10"]
}