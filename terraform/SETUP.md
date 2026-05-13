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

## 3. Deploy Dev

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## 4. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name hospital-dev-eks
kubectl get nodes
```

## 5. Deploy Kubernetes Manifests

```bash
kubectl apply -k ../../../k8s/overlays/dev
```
