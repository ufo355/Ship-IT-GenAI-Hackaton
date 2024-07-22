resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "hackaton/chatbot/api-gateway/JWT_SECRET"
}

resource "aws_secretsmanager_secret_version" "jwt_secret_version" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
      JWT_SECRET = random_password.jwt_secret.result
    }
  )
}
