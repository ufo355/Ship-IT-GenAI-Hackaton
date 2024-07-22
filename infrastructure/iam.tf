resource "aws_iam_role" "lex-integration-lambda-role" {
  name               = "lex-integration-lambda-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "authorization-lambda-role" {
  name               = "lambda-authorizer-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attach" {
  role       = aws_iam_role.lex-integration-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonLexRunBotsOnly"
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lex-integration-lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = ""
}

resource "aws_iam_role_policy_attachment" "SecretsManagerReadWrite_iam_attach" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.authorization-lambda-role.name
}

resource "aws_lambda_permission" "allow_api_gateway_for_jwt_lambda" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-authorizer.function_name
  principal     = "apigateway.amazonaws.com"
}