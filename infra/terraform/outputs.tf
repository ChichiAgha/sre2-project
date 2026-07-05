output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "banking_secret_arn" {
  description = "AWS Secrets Manager ARN for the banking app secret."
  value       = aws_secretsmanager_secret.banking_app.arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN assumed by External Secrets Operator."
  value       = aws_iam_role.external_secrets.arn
}
