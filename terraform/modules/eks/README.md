# EKS Module

Creates the EKS control plane and managed node groups.

Included:

- EKS cluster IAM role
- Managed node IAM role
- optional KMS secret encryption
- OIDC provider for IAM roles for service accounts
- control plane log types enabled
- managed node groups in private subnets
- core EKS addons
- dedicated IAM role for the AWS EBS CSI driver addon

Recommended production settings:

- keep `endpoint_private_access = true`
- keep `endpoint_public_access = false` unless operators connect through approved public IP ranges
- restrict `public_access_cidrs` to `/32` office, VPN, or bastion IPs when public access is enabled
- use at least two AZs
- use more than one node in the default node group
- keep control plane logging enabled
