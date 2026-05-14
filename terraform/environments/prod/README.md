# Production Environment

![Terraform](https://img.shields.io/badge/Terraform-Prod%20Environment-844FBA?logo=terraform&logoColor=white)
![AWS EKS](https://img.shields.io/badge/AWS%20EKS-Production%20Cluster-FF9900?logo=amazoneks&logoColor=white)
![High Availability](https://img.shields.io/badge/Availability-Multi%20AZ-16A34A)
![Private API](https://img.shields.io/badge/API%20Endpoint-Private%20First-111827)

This environment creates a more resilient EKS stack for production.

## Learning Focus

| Topic | Production choice |
|---|---|
| Availability | Prefer one NAT gateway per AZ. |
| Secure access | Keep the EKS API private or tightly restricted. |
| Capacity planning | Review node sizes, desired counts, and AWS quotas. |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan -out tfplan
terraform apply tfplan
aws eks update-kubeconfig --region us-east-1 --name hospital-prod-eks
```

## Production Checklist

- Keep `endpoint_private_access = true` and `endpoint_public_access = false` unless operators connect through VPN or a bastion.
- If public API access is required, set `public_access_cidrs` only to office or VPN public IP ranges.
- Review node sizes and desired capacity.
- Review AWS service quotas before applying.
- Keep `single_nat_gateway = false` for AZ-level resilience.
