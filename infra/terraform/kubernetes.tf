resource "kubernetes_namespace" "banking" {
  count = var.enable_platform ? 1 : 0

  metadata {
    name = var.banking_namespace

    labels = {
      "app.kubernetes.io/name"       = "techbleat-bank"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [module.eks]
}

resource "kubernetes_manifest" "aws_secretsmanager_store" {
  count = var.enable_platform ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secretsmanager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = var.external_secrets_namespace
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.external_secrets]
}

resource "kubernetes_manifest" "banking_app_secret" {
  count = var.enable_platform ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "banking-app-secret"
      namespace = kubernetes_namespace.banking[0].metadata[0].name
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = kubernetes_manifest.aws_secretsmanager_store[0].manifest.metadata.name
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "banking-app-secret"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "POSTGRES_PASSWORD"
          remoteRef = {
            key      = var.banking_secret_name
            property = "POSTGRES_PASSWORD"
          }
        },
        {
          secretKey = "DATABASE_URL"
          remoteRef = {
            key      = var.banking_secret_name
            property = "DATABASE_URL"
          }
        },
        {
          secretKey = "SPRING_DATASOURCE_PASSWORD"
          remoteRef = {
            key      = var.banking_secret_name
            property = "SPRING_DATASOURCE_PASSWORD"
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.aws_secretsmanager_store,
    kubernetes_namespace.banking
  ]
}
