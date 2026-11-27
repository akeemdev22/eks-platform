variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "cluster_name" {
  description = "Name used for the EKS cluster and its network"
  type        = string
  default     = "eks-platform"
}