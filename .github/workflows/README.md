# GitHub Actions EC2 Build and ECR Push

![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white)
![Amazon EC2](https://img.shields.io/badge/Amazon%20EC2-Build%20Host-FF9900?logo=amazonec2&logoColor=white)
![Amazon ECR](https://img.shields.io/badge/Amazon%20ECR-Container%20Registry-FF9900?logo=amazonecr&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Build%20%26%20Push-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Manifests-326CE5?logo=kubernetes&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-GitOps-EF7B4D?logo=argo&logoColor=white)

This folder contains the runnable GitHub Actions workflow for quality/security checks, building Docker images on an EC2 server, pushing them to Amazon ECR, updating Kubernetes image tags in Git, and letting Argo CD deploy the new version.

Runnable workflow:

```text
.github/workflows/cicd.yml
```

## Architecture

```mermaid
flowchart TB
  dev[Developer] --> push[Push to devops]
  push --> gha[GitHub Actions]
  gha --> quality[Build FE/BE<br/>SonarQube optional<br/>Trivy scan]
  quality --> ssh[SSH to EC2 build host]
  ssh --> ec2[EC2 Server]
  ec2 --> clone[Clone or reset repo]
  clone --> docker[Docker build FE/BE]
  docker --> ecr[Push images to Amazon ECR]
  gha --> checkout[Checkout repo]
  checkout --> update[Update k8s/base image tags]
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
  participant EC2 as EC2 Build Server
  participant ECR as Amazon ECR
  participant Git as Git Repository
  participant Argo as Argo CD
  participant EKS as AWS EKS

  Dev->>GH: push to devops
  GH->>GH: build backend and frontend
  GH->>GH: run SonarQube when secrets exist
  GH->>GH: run Trivy filesystem and IaC scans
  GH->>EC2: SSH with EC2 key after gates pass
  EC2->>Git: clone/fetch devops branch
  EC2->>ECR: docker login
  EC2->>EC2: build frontend and backend images
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
| `push` | `devops` | Build/push images and update manifests. |
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
| `FE_MANIFEST` | `k8s/base/05-fe-deployment.yaml` | Frontend deployment manifest updated by CI. |
| `BE_MANIFEST` | `k8s/base/07-be-deployment.yaml` | Backend deployment manifest updated by CI. |

## Required GitHub Secrets

Configure these in:

```text
Repository > Settings > Secrets and variables > Actions
```

| Secret | Required | Purpose |
|---|---|---|
| `SONAR_HOST_URL` | No | SonarQube server URL. If missing, SonarQube analysis is skipped. |
| `SONAR_TOKEN` | No | SonarQube token. If missing, SonarQube analysis is skipped. |
| `EC2_HOST` | Yes | Public IP or DNS name of the EC2 build server. |
| `EC2_SSH_PRIVATE_KEY` | Yes | Private SSH key used to connect to EC2 as `ubuntu`. |
| `EC2_HOST_KEY` | Yes | EC2 SSH host public key for known_hosts verification. |
| `GIT_USERNAME` | Yes | GitHub username used by EC2 when cloning/fetching. |
| `GIT_PASSWORD` | Yes | GitHub personal access token or password used by EC2. |

## Workflow Jobs

| Job | Runs on | Purpose |
|---|---|---|
| `quality-and-security` | GitHub-hosted Ubuntu runner | Builds backend/frontend, runs optional SonarQube, runs Trivy scans. |
| `build-and-push` | GitHub-hosted Ubuntu runner plus remote EC2 SSH | Builds images on EC2, pushes ECR images, updates Kubernetes manifests. |

The `build-and-push` job depends on `quality-and-security`. If build, lint, SonarQube, or Trivy fails, image build and manifest update will not run.

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

The EC2 step runs:

```bash
sudo docker build -t "ecr-fe:$IMAGE_TAG" -f hospital_FE/Dockerfile hospital_FE
sudo docker build -t "ecr-be:$IMAGE_TAG" -f hospital_BE/Hospital_API/Dockerfile hospital_BE/Hospital_API
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
k8s/base/05-fe-deployment.yaml
k8s/base/07-be-deployment.yaml
```

It replaces old image tags with:

```text
image: 606030503959.dkr.ecr.us-east-1.amazonaws.com/ecr-fe:<github.sha>
image: 606030503959.dkr.ecr.us-east-1.amazonaws.com/ecr-be:<github.sha>
```

Then it commits:

```text
ci: update image tag to <github.sha>
```

and pushes to:

```text
devops
```

## Argo CD Deployment

Argo CD watches Git. Once the manifest commit lands on `devops`, Argo CD sees the new image tag and syncs the Kubernetes deployment.

Check:

```bash
kubectl -n argocd get applications
kubectl -n hospital get deploy,pods
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

Check manifests locally:

```bash
kubectl kustomize k8s/base
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
| Manifest path not found | Wrong path in workflow | Current repo uses `k8s/base/*.yaml`. |
| Workflow loops forever | Skip guard missing | Keep `ci: update image tag` guard in workflow. |
| Argo CD does not update pods | Argo app path/branch mismatch | Confirm Argo CD watches `devops` and `k8s/base`. |

## Maintenance Checklist

- Rotate EC2 SSH key and GitHub PAT periodically.
- Keep EC2 Docker and AWS CLI updated.
- Keep ECR repositories protected and scanned.
- Keep `EC2_HOST_KEY` updated if the EC2 instance is rebuilt.
- Keep manifest paths in sync with repo structure.
- Confirm Argo CD app points to the same branch and path as this workflow updates.
