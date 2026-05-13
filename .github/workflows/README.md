# GitHub Actions DevSecOps CI/CD

![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white)
![Amazon EC2](https://img.shields.io/badge/Amazon%20EC2-Build%20Host-FF9900?logo=amazonec2&logoColor=white)
![Amazon ECR](https://img.shields.io/badge/Amazon%20ECR-Container%20Registry-FF9900?logo=amazonecr&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Build%20%26%20Push-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Manifests-326CE5?logo=kubernetes&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-GitOps-EF7B4D?logo=argo&logoColor=white)

This folder contains the runnable GitHub Actions workflow for IaC checks, Trivy and SonarQube gates, publishing build artifacts to Nexus, building Docker images from those Nexus artifacts on an EC2 server, scanning images with Trivy, pushing them to Amazon ECR, updating Kubernetes image tags in Git, and letting Argo CD deploy the new version.

Runnable workflow:

```text
.github/workflows/cicd.yml
```

## Architecture

```mermaid
flowchart TB
  dev[Developer] --> push[Push to main/stag/devops]
  push --> gha[GitHub Actions]
  gha --> iac[Terraform validate<br/>Kubernetes render]
  iac --> restore[Restore dependencies<br/>through Nexus cache]
  restore --> build[Build backend/frontend]
  build --> trivy[Trivy filesystem<br/>Trivy IaC]
  trivy --> sonar[SonarQube optional<br/>code quality]
  sonar --> nexus[Publish artifacts<br/>to Nexus raw repo]
  nexus --> ssh[SSH to EC2 build host]
  ssh --> ec2[EC2 Server]
  ec2 --> clone[Clone or reset repo]
  clone --> pull[Download artifacts<br/>from Nexus]
  pull --> docker[Docker build FE/BE]
  docker --> imgscan[Trivy image scan]
  imgscan --> ecr[Push images to Amazon ECR]
  gha --> checkout[Checkout repo]
  checkout --> update[Update k8s overlay image tags]
  update --> commit[Commit ci: update image tag]
  commit --> git[Push to devops]
  git --> argocd[Argo CD detects Git change]
  argocd --> eks[AWS EKS rollout]
```

## Workflow

```mermaid
sequenceDiagram
  participant Dev as Developer
  participant GH as GitHub Actions
  participant Nexus as Nexus Repository
  participant EC2 as EC2 Build Server
  participant ECR as Amazon ECR
  participant Git as Git Repository
  participant Argo as Argo CD
  participant EKS as AWS EKS

  Dev->>GH: push to main, stag, or devops
  GH->>GH: validate Terraform and render Kubernetes manifests
  GH->>Nexus: restore NuGet and npm dependencies through cache
  GH->>GH: build backend and frontend
  GH->>GH: run Trivy filesystem and IaC scans
  GH->>GH: run SonarQube when secrets exist
  GH->>GH: package backend/frontend artifacts
  GH->>Nexus: upload artifacts to raw repository
  GH->>EC2: SSH with EC2 key after gates pass
  EC2->>Git: clone/fetch triggering branch
  EC2->>Nexus: download backend/frontend artifacts
  EC2->>ECR: docker login
  EC2->>EC2: build frontend and backend images from artifacts
  EC2->>EC2: run Trivy image scans
  EC2->>ECR: push ecr-fe:<sha> and ecr-be:<sha>
  GH->>Git: checkout devops
  GH->>Git: update deployment image tags
  GH->>Git: commit and push tag update
  Argo->>Git: detect manifest change
  Argo->>EKS: sync deployment
```

## Trigger Rules

| Trigger | Branch | Purpose |
|---|---|---|
| `push` | `main`, `stag`, `devops` | Build/push images and update environment manifests. |
| `workflow_dispatch` | manual | Run workflow from the GitHub UI. |

The workflow skips commits containing:

```text
ci: update image tag
```

This prevents an infinite loop when the workflow commits updated Kubernetes manifests back to `devops`.

## Workflow Environment

These values are defined directly in `cicd.yml`.

| Variable | Current value | Purpose |
|---|---|---|
| `DOTNET_VERSION` | `9.0.x` | .NET SDK version for backend quality gate. |
| `NODE_VERSION` | `20` | Node.js version for frontend quality gate. |
| `BACKEND_PROJECT` | `hospital_BE/Hospital_API/Hospital_API.csproj` | Backend project path. |
| `FRONTEND_DIR` | `hospital_FE` | Frontend working directory. |
| `REPO_DIR` | `/home/ubuntu/eks-cicd-argocd-sec-monitor` | Repo path on EC2 build server. |
| `REPO_URL` | `https://github.com/Kien-devops/eks-cicd-argocd-sec-monitor.git` | Repository URL cloned by EC2. |
| `REGISTRY` | `606030503959.dkr.ecr.us-east-1.amazonaws.com` | Amazon ECR registry. |
| `AWS_REGION` | `us-east-1` | AWS region for ECR login. |
| `IMAGE_TAG` | `${{ github.sha }}` | Immutable image tag. |
| `BRANCH_NAME` | `${{ github.ref_name }}` | Branch cloned/fetched on EC2. |
| `K8S_ENV` | branch-based | Environment selected by branch: `main=prod`, `stag=stag`, all other branches use `dev`. |
| `K8S_OVERLAY` | `k8s/overlays/<env>` | Kustomize overlay rendered by CI and watched by Argo CD. |
| `K8S_KUSTOMIZATION` | `k8s/overlays/<env>/kustomization.yaml` | Overlay file updated by CI with the new image tag. |
| `TERRAFORM_DIR` | `terraform/environments/dev` | Terraform environment validated by CI. |
| `NEXUS_RAW_REPOSITORY` | `hospital-artifacts` | Nexus raw hosted repository used for build artifacts. |
| `NEXUS_NUGET_REPOSITORY` | `nuget-group` | Nexus NuGet group repository used for backend dependency restore. |
| `NEXUS_NPM_REPOSITORY` | `npm-group` | Nexus npm group repository used for frontend dependency install. |
| `BACKEND_ARTIFACT` | `backend-${{ github.sha }}.zip` | Backend publish artifact name. |
| `FRONTEND_ARTIFACT` | `frontend-${{ github.sha }}.zip` | Frontend build artifact name. |

## Required GitHub Secrets

Configure these in:

```text
Repository > Settings > Secrets and variables > Actions
```

| Secret | Required | Purpose |
|---|---|---|
| `SONAR_HOST_URL` | No | SonarQube server URL. If missing, SonarQube analysis is skipped. |
| `SONAR_TOKEN` | No | SonarQube token. If missing, SonarQube analysis is skipped. |
| `NEXUS_URL` | Yes | Nexus server URL used to upload/download build artifacts. |
| `NEXUS_USERNAME` | Yes | Nexus user with read/write access to the raw artifact repository. |
| `NEXUS_PASSWORD` | Yes | Nexus password for `NEXUS_USERNAME`. |
| `EC2_HOST` | Yes | Public IP or DNS name of the EC2 build server. |
| `EC2_SSH_PRIVATE_KEY` | Yes | Private SSH key used to connect to EC2 as `ubuntu`. |
| `EC2_HOST_KEY` | Yes | EC2 SSH host public key for known_hosts verification. |
| `GIT_USERNAME` | Yes | GitHub username used by EC2 when cloning/fetching. |
| `GIT_PASSWORD` | Yes | GitHub personal access token or password used by EC2. |

## Workflow Jobs

| Job | Runs on | Purpose |
|---|---|---|
| `iac-terraform-check` | GitHub-hosted Ubuntu runner | Runs Terraform fmt/init/validate and renders Kubernetes manifests. |
| `security-gates` | GitHub-hosted Ubuntu runner | Runs Trivy, optional SonarQube, builds backend/frontend, and uploads artifacts to Nexus. |
| `build-push-deploy` | GitHub-hosted Ubuntu runner plus remote EC2 SSH | Downloads artifacts from Nexus, builds images on EC2, scans images with Trivy, pushes ECR images, updates Kubernetes manifests. |

The `build-push-deploy` job depends on `security-gates`, which depends on `iac-terraform-check`. If IaC validation, build, lint, Nexus upload/download, SonarQube, or Trivy fails, image build and manifest update will not run.

The workflow uses the built-in `GITHUB_TOKEN` for committing manifest changes back to the repository, because `permissions.contents` is set to `write`.

## EC2 Build Server Setup

Run these commands on the EC2 server.

### 1. Install Base Packages

```bash
sudo apt update
sudo apt install -y git curl unzip ca-certificates
```

### 2. Install Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
docker --version
```

Log out and log back in, or keep using `sudo docker` as the workflow does.

### 3. Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### 4. Configure AWS Access

Recommended production approach: attach an IAM role to the EC2 instance.

Required ECR permissions:

```text
ecr:GetAuthorizationToken
ecr:BatchCheckLayerAvailability
ecr:InitiateLayerUpload
ecr:UploadLayerPart
ecr:CompleteLayerUpload
ecr:PutImage
```

Quick validation:

```bash
aws sts get-caller-identity
aws ecr get-login-password --region us-east-1
```

### 5. Prepare ECR Repositories

The workflow expects these ECR repositories to already exist:

```text
ecr-fe
ecr-be
```

Create them once if needed:

```bash
aws ecr create-repository --repository-name ecr-fe --region us-east-1
aws ecr create-repository --repository-name ecr-be --region us-east-1
```

## SSH Secret Setup

### 1. EC2 Host

Set:

```text
EC2_HOST=<ec2-public-ip-or-dns>
```

### 2. Private Key

Set `EC2_SSH_PRIVATE_KEY` to the full private key content used to connect as `ubuntu`.

Example format:

```text
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

The matching public key must be present on the EC2 instance in:

```bash
/home/ubuntu/.ssh/authorized_keys
```

You can confirm the public key for the secret locally with:

```bash
ssh-keygen -y -f <private-key-file>
```

If GitHub Actions reports `Permission denied (publickey)`, the private key is readable but EC2 did not accept it. Recheck that `EC2_HOST` points to the expected instance, the workflow connects as `ubuntu`, and the matching public key is installed for that user.

### 3. Host Key

Generate the host key from your local machine:

```bash
ssh-keyscan -H <ec2-public-ip-or-dns>
```

Put the output into:

```text
EC2_HOST_KEY
```

The workflow uses `StrictHostKeyChecking=yes`, so this value must match the EC2 host.

## Git Credential Setup

The EC2 server clones/fetches the repository over HTTPS using a basic auth header.

Set:

```text
GIT_USERNAME=<github-username>
GIT_PASSWORD=<github-personal-access-token>
```

Recommended token permissions:

| Scope | Needed for |
|---|---|
| repository read access | clone/fetch on EC2 |

The final manifest commit uses GitHub Actions' built-in token, not `GIT_PASSWORD`.

## Build and Push Step

Before building, the workflow restores dependencies through Nexus cache:

```text
dotnet restore -> Nexus nuget-group -> nuget.org proxy
npm ci         -> Nexus npm-group   -> npmjs proxy
```

The EC2 step downloads the packaged artifacts from Nexus:

```text
backend-<github.sha>.zip
frontend-<github.sha>.zip
```

Then it creates runtime Docker images from those extracted artifacts, scans both images with Trivy, and pushes them to ECR.

The equivalent image flow is:

```bash
curl -H "Authorization: Basic <nexus-auth>" \
  -o backend-<sha>.zip \
  "$NEXUS_URL/repository/hospital-artifacts/<branch>/backend-<sha>.zip"

curl -H "Authorization: Basic <nexus-auth>" \
  -o frontend-<sha>.zip \
  "$NEXUS_URL/repository/hospital-artifacts/<branch>/frontend-<sha>.zip"

sudo docker build -t "ecr-fe:$IMAGE_TAG" -f Dockerfile.frontend .
sudo docker build -t "ecr-be:$IMAGE_TAG" -f Dockerfile.backend .

sudo docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.56.2 image ecr-fe:$IMAGE_TAG
sudo docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.56.2 image ecr-be:$IMAGE_TAG

sudo docker tag "ecr-fe:$IMAGE_TAG" "$REGISTRY/ecr-fe:$IMAGE_TAG"
sudo docker tag "ecr-be:$IMAGE_TAG" "$REGISTRY/ecr-be:$IMAGE_TAG"
sudo docker push "$REGISTRY/ecr-fe:$IMAGE_TAG"
sudo docker push "$REGISTRY/ecr-be:$IMAGE_TAG"
```

Image tags use the full commit SHA:

```text
606030503959.dkr.ecr.us-east-1.amazonaws.com/ecr-fe:<github.sha>
606030503959.dkr.ecr.us-east-1.amazonaws.com/ecr-be:<github.sha>
```

## Manifest Update Step

After pushing images, the workflow updates:

```text
k8s/overlays/<env>/kustomization.yaml
```

It replaces old image tags with:

```text
newTag: <github.sha>
```

Environment selection is branch-based:

| Branch | Overlay | Namespace |
|---|---|---|
| `main` | `k8s/overlays/prod` | `hospital-prod` |
| `stag` | `k8s/overlays/stag` | `hospital-stag` |
| `devops` and manual runs from other branches | `k8s/overlays/dev` | `hospital-dev` |

Then it commits:

```text
ci: update image tag to <github.sha>
```

and pushes to the branch that triggered the workflow:

```text
main or devops
```

## Argo CD Deployment

Argo CD watches Git. Once the manifest commit lands, Argo CD sees the new image tag in the environment overlay and syncs the Kubernetes deployment. Configure each Argo CD application to watch the matching path, for example `k8s/overlays/dev`, `k8s/overlays/stag`, or `k8s/overlays/prod`.

Check:

```bash
kubectl -n argocd get applications
kubectl -n hospital-dev get deploy,pods
```

## Manual Validation

Before relying on CI, test these on EC2:

```bash
git --version
docker --version
aws --version
aws sts get-caller-identity
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 606030503959.dkr.ecr.us-east-1.amazonaws.com
```

Build manually:

```bash
cd /home/ubuntu/eks-cicd-argocd-sec-monitor
sudo docker build -t ecr-fe:test -f hospital_FE/Dockerfile hospital_FE
sudo docker build -t ecr-be:test -f hospital_BE/Hospital_API/Dockerfile hospital_BE/Hospital_API
```

For the Nexus artifact flow, also verify the raw repository exists:

```text
Nexus > Repositories > Create repository > raw (hosted)
Name: hospital-artifacts
```

For dependency cache, verify these Nexus repositories exist:

```text
NuGet group: nuget-group
npm group:   npm-group
```

Check manifests locally:

```bash
kubectl kustomize k8s/overlays/dev
kubectl kustomize k8s/overlays/stag
kubectl kustomize k8s/overlays/prod
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| SSH permission denied | Wrong `EC2_SSH_PRIVATE_KEY` or EC2 user | Confirm key and connect as `ubuntu`. |
| Host key verification failed | Wrong or missing `EC2_HOST_KEY` | Regenerate with `ssh-keyscan -H <host>`. |
| EC2 clone fails | Bad `GIT_USERNAME`/`GIT_PASSWORD` | Use a valid GitHub PAT with repo read access. |
| `aws CLI is not installed on EC2` | AWS CLI missing | Install AWS CLI on EC2. |
| ECR login fails | EC2 IAM role lacks permissions | Attach ECR push permissions. |
| Docker build fails | Docker not installed or Dockerfile error | Validate manual `sudo docker build`. |
| Manifest path not found | Wrong path in workflow | Current repo updates `k8s/overlays/<env>/kustomization.yaml`. |
| Workflow loops forever | Skip guard missing | Keep `ci: update image tag` guard in workflow. |
| Argo CD does not update pods | Argo app path/branch mismatch | Confirm Argo CD watches the right branch and `k8s/overlays/<env>`. |

## Maintenance Checklist

- Rotate EC2 SSH key and GitHub PAT periodically.
- Keep EC2 Docker and AWS CLI updated.
- Keep ECR repositories protected and scanned.
- Keep `EC2_HOST_KEY` updated if the EC2 instance is rebuilt.
- Keep overlay paths in sync with repo structure.
- Confirm Argo CD app points to the same branch and path as this workflow updates.
