resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lex_lambda.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

data "archive_file" "zip_the_lambda_lex" {
  type        = "zip"
  source_file = "${path.module}/lambda_code/index.py"
  output_path = "${path.module}/lambda_code/lambda.zip"
}

resource "aws_lambda_function" "lex_lambda" {
  filename         = "${path.module}/lambda_code/lambda.zip"
  function_name    = local.lambda_lex_name
  role             = aws_iam_role.role_for_lambda_lex.arn
  timeout          = 900
  handler          = "index.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.zip_the_lambda_lex.output_base64sha256
  // vpc_config {
  //   subnet_ids         = []
  //   security_group_ids = []
  // }
  // environment {
  //   variables = {
  //   }
  // }
  depends_on      = [data.archive_file.zip_the_lambda_lex]
}