# The vault entry for the Slack webhook. Terraform creates the empty
# secret, and the value is added separately so it never appears in code
# or in Terraform state.
resource "aws_secretsmanager_secret" "slack_webhook" {
  name                    = "${var.cluster_name}/slack-webhook"
  recovery_window_in_days = 0
}

# Who can use the role: only pods, through EKS Pod Identity
data "aws_iam_policy_document" "external_secrets_assume" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume.json
}

# What the role can do: read this one secret, nothing else
data "aws_iam_policy_document" "external_secrets_read" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_secretsmanager_secret.slack_webhook.arn]
  }
}

resource "aws_iam_role_policy" "external_secrets_read" {
  name   = "read-slack-webhook"
  role   = aws_iam_role.external_secrets.id
  policy = data.aws_iam_policy_document.external_secrets_read.json
}

# Link the role to the External Secrets service account in the cluster
resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.external_secrets.arn
}