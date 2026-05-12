# Production Environment

This environment creates a more resilient EKS stack for production.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform plan -out tfplan
terraform apply tfplan
aws eks update-kubeconfig --region us-east-1 --name hospital-prod-eks
```

## Production Checklist

- Replace `public_access_cidrs` with office or VPN IP ranges.
- Replace the backend bucket and DynamoDB lock table names in `backend.hcl`.
- Review node sizes and desired capacity.
- Review AWS service quotas before applying.
- Keep `single_nat_gateway = false` for AZ-level resilience.
