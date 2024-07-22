resource "aws_security_group" "lambda_sg" {
  vpc_id      = local.vpc_id
  name        = "rag-lambda-sg"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_lambda_function" "hackaton_rag_upload" {
  function_name = "rag-upload-lambda"
  role          = aws_iam_role.rag_lambda_role.arn
  timeout       = 900
  image_uri     = ""
  package_type  = "Image"
  memory_size   = 256

  vpc_config {
    subnet_ids         = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment {
    variables = {
      "DATABASE"            = "vectors"
      "DATABASE_USER"       = "postgres"
      "DATABASE_PORT"       = "5432"
      "RDS_PROXY_ENDPOINT"  = aws_db_instance.db_instance.address
      "REGION"              = var.aws_region
      "COLLECTION_NAME"     = "animal-shelter"
      "SECRET_NAME"         = aws_secretsmanager_secret.rds-secret-manager.name
      "BUCKET_NAME"         = "hackaton-data-animal-shelter"
    }
  }
}

resource "aws_lambda_function" "hackaton_rag_query" {
  function_name = "rag-query-lambda"
  role          = aws_iam_role.rag_lambda_role.arn
  timeout       = 180
  image_uri     = ""
  package_type  = "Image"

  vpc_config {
    subnet_ids         = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      "DATABASE"            = "vectors"
      "DATABASE_USER"       = "postgres"
      "DATABASE_PORT"       = "5432"
      "RDS_PROXY_ENDPOINT"  = aws_db_instance.db_instance.address
      "REGION"              = var.aws_region
      "COLLECTION_NAME"     = "animal-shelter"
      "SECRET_NAME"         = aws_secretsmanager_secret.rds-secret-manager.name
      "BUCKET_NAME"         = "hackaton-data-animal-shelter"
    }
  }
}

