variable "name" {
  description = "Name prefix used for all network resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones used by public and private subnets."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name, used for Kubernetes load balancer discovery tags."
  type        = string
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for all private subnets. Lower cost for dev, less resilient than one per AZ."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

