variable "project_name" {
  description = "Project name used in resource names."
  type        = string
  default     = "hospital"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "devops"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.30.0.0/16"
}

variable "azs" {
  description = "Availability zones."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
  default     = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs."
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway. Production default is false."
  type        = bool
  default     = false
}

variable "endpoint_public_access" {
  description = "Enable public EKS API endpoint."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Enable private EKS API endpoint."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint."
  type        = list(string)
  default     = ["203.0.113.10/32"]
}

variable "enable_secrets_encryption" {
  description = "Encrypt Kubernetes secrets with KMS."
  type        = bool
  default     = true
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
  default = {
    system = {
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      desired_size   = 3
      max_size       = 6
      disk_size      = 50
      labels = {
        role = "system"
      }
    }
  }
}

