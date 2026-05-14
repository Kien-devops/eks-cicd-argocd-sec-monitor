# Terraform Infrastructure

![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-232F3E?logo=amazonaws&logoColor=white)
![Amazon EKS](https://img.shields.io/badge/Amazon%20EKS-Kubernetes-FF9900?logo=amazoneks&logoColor=white)
![VPC](https://img.shields.io/badge/AWS%20VPC-Networking-FF9900?logo=amazonaws&logoColor=white)
![KMS](https://img.shields.io/badge/AWS%20KMS-Secrets%20Encryption-FF9900?logo=amazonaws&logoColor=white)
![IAM](https://img.shields.io/badge/AWS%20IAM-Least%20Privilege-FF9900?logo=amazonaws&logoColor=white)

This folder provisions AWS infrastructure for the hospital platform.

## Learning Map

| Topic | What to study here |
|---|---|
| Environment separation | `terraform/environments/dev` and `terraform/environments/prod`. |
| Module design | Shared `network` and `eks` modules. |
| EKS foundation | Cluster, managed node groups, addons, IAM roles, and KMS secret encryption. |
| Network foundation | VPC, public/private subnets, route tables, and NAT gateway strategy. |
| Cost tradeoff | Dev uses a single NAT gateway; prod can use one NAT gateway per AZ. |

## Architecture

```mermaid
flowchart TB
  user[Operator] --> tf[Terraform CLI]
  tf --> state[(Local terraform.tfstate)]
  tf --> vpc[AWS VPC]
  vpc --> public[Public subnets]
  vpc --> private[Private subnets]
  public --> nat[NAT Gateway]
  private --> eks[EKS cluster]
  eks --> ng[Managed node group]
  eks --> addons[EKS addons]
  eks --> kms[KMS secret encryption]
```

## Provisioning Workflow

```mermaid
sequenceDiagram
  participant Op as Operator
  participant TF as Terraform
  participant AWS as AWS APIs
  participant EKS as EKS

  Op->>TF: terraform init
  Op->>TF: plan
  TF->>AWS: compare desired and current resources
  Op->>TF: apply
  TF->>AWS: create VPC, IAM, KMS
  TF->>EKS: create cluster, node groups, addons
  TF-->>Op: outputs cluster name and endpoint
```

## Structure

```text
terraform/
  environments/
    dev/                 # Development stack
    prod/                # Production stack
  modules/
    network/             # VPC, subnets, NAT, routes
    eks/                 # EKS cluster, node groups, addons
```

## Prerequisites

- Terraform `>= 1.6`
- AWS CLI v2
- kubectl
- AWS credentials configured with permission to create VPC, EKS, IAM, and KMS resources

## Deploy Dev

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
aws eks update-kubeconfig --region us-east-1 --name hospital-dev-eks
```

## Deploy Prod

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
aws eks update-kubeconfig --region us-east-1 --name hospital-prod-eks
```

## Destroy

Destroy only after removing application load balancers and persistent volumes from the cluster:

```bash
terraform destroy
```

## Notes

- Dev uses one NAT gateway by default to reduce cost.
- Prod uses one NAT gateway per AZ by default.
- Terraform uses local state by default in this lab setup.
- Keep the EKS API endpoint private by default. If public endpoint access is required, restrict `public_access_cidrs` to approved public IP ranges.
- Terraform does not create ECR repositories. Use an existing registry or create repositories from your CI/CD bootstrap process.
- Terraform does not store application secrets; create Kubernetes secrets separately or with an external secret manager.
