# Terraform Setup

## 1. Install Tools

```bash
terraform -version
aws --version
kubectl version --client
```

## 2. Configure AWS

```bash
aws configure
aws sts get-caller-identity
```

## 3. Create Remote State

```powershell
./terraform/scripts/bootstrap-backend.ps1 -BucketName hospital-terraform-state-devops -TableName hospital-terraform-locks -Region us-east-1
```

Create an environment `backend.hcl` file from `backend.hcl.example` and set the created bucket and table.

## 4. Deploy Dev

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## 5. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name hospital-dev-eks
kubectl get nodes
```

## 6. Deploy Kubernetes Manifests

```bash
kubectl apply -k ../../../k8s/base
```
