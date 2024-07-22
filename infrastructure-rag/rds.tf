
resource "aws_security_group" "database_security_group" {
  name        = "vector-database-security-group"
  vpc_id      = local.vpc_id

  ingress {
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


resource "random_string" "random-database-password" {
  length  = 30
  upper   = true
  numeric = true
  special = false
}


resource "aws_db_subnet_group" "vector_database" {
  name       = "vector_database"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]

  tags = {
    Name = "vector_database"
  }
}

resource "aws_db_instance" "db_instance" {
  engine                  = "postgres"
  engine_version          = "16.2"
  db_name                 = "vectors"
  identifier              = "rag-vector-database"
  username                = "postgres"
  password                = random_string.random-database-password.result
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.vector_database.name
  vpc_security_group_ids  = [aws_security_group.database_security_group.id]
}

resource "aws_secretsmanager_secret" "rds-secret-manager" {
  name_prefix = "hackaton/rag/rds/secrets"
}

resource "aws_secretsmanager_secret_version" "rds-secret-manager-keys-values" {
  secret_id     = aws_secretsmanager_secret.rds-secret-manager.id
  secret_string = jsonencode({
    "db_name"  = aws_db_instance.db_instance.db_name
    "username" = aws_db_instance.db_instance.username
    "password" = aws_db_instance.db_instance.password
  })
}