# EKS Module

![Terraform Module](https://img.shields.io/badge/Terraform-Module-844FBA?logo=terraform&logoColor=white)
![Amazon EKS](https://img.shields.io/badge/Amazon%20EKS-Control%20Plane-FF9900?logo=amazoneks&logoColor=white)
![IAM](https://img.shields.io/badge/AWS%20IAM-Roles-FF9900?logo=amazonaws&logoColor=white)
![KMS](https://img.shields.io/badge/KMS-Secret%20Encryption-FF9900?logo=amazonaws&logoColor=white)

Creates the EKS control plane and managed node groups.

## Learning Focus

| Topic | What this module teaches |
|---|---|
| EKS control plane | Cluster endpoint, logging, addons, and versioning. |
| Node security | Managed node groups in private subnets. |
| IAM integration | Control plane role, node role, OIDC provider, and addon roles. |
| Secret protection | Optional KMS encryption for Kubernetes secrets. |

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
