resource "aws_secretsmanager_secret" "banking_app" {
  name        = var.banking_secret_name
  description = "Runtime secrets for TechBleat Global Bank."

  tags = {
    Project     = "techbleat-bank"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "banking_app" {
  secret_id     = aws_secretsmanager_secret.banking_app.id
  secret_string = jsonencode(var.banking_secret_values)
}
