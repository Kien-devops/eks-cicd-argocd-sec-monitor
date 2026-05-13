# Hospital EKS DevSecOps GitOps Platform

![AWS EKS](https://img.shields.io/badge/AWS%20EKS-Kubernetes-FF9900?logo=amazoneks&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-GitOps-EF7B4D?logo=argo&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white)
![SonarQube](https://img.shields.io/badge/SonarQube-Code%20Quality-4E9BCD?logo=sonarqube&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-Security%20Gate-1904DA?logo=aqua&logoColor=white)
![Nexus](https://img.shields.io/badge/Nexus-Artifacts-1B1C30?logo=sonatype&logoColor=white)
![Amazon ECR](https://img.shields.io/badge/Amazon%20ECR-Registry-FF9900?logo=amazonecr&logoColor=white)
![.NET](https://img.shields.io/badge/.NET%209-API-512BD4?logo=dotnet&logoColor=white)
![React](https://img.shields.io/badge/React-Vite-61DAFB?logo=react&logoColor=black)

This repository is a complete learning-oriented DevSecOps platform for a hospital management application. It combines a React/Vite frontend, an ASP.NET Core 9 backend, Docker, Nexus Repository, SonarQube, Trivy, Amazon ECR, AWS EKS, Terraform, GitHub Actions, and Argo CD GitOps.

The goal is not only to run the app, but to understand how a modern CI/CD and security delivery flow is assembled end to end.

## Table of Contents

- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Current CI/CD Flow](#current-cicd-flow)
- [Prerequisites](#prerequisites)
- [Run Locally](#run-locally)
- [Security Stack Setup](#security-stack-setup)
- [EC2 Build Host Setup](#ec2-build-host-setup)
- [GitHub Actions Secrets](#github-actions-secrets)
- [ECR, EKS, and Argo CD Setup](#ecr-eks-and-argo-cd-setup)
- [Pipeline Readiness Checklist](#pipeline-readiness-checklist)
- [Troubleshooting](#troubleshooting)
- [Documentation Index](#documentation-index)

## Architecture

```mermaid
flowchart TB
  dev[Developer] --> git[GitHub Repository]
  git --> gha[GitHub Actions]

  gha --> iac[Terraform and Kubernetes checks]
  gha --> build[Build frontend and backend]
  build --> sonar[SonarQube quality gate]
  build --> trivyfs[Trivy filesystem and IaC scan]
  build --> nexus[Nexus raw artifacts]

  nexus --> ec2[EC2 build host]
  gha --> ec2
  ec2 --> docker[Docker build FE/BE images]
  docker --> trivyimg[Trivy image scan]
  trivyimg --> ecr[Amazon ECR]

  gha --> manifest[Update Kubernetes image tags in Git]
  manifest --> argocd[Argo CD]
  argocd --> eks[AWS EKS]

  eks --> fe[Frontend pods]
  eks --> be[Backend API pods]
  be --> db[(Database)]
```

High-level idea:

- GitHub Actions validates infrastructure, builds source code, runs security gates, and uploads build artifacts to Nexus.
- EC2 acts as a remote build host. It downloads artifacts from Nexus, builds Docker images, scans them with Trivy, and pushes them to ECR.
- The workflow updates image tags in `k8s/base/*.yaml`.
- Argo CD watches Git and syncs the updated manifests to EKS.

## Repository Structure

```text
.
|-- hospital_FE/              # React/Vite frontend, served by nginx as a non-root user
|-- hospital_BE/              # ASP.NET Core 9 backend API
|-- k8s/base/                 # Namespace, Deployments, Services, NetworkPolicy, Kustomize
|-- argocd/                   # Argo CD Application manifest
|-- terraform/                # AWS network and EKS infrastructure as code
|-- security/                 # SonarQube, Nexus, Trivy, and hardening notes
|-- .github/workflows/        # GitHub Actions DevSecOps pipeline
|-- docker-compose.yml        # Local frontend/backend container runner
|-- hospital_db.sql           # Database bootstrap script
`-- DIAGRAM.drawio            # Architecture diagram source
```

Key operational files:

| File | Purpose |
|---|---|
| `.github/workflows/cicd.yml` | Main pipeline: validate, build, scan, publish artifacts, build images, push images, update manifests. |
| `hospital_FE/Dockerfile` | Builds the frontend and serves it with nginx on port `8000`. |
| `hospital_BE/Hospital_API/Dockerfile` | Builds the backend runtime image on port `8080`. |
| `k8s/base/05-fe-deployment.yaml` | Frontend Deployment using `ecr-fe:<sha>`. |
| `k8s/base/07-be-deployment.yaml` | Backend Deployment using `ecr-be:<sha>`. |
| `argocd/hospital-traefik-app.yaml` | Argo CD Application that syncs Kubernetes manifests. |

## Current CI/CD Flow

The pipeline runs on pushes to:

```text
main
devops
```

The pipeline skips commits containing:

```text
ci: update image tag
```

This prevents an infinite loop when the workflow commits updated Kubernetes manifests back to Git.

Main flow:

1. Validate Terraform and render Kubernetes manifests.
2. Restore dependencies through Nexus cache:
   - NuGet: `nuget-group`
   - npm: `npm-group`
3. Build the `.NET 9` backend and the `React/Vite` frontend.
4. Run Trivy filesystem and IaC scans.
5. Run SonarQube analysis when `SONAR_HOST_URL` and `SONAR_TOKEN` are configured.
6. Package build artifacts:
   - `backend-<github.sha>.zip`
   - `frontend-<github.sha>.zip`
7. Upload artifacts to the Nexus raw repository `hospital-artifacts`.
8. SSH into the EC2 build host as `ubuntu`.
9. On EC2: clone/fetch the repo, download artifacts from Nexus, and build Docker images.
10. Scan Docker images with Trivy. The job fails on HIGH or CRITICAL findings.
11. Push images to Amazon ECR:
   - `ecr-fe:<github.sha>`
   - `ecr-be:<github.sha>`
12. Update image tags in `k8s/base`.
13. Argo CD detects the Git change and syncs it to EKS.

## Prerequisites

Local workstation:

- Git
- Docker and Docker Compose
- Node.js 20, if running the frontend outside containers
- .NET SDK 9, if running the backend outside containers
- AWS CLI v2
- Terraform `>= 1.6`
- kubectl
- SSH client

AWS:

- AWS account with permissions for EKS, ECR, EC2, IAM, and VPC.
- ECR repositories:
  - `ecr-fe`
  - `ecr-be`
- Ubuntu EC2 instance used as the build host.
- EKS cluster created by Terraform or already available.

DevSecOps services:

- Nexus Repository Manager
- SonarQube Community
- Trivy CLI or Trivy container

## Run Locally

Start the frontend and backend containers from the repository root:

```bash
docker compose up --build
```

Default ports:

| Service | Container | URL |
|---|---|---|
| Frontend | `cons-react` | `http://localhost:5173` |
| Backend | `cons-dotnet` | `http://localhost:5247` |

The backend needs a database connection string. See:

```text
hospital_BE/Hospital_API/appsettings.example.json
hospital_db.sql
```

In Kubernetes, the backend connection string is provided through a Secret:

```bash
kubectl -n hospital create secret generic be-db-secret \
  --from-literal=default-connection='Server=<host>;Database=<db>;User Id=<user>;Password=<password>;TrustServerCertificate=True'
```

## Security Stack Setup

The `security/` folder provides SonarQube and Nexus through Docker Compose.

```bash
cd security
cp .env.example .env
docker compose up -d
```

Default local endpoints:

| Tool | URL | Purpose |
|---|---|---|
| SonarQube | `http://127.0.0.1:9000` | Static analysis and quality gates. |
| Nexus | `http://127.0.0.1:8081` | Artifact repository and dependency cache. |

Required Nexus repositories:

| Repository | Type | Purpose |
|---|---|---|
| `hospital-artifacts` | raw hosted | Stores backend/frontend zip artifacts. |
| `nuget-group` | NuGet group | Caches NuGet dependencies. |
| `npm-group` | npm group | Caches npm dependencies. |

If SonarQube or Nexus must be reachable from GitHub Actions or EC2, expose them through HTTPS and restrict inbound access to trusted IP ranges.

## EC2 Build Host Setup

The workflow connects to EC2 with:

```text
ubuntu@<EC2_HOST>
```

Install base packages:

```bash
sudo apt update
sudo apt install -y git curl unzip ca-certificates
```

Install Docker:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
docker --version
```

The workflow uses `sudo docker`, so logging out and back in is helpful but not required for the pipeline.

Install AWS CLI v2:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

Recommended AWS authentication: attach an IAM role to the EC2 instance instead of storing long-lived AWS keys on the server.

Minimum ECR permissions for the EC2 role:

```text
ecr:GetAuthorizationToken
ecr:BatchCheckLayerAvailability
ecr:InitiateLayerUpload
ecr:UploadLayerPart
ecr:CompleteLayerUpload
ecr:PutImage
```

Validate the EC2 host:

```bash
git --version
docker --version
aws --version
aws sts get-caller-identity
aws ecr get-login-password --region us-east-1
```

## GitHub Actions Secrets

Configure secrets in:

```text
Repository > Settings > Secrets and variables > Actions
```

Required secrets:

| Secret | Required | Purpose |
|---|---:|---|
| `NEXUS_URL` | Yes | Nexus server URL. |
| `NEXUS_USERNAME` | Yes | Nexus user with read/write access to the raw artifact repository. |
| `NEXUS_PASSWORD` | Yes | Nexus password. |
| `EC2_HOST` | Yes | EC2 public IP or DNS name. |
| `EC2_SSH_PRIVATE_KEY` | Yes | Full private key content used to SSH as `ubuntu`. |
| `EC2_HOST_KEY` | Yes | Host key from `ssh-keyscan -H <EC2_HOST>`. |
| `GIT_USERNAME` | Yes | GitHub username used by EC2 for clone/fetch. |
| `GIT_PASSWORD` | Yes | GitHub Personal Access Token, not a normal GitHub password. |
| `SONAR_HOST_URL` | No | SonarQube URL. SonarQube is skipped if missing. |
| `SONAR_TOKEN` | No | SonarQube token. SonarQube is skipped if missing. |

`EC2_SSH_PRIVATE_KEY` must contain the complete private key:

```text
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

The matching public key must exist on EC2:

```bash
/home/ubuntu/.ssh/authorized_keys
```

Generate `EC2_HOST_KEY`:

```bash
ssh-keyscan -H <EC2_HOST>
```

`GIT_PASSWORD` should be a GitHub PAT with repository read access:

- Fine-grained token: select this repository and allow `Contents: Read`.
- Classic token: use the `repo` scope for private repositories.

## ECR, EKS, and Argo CD Setup

Create ECR repositories if they do not exist:

```bash
aws ecr create-repository --repository-name ecr-fe --region us-east-1
aws ecr create-repository --repository-name ecr-be --region us-east-1
```

Create the dev EKS environment with Terraform:

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan -out tfplan
terraform apply tfplan
aws eks update-kubeconfig --region us-east-1 --name hospital-dev-eks
```

Create the namespace and backend runtime secret:

```bash
kubectl apply -f k8s/base/namespace.yaml

kubectl -n hospital create secret generic be-db-secret \
  --from-literal=default-connection='Server=<host>;Database=<db>;User Id=<user>;Password=<password>;TrustServerCertificate=True'
```

If the cluster pulls private images from ECR, create an image pull secret:

```bash
aws ecr get-login-password --region us-east-1 | \
kubectl -n hospital create secret docker-registry ecr-registry-secret \
  --docker-server=606030503959.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password-stdin
```

Render manifests locally:

```bash
kubectl kustomize k8s/base
```

Apply manifests manually if Argo CD is not being used yet:

```bash
kubectl apply -k k8s/base
kubectl -n hospital get deploy,pods,svc
```

Apply the Argo CD Application:

```bash
kubectl apply -f argocd/hospital-traefik-app.yaml
kubectl -n argocd get applications
```

## Pipeline Readiness Checklist

Before rerunning the workflow, confirm:

- EC2 is reachable with `ssh ubuntu@<EC2_HOST>`.
- EC2 has `git`, `docker`, `aws`, `unzip`, and `curl`.
- EC2 IAM role can push to ECR.
- ECR contains `ecr-fe` and `ecr-be`.
- Nexus contains `hospital-artifacts`, `nuget-group`, and `npm-group`.
- GitHub secrets exist and contain the correct values.
- `GIT_PASSWORD` is a valid GitHub PAT with repository read access.
- Trivy image scan has no fixable HIGH or CRITICAL vulnerabilities.
- Kubernetes has `be-db-secret` and `ecr-registry-secret`.
- Argo CD watches the same branch/path that the workflow updates.

## Troubleshooting

| Symptom | Common cause | Fix |
|---|---|---|
| `Permission denied (publickey)` | EC2 rejected the SSH key | Check `EC2_SSH_PRIVATE_KEY`, `EC2_HOST`, user `ubuntu`, and `/home/ubuntu/.ssh/authorized_keys`. |
| `Host key verification failed` | Wrong or stale `EC2_HOST_KEY` | Regenerate with `ssh-keyscan -H <EC2_HOST>` and update the secret. |
| `aws CLI is not installed on EC2` | AWS CLI missing on EC2 | Install AWS CLI v2 on the EC2 host. |
| `could not read Username for 'https://github.com'` | Bad GitHub username or PAT | Update `GIT_USERNAME` and `GIT_PASSWORD` with a valid PAT. |
| ECR login fails | EC2 IAM role lacks ECR permissions | Attach ECR push permissions to the EC2 role. |
| Trivy reports HIGH/CRITICAL findings | Base image or packages contain CVEs | Upgrade the base image or update packages during the Docker build, then rerun the scan. |
| `be-db-secret` not found | Backend database secret missing | Create `be-db-secret` in the `hospital` namespace. |
| `ImagePullBackOff` | ECR pull secret or image tag is wrong | Check `ecr-registry-secret`, ECR repository, and image tag in manifests. |
| Argo CD does not sync | Branch/path mismatch or app unhealthy | Check `argocd/hospital-traefik-app.yaml`, app status, and repo credentials. |
| Workflow loops repeatedly | Manifest update commit retriggers pipeline | Keep the skip guard for `ci: update image tag`. |

## Security Practices Used

- No real passwords, tokens, private keys, or connection strings are committed.
- GitHub Actions secrets store CI/CD credentials.
- Kubernetes Secrets store runtime configuration.
- EC2 should use an IAM role instead of hardcoded AWS keys.
- Containers run as non-root users where possible.
- Image tags use immutable commit SHAs.
- Trivy blocks the pipeline on HIGH or CRITICAL image vulnerabilities.
- SonarQube and Nexus should be exposed only through restricted and secured endpoints.

## Documentation Index

| Document | Content |
|---|---|
| `.github/workflows/README.md` | GitHub Actions pipeline, secrets, EC2 build host, and CI/CD troubleshooting. |
| `security/README.md` | SonarQube, Nexus, and Trivy overview. |
| `security/nexus/README.md` | Nexus repositories and credentials. |
| `security/sonarqube/README.md` | SonarQube token, scanner, and quality gate setup. |
| `security/trivy/README.md` | Trivy filesystem, image, and IaC scanning. |
| `terraform/README.md` | Terraform module layout and workflow. |
| `terraform/environments/dev/README.md` | Dev EKS environment setup. |
| `terraform/environments/prod/README.md` | Production-oriented Terraform setup. |
| `k8s/README.md` | Kubernetes manifests, namespace, services, and secrets. |
| `argocd/README.md` | GitOps deployment with Argo CD. |
| `hospital_FE/README.md` | Frontend React/Vite/nginx notes. |
| `hospital_BE/README.md` | Backend ASP.NET Core notes. |

## Expected Result

When everything is configured correctly, a push to `main` or `devops` should produce this delivery chain:

```text
Source code -> Build -> Security gates -> Nexus artifacts -> EC2 image build
-> Trivy image scan -> ECR push -> Manifest update -> Argo CD sync -> EKS rollout
```

Final validation commands:

```bash
kubectl -n hospital get deploy,pods,svc
kubectl -n argocd get applications
aws ecr describe-images --repository-name ecr-fe --region us-east-1
aws ecr describe-images --repository-name ecr-be --region us-east-1
```
