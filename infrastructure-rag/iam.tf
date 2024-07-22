resource "aws_iam_role" "rag_lambda_role" {
  name               = "rag-lambda-role"
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

resource "aws_iam_role_policy_attachment" "attach_AmazonEC2FullAccess_to_iam_role" {
  role       = aws_iam_role.rag_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_AWSLambdaBasicExecutionRole_to_iam_role" {
  role       = aws_iam_role.rag_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "SecretsManagerReadWrite_iam_attach" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.rag_lambda_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonS3ReadOnlyAccess_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.rag_lambda_role.name
}


resource "aws_iam_role_policy_attachment" "InvokeBedrock_attach" {
  policy_arn = aws_iam_policy.bedrock.arn
  role       = aws_iam_role.rag_lambda_role.name
}

resource "aws_iam_role_policy_attachment" "Textractpolicy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonTextractFullAccess"
  role       = aws_iam_role.rag_lambda_role.name
}

resource "aws_iam_policy" "bedrock" {
  name        = "Bedrock-policy"
  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Sid": "InvokeModel1",
            "Action": [
                "bedrock:InvokeModel"
            ],
            "Resource": [
                "arn:aws:bedrock:eu-central-1::foundation-model/amazon.titan-text-express-v1",
                "arn:aws:bedrock:eu-central-1::foundation-model/amazon.titan-embed-text-v1",
                "arn:aws:bedrock:eu-central-1::foundation-model/anthropic.claude-v2:1"
            ]
        }
    ]
}
EOT
}