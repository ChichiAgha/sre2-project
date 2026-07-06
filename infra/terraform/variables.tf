variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "eu-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "techbleat-capstone"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.34"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "banking_namespace" {
  description = "Application namespace."
  type        = string
  default     = "banking"
}

variable "external_secrets_namespace" {
  description = "Namespace for External Secrets Operator."
  type        = string
  default     = "external-secrets"
}

variable "banking_secret_name" {
  description = "AWS Secrets Manager secret name for the banking app."
  type        = string
  default     = "techbleat/banking/app"
}

variable "banking_secret_values" {
  description = "Secret values stored in AWS Secrets Manager."
  type = object({
    POSTGRES_PASSWORD          = string
    DATABASE_URL               = string
    SPRING_DATASOURCE_PASSWORD = string
  })
  sensitive = true
}

variable "enable_platform" {
  description = "Enable Kubernetes platform resources after the EKS cluster exists."
  type        = bool
  default     = false
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum EKS node group size."
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "Desired EKS node group size. Three nodes provide enough pod capacity for the app plus observability stack."
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum EKS node group size."
  type        = number
  default     = 4
}

variable "github_owner" {
  description = "GitHub account or organisation that owns the capstone repository."
  type        = string
  default     = "ChichiAgha"
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the CI/CD IAM role."
  type        = string
  default     = "sre2-project"
}

variable "github_actions_role_name" {
  description = "IAM role name used by GitHub Actions OIDC to push scanned images to Public ECR."
  type        = string
  default     = "techbleat-github-actions-ecr"
}
