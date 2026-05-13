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
- Keeps the Kubernetes API private by default.
- If public API access is required temporarily, enable `endpoint_public_access` and set `public_access_cidrs` to your public IP as `/32`.
