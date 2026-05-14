# Dev Environment

![Terraform](https://img.shields.io/badge/Terraform-Dev%20Environment-844FBA?logo=terraform&logoColor=white)
![AWS EKS](https://img.shields.io/badge/AWS%20EKS-Dev%20Cluster-FF9900?logo=amazoneks&logoColor=white)
![Cost Optimized](https://img.shields.io/badge/Cost-Single%20NAT%20Gateway-16A34A)
![Private API](https://img.shields.io/badge/API%20Endpoint-Private%20First-111827)

This environment creates a cost-conscious EKS stack for development.

## Learning Focus

| Topic | Dev choice |
|---|---|
| Cost control | Uses one NAT gateway by default. |
| Secure default | Keeps the EKS API private unless explicitly opened. |
| Experimentation | Small node counts and dev-friendly defaults. |

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
