variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs used by the cluster and node groups."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Enable public access to the Kubernetes API endpoint."
  type        = bool
  default     = false
}

variable "endpoint_private_access" {
  description = "Enable private access to the Kubernetes API endpoint."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the public Kubernetes API endpoint."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "node_groups" {
  description = "Managed node group configuration."
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    min_size       = number
    desired_size   = number
    max_size       = number
    disk_size      = number
    labels         = map(string)
  }))
}

variable "cluster_addons" {
  description = "EKS managed addons to install."
  type        = list(string)
  default = [
    "vpc-cni",
    "coredns",
    "kube-proxy",
    "eks-pod-identity-agent",
    "aws-ebs-csi-driver"
  ]
}

variable "oidc_thumbprint_list" {
  description = "Thumbprints for the EKS OIDC provider root CA."
  type        = list(string)
  default     = ["9e99a48a9960b14926bb7f3b02e22da0ecd4e"]
}

variable "enable_secrets_encryption" {
  description = "Encrypt Kubernetes secrets with a customer-managed KMS key."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
