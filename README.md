# Hospital EKS CI/CD GitOps Platform

![AWS EKS](https://img.shields.io/badge/AWS%20EKS-Kubernetes-FF9900?logo=amazoneks&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-GitOps-EF7B4D?logo=argo&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white)
![SonarQube](https://img.shields.io/badge/SonarQube-Code%20Quality-4E9BCD?logo=sonarqube&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-Security%20Scan-1904DA?logo=aqua&logoColor=white)
![Nexus](https://img.shields.io/badge/Nexus-Artifacts-1B1C30?logo=sonatype&logoColor=white)
![.NET](https://img.shields.io/badge/.NET%209-API-512BD4?logo=dotnet&logoColor=white)
![React](https://img.shields.io/badge/React-Vite-61DAFB?logo=react&logoColor=black)

This repository contains a hospital management application and the infrastructure files needed to run it on AWS EKS with a production-style DevOps layout.

## Project Structure

```text
.
  hospital_FE/             # React/Vite frontend
  hospital_BE/             # ASP.NET Core backend API
  k8s/                     # Kubernetes manifests and kustomize base
  argocd/                  # Argo CD application and setup notes
  .github/workflows/       # GitHub Actions workflows and CI/CD setup guide
  terraform/               # AWS EKS infrastructure as code
  security/                # SonarQube, Nexus, and Trivy setup
  docker-compose.yml       # Local app build/run helper
  hospital_db.sql          # Database bootstrap script
  DIAGRAM.drawio           # Architecture diagram source
```

## Architecture

```mermaid
flowchart TB
  dev[Developer] --> git[Git repository]
  git --> gha[GitHub Actions]
  gha --> build[Build FE/BE]
  build --> sonar[SonarQube Quality Gate]
  build --> trivy[Trivy Security Gate]
  build --> registry[Container Registry]
  terraform[Terraform] --> eks[AWS EKS]
  git --> argocd[Argo CD]
  argocd --> eks
  eks --> fe[Frontend Pods]
  eks --> be[Backend API Pods]
  be --> db[(Database)]
  gha --> nexus[Nexus Artifacts]
```

## Delivery Workflow

```mermaid
sequenceDiagram
  participant Dev
  participant GH as GitHub Actions
  participant Sec as SonarQube/Trivy
  participant Reg as Registry/Nexus
  participant Argo as Argo CD
  participant EKS as AWS EKS

  Dev->>GH: push / pull request
  GH->>GH: build backend and frontend
  GH->>Sec: run quality and security gates
  Sec-->>GH: pass/fail result
  GH->>Reg: publish artifact or image
  Argo->>EKS: sync Kubernetes manifests from Git
```

## Main Components

| Area | Path | Purpose |
|---|---|---|
| Frontend | `hospital_FE/` | React/Vite web application served by nginx container. |
| Backend | `hospital_BE/Hospital_API/` | ASP.NET Core API for hospital workflows. |
| Kubernetes | `k8s/base/` | Deployments, services, namespace, and network policies. |
| GitOps | `argocd/` | Argo CD `Application` that syncs Kubernetes manifests. |
| CI/CD | `.github/workflows/` | GitHub Actions build, scan, image, and GitOps pipeline. |
| Infrastructure | `terraform/` | Modular AWS EKS and VPC provisioning. |
| Security Tooling | `security/` | SonarQube, Nexus, and Trivy setup with secure defaults. |

## Local Development

Run both application containers locally:

```bash
docker compose up --build
```

Default local ports:

| Service | URL |
|---|---|
| Frontend | `http://localhost:5173` |
| Backend | `http://localhost:5247` |

## Infrastructure Setup

Install prerequisites:

- AWS CLI v2
- Terraform `>= 1.6`
- kubectl
- Docker

Configure AWS credentials:

```bash
aws configure
```

Deploy dev infrastructure:

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan -out tfplan
terraform apply tfplan
aws eks update-kubeconfig --region us-east-1 --name hospital-dev-eks
```

For production, use `terraform/environments/prod` and restrict `public_access_cidrs` before applying.

## Kubernetes Deployment

Create required runtime secrets:

```bash
kubectl -n hospital create secret generic be-db-secret \
  --from-literal=default-connection='Server=<host>;Database=<db>;User Id=<user>;Password=<password>;TrustServerCertificate=True'
```

Apply manually:

```bash
kubectl apply -k k8s/base
```

Or let Argo CD sync from `argocd/hospital-traefik-app.yaml`.

## Argo CD

Apply the Argo CD application:

```bash
kubectl apply -f argocd/hospital-traefik-app.yaml
```

Check sync:

```bash
kubectl -n argocd get applications
kubectl get pods,svc -n hospital
```

More details are in `argocd/README.md` and `argocd/SETUP.md`.

## DevSecOps Security Stack

The `security/` folder contains setup for the supporting security servers:

| Tool | Default local URL | Purpose |
|---|---|---|
| SonarQube | `http://127.0.0.1:9000` | Static code analysis and quality gate. |
| Nexus | `http://127.0.0.1:8081` | Private artifact and dependency repository. |
| Trivy | CLI | Vulnerability, secret, IaC, and misconfiguration scanning. |

Start SonarQube and Nexus:

```bash
cd security
docker compose up -d
```

Recommended pipeline gate:

```text
Build -> Test -> SonarQube -> Trivy -> Publish Artifact/Image -> Argo CD Deploy
```

For public access, put these services behind HTTPS and restrict inbound traffic to trusted IPs or CI servers.

## Production Notes

- Keep application workloads in private subnets.
- Restrict EKS API public access to trusted IPs.
- Store database passwords and tokens outside Git.
- Keep SonarQube/Nexus admin passwords and tokens in CI secrets only.
- Use immutable image tags in release pipelines.
- Review Terraform plans before applying to production.
- Prefer GitOps changes through Git instead of manual `kubectl edit`.

## Documentation Index

- `terraform/README.md`: infrastructure workflow and module layout
- `terraform/environments/dev/README.md`: dev environment setup
- `terraform/environments/prod/README.md`: production environment setup
- `k8s/README.md`: Kubernetes manifests and secrets
- `argocd/README.md`: GitOps deployment
- `.github/workflows/README.md`: GitHub Actions CI/CD and self-hosted runner setup
- `security/README.md`: DevSecOps security stack overview
- `security/sonarqube/README.md`: SonarQube token, webhook, and scanner setup
- `security/nexus/README.md`: Nexus repositories and credential handling
- `security/trivy/README.md`: vulnerability and IaC scanning
- `hospital_FE/README.md`: frontend notes
- `hospital_BE/README.md`: backend notes
