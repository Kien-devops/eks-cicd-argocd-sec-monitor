# Production Environment

This environment creates a more resilient EKS stack for production.

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
