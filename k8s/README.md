# Kubernetes Manifests

![Kubernetes](https://img.shields.io/badge/Kubernetes-Manifests-326CE5?logo=kubernetes&logoColor=white)
![Kustomize](https://img.shields.io/badge/Kustomize-Overlays-326CE5?logo=kubernetes&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-GitOps-EF7B4D?logo=argo&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Images-2496ED?logo=docker&logoColor=white)
![NetworkPolicy](https://img.shields.io/badge/NetworkPolicy-Zero%20Trust-326CE5?logo=kubernetes&logoColor=white)

This folder contains the Kubernetes runtime manifests deployed by Argo CD.

## Architecture

```mermaid
flowchart TB
  argocd[Argo CD] --> kustomize[kustomize build k8s/overlays/env]
  kustomize --> ns[hospital-dev/stag/prod namespace]
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
  Argo->>Argo: render kustomize overlay
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
  overlays/
    dev/
      kustomization.yaml
    stag/
      kustomization.yaml
    prod/
      kustomization.yaml
```

## Environments

| Environment | Path | Namespace | Replicas |
|---|---|---|---|
| dev | `k8s/overlays/dev` | `hospital-dev` | 1 frontend, 1 backend |
| stag | `k8s/overlays/stag` | `hospital-stag` | 2 frontend, 2 backend |
| prod | `k8s/overlays/prod` | `hospital-prod` | 3 frontend, 3 backend |

## Apply Manually

```bash
kubectl apply -k k8s/overlays/dev
kubectl apply -k k8s/overlays/stag
kubectl apply -k k8s/overlays/prod
```

## Required Secrets

Create these before deploying the backend:

```bash
kubectl -n hospital-dev create secret generic be-db-secret \
  --from-literal=default-connection='Server=<host>;Database=<db>;User Id=<user>;Password=<password>;TrustServerCertificate=True'
```

If images are private in ECR, create an image pull secret or configure worker node IAM/ECR access:

```bash
kubectl -n hospital-dev create secret docker-registry ecr-registry-secret \
  --docker-server=<account-id>.dkr.ecr.<region>.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region <region>)"
```

## Verify

```bash
kubectl get pods,svc -n hospital-dev
kubectl describe deploy be-deployment-v1 -n hospital-dev
kubectl describe deploy fe-deployment-v1 -n hospital-dev
```
