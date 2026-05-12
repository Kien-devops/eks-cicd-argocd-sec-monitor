# Kubernetes Manifests

![Kubernetes](https://img.shields.io/badge/Kubernetes-Manifests-326CE5?logo=kubernetes&logoColor=white)
![Kustomize](https://img.shields.io/badge/Kustomize-Base-326CE5?logo=kubernetes&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-GitOps-EF7B4D?logo=argo&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Images-2496ED?logo=docker&logoColor=white)
![NetworkPolicy](https://img.shields.io/badge/NetworkPolicy-Zero%20Trust-326CE5?logo=kubernetes&logoColor=white)

This folder contains the Kubernetes runtime manifests deployed by Argo CD.

## Architecture

```mermaid
flowchart TB
  argocd[Argo CD] --> kustomize[kustomize build k8s/base]
  kustomize --> ns[hospital namespace]
  ns --> fe[Frontend Deployment]
  ns --> be[Backend Deployment]
  fe --> fesvc[Frontend Service]
  be --> besvc[Backend Service]
  be --> secret[be-db-secret]
  ns --> np[Network Policies]
  ingress[Traefik/Gateway] --> fesvc
  ingress --> besvc
```

## Deployment Workflow

```mermaid
sequenceDiagram
  participant Git
  participant Argo as Argo CD
  participant K8s as Kubernetes API
  participant Pods as Hospital Pods

  Git->>Argo: manifests changed
  Argo->>Argo: render kustomize base
  Argo->>K8s: apply desired resources
  K8s->>Pods: rollout deployments
  Argo->>K8s: prune/self-heal drift when enabled
```

## Structure

```text
k8s/
  base/
    namespace.yaml
    kustomization.yaml
    05-fe-deployment.yaml
    06-fe-service.yaml
    07-be-deployment.yaml
    08-be-service.yaml
    10-network-policy.yaml
```

## Apply Manually

```bash
kubectl apply -k k8s/base
```

## Required Secrets

Create these before deploying the backend:

```bash
kubectl -n hospital create secret generic be-db-secret \
  --from-literal=default-connection='Server=<host>;Database=<db>;User Id=<user>;Password=<password>;TrustServerCertificate=True'
```

If images are private in ECR, create an image pull secret or configure worker node IAM/ECR access:

```bash
kubectl -n hospital create secret docker-registry ecr-registry-secret \
  --docker-server=<account-id>.dkr.ecr.<region>.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region <region>)"
```

## Verify

```bash
kubectl get pods,svc -n hospital
kubectl describe deploy be-deployment-v1 -n hospital
kubectl describe deploy fe-deployment-v1 -n hospital
```
