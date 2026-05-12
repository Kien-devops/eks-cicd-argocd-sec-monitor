# Dev Environment

This environment creates a cost-conscious EKS stack for development.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan -out tfplan
terraform apply tfplan
aws eks update-kubeconfig --region us-east-1 --name hospital-dev-eks
```

## Notes

- Uses one NAT gateway by default to reduce cost.
- Keeps the public API endpoint open in the example for quick labs.
- Update `public_access_cidrs` before using with real data.
