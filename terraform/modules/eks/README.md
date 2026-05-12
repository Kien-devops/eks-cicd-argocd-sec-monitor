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
- restrict `public_access_cidrs`
- use at least two AZs
- use more than one node in the default node group
- keep control plane logging enabled
