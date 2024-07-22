resource "aws_iam_role" "role_for_lex" {
  name = local.lex_role_name
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lexv2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonLexFullAccess",
	  "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
  ]
}

resource "aws_iam_role" "role_for_lambda_lex" {
  name = local.lambda_lex_role_name
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
	  "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
  ]
}

resource "aws_lambda_permission" "resource_based_policy_for_lex" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lex_lambda.function_name
  principal     = "lexv2.amazonaws.com"
  source_arn    = "arn:aws:lex:eu-central-1:471112839437:bot-alias/UWFWVG2XNE/TSTALIASID"
}