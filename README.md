# go-web-app — DevOps End-to-End Practice Project

A production-style DevOps pipeline built around a lightweight Go web application. The project covers everything from local development through containerization, Kubernetes deployment, GitOps with Argo CD, and fully automated CI/CD via GitHub Actions.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Application Routes](#application-routes)
- [Repository Structure](#repository-structure)
- [Local Development](#local-development)
- [Docker Build](#docker-build)
- [Kubernetes Deployment](#kubernetes-deployment)
  - [Connect to Amazon EKS](#connect-to-amazon-eks)
  - [Install NGINX Ingress Controller](#install-nginx-ingress-controller)
  - [Deploy with Raw Manifests](#deploy-with-raw-manifests)
  - [Deploy with Helm](#deploy-with-helm)
- [GitOps with Argo CD](#gitops-with-argo-cd)
  - [Install Argo CD](#install-argo-cd)
  - [Deploy the Application](#deploy-the-application)
- [CI/CD Pipeline](#cicd-pipeline)
- [Secrets Configuration](#secrets-configuration)
- [Troubleshooting](#troubleshooting)

---

## Project Overview

This repository demonstrates a complete DevOps workflow for a Go web application:

- **Application** — Go HTTP server serving four static HTML pages
- **Containerization** — Docker multi-stage build using a distroless runtime image for minimal attack surface
- **Kubernetes** — Raw manifests and a Helm chart for flexible deployment
- **GitOps** — Argo CD tracks the Helm chart in Git and auto-syncs the cluster
- **CI/CD** — GitHub Actions builds, tests, lints, pushes Docker images, and bumps the Helm chart image tag on every push

---

## Architecture

```
Developer Push
      │
      ▼
┌─────────────────────────────────────────────────┐
│              GitHub Actions CI/CD               │
│  Build → Test → Lint → Docker Push → Helm Tag  │
└────────────────────┬────────────────────────────┘
                     │ updates image tag in Git
                     ▼
             Git Repository
             (Helm chart source of truth)
                     │
                     │ polls for changes
                     ▼
┌─────────────────────────────────────────────────┐
│                  Argo CD                        │
│         Syncs Helm chart to cluster             │
└────────────────────┬────────────────────────────┘
                     │ deploys
                     ▼
┌─────────────────────────────────────────────────┐
│            Kubernetes (EKS / local)             │
│  Deployment → Service → Ingress (NGINX)         │
└─────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Application | Go 1.23, `net/http` |
| Containerization | Docker multi-stage, distroless runtime |
| Orchestration | Kubernetes (EKS / Minikube / Kind) |
| Package Manager | Helm |
| GitOps | Argo CD |
| CI/CD | GitHub Actions |
| Ingress | NGINX Ingress Controller |
| Registry | Docker Hub |
| Cloud (optional) | AWS EKS |

---

## Prerequisites

Install the following tools before running the full project:

| Tool | Purpose | Install |
|---|---|---|
| Git | Source control | [git-scm.com](https://git-scm.com) |
| Go 1.23+ | Build and run the app | [go.dev](https://go.dev/dl) |
| Docker | Build and run containers | [docs.docker.com](https://docs.docker.com/get-docker) |
| kubectl | Kubernetes CLI | [kubernetes.io](https://kubernetes.io/docs/tasks/tools) |
| Helm | Kubernetes package manager | [helm.sh](https://helm.sh/docs/intro/install) |
| AWS CLI | Connect to EKS (optional) | [aws.amazon.com](https://aws.amazon.com/cli) |
| Argo CD CLI | Manage Argo CD from terminal (optional) | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io) |

Verify all tools are installed:

```bash
git --version
go version
docker --version
kubectl version --client
helm version
aws --version          # optional
argocd version --client  # optional
```

---

## Quick Start

Get the app running locally in under two minutes:

```bash
# Clone the repo
git clone https://github.com/VenkataNaveenReddyYaparla/go-web-app.git
cd go-web-app

# Download dependencies
go mod download

# Start the app
go run main.go
```

Open in your browser: [http://localhost:8080/home](http://localhost:8080/home)

---

## Application Routes

The app runs on port `8080` and serves four routes:

| Route | Description |
|---|---|
| `/home` | Home page |
| `/about` | About page |
| `/contact` | Contact page |
| `/courses` | Courses page |

---

## Repository Structure

```
go-web-app/
├── .github/
│   └── workflows/
│       └── ci.yaml              # GitHub Actions CI/CD pipeline
├── helm/
│   └── go-web-app-charts/
│       ├── Chart.yaml           # Helm chart metadata
│       ├── values.yaml          # Default values (image tag updated by CI)
│       └── templates/           # Kubernetes manifest templates
├── k8s/
│   └── manisfests/
│       ├── deployment.yaml      # Kubernetes Deployment
│       ├── service.yaml         # Kubernetes Service
│       └── ingress.yaml         # NGINX Ingress
├── static/
│   ├── home.html
│   ├── about.html
│   ├── contact.html
│   └── courses.html
├── Dockerfile                   # Multi-stage Docker build
├── go.mod
├── main.go                      # Go HTTP server
└── main_test.go                 # Unit tests
```

---

## Local Development

### Run from source

```bash
go run main.go
```
### Build and run a binary

**Linux / macOS:**
```bash
go build -o main .
./main
```

**Windows (PowerShell):**
```powershell
go build -o main.exe .
.\main.exe
```

Verify the app is responding:

```bash
curl http://localhost:8080/home
```

---

## Docker Build

The `Dockerfile` uses a two-stage build:

1. **Build stage** — compiles the Go binary using `golang:1.23`
2. **Runtime stage** — copies only the binary into a distroless image, keeping the final image minimal and secure

```bash
# Build the image
docker build -t go-web-app:local .

# Verify the image was created
docker images go-web-app

# Run the container
docker run -p 8080:8080 go-web-app:local

# Verify it's running
docker ps
curl http://localhost:8080/home
```

## Kubernetes Deployment

### Connect to Amazon EKS

Skip this section if you are using a local cluster (Minikube, Kind, Docker Desktop).

```bash
# Confirm AWS credentials
aws sts get-caller-identity

# Pull cluster credentials into kubeconfig
aws eks update-kubeconfig --region us-east-1 --name demo-cluster

# Verify the context and nodes
kubectl config current-context
kubectl get nodes
```

### Install NGINX Ingress Controller

Required to route external traffic to the application via the Ingress resource.

```bash
# Install the AWS-flavoured ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/aws/deploy.yaml

# Watch the controller come up
kubectl get pods -n ingress-nginx --watch

# Confirm the LoadBalancer service has an external address (takes ~2 min on EKS)
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

### Deploy with Raw Manifests

Use this approach for quick testing or when you don't need Helm templating.

```bash
# Apply all three manifests at once
kubectl apply -f k8s/manisfests/

# Check rollout status
kubectl rollout status deployment/go-web-app

# Inspect all created resources
kubectl get pods,svc,ingress

# Remove everything
kubectl delete -f k8s/manisfests/
```

### Deploy with Helm

Helm adds templating, versioned releases, and easy rollbacks.

```bash
# Install the chart
helm install go-web-app helm/go-web-app-charts

# Check the release and pods
helm list
kubectl get pods,svc

# Upgrade after a values or template change
helm upgrade go-web-app helm/go-web-app-charts

# Verify the rollout after upgrade
kubectl rollout status deployment/go-web-app

# Remove the release
helm uninstall go-web-app
```

---

## GitOps with Argo CD

Argo CD continuously watches the Helm chart in this Git repo and reconciles any drift between Git and the cluster. The GitHub Actions pipeline updates `values.yaml` with the new image tag after each successful build, which Argo CD picks up and rolls out automatically.

### Install Argo CD

```bash
# Create the namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for the server to become available
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Expose the server via a LoadBalancer (or use port-forward for local access)
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Retrieve the external address
kubectl get svc argocd-server -n argocd
```

**Get the initial admin password:**

```bash
# Linux / macOS
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d

# Windows PowerShell
$password = kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
```

### Deploy the Application

Create an Argo CD Application that points to the Helm chart in this repo:

```yaml
# application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: go-web-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/VenkataNaveenReddyYaparla/go-web-app.git
    targetRevision: main
    path: helm/go-web-app-charts
    helm: {}
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true      # removes resources deleted from Git
      selfHeal: true   # corrects manual changes made directly in the cluster
```

```bash
# Apply the Application manifest
kubectl apply -f application.yaml

# Confirm Argo CD synced and the app is healthy
kubectl get application go-web-app -n argocd
kubectl get pods,svc
```

**Argo CD connection details:**

| Field | Value |
|---|---|
| Repository URL | `https://github.com/VenkataNaveenReddyYaparla/go-web-app.git` |
| Revision | `main` |
| Chart path | `helm/go-web-app-charts` |
| Destination namespace | `default` |

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci.yaml`) runs on every push and pull request to `main`.

### Pipeline Stages

```
Push to main
    │
    ├─► Build         go build ./...
    ├─► Test          go test ./...
    ├─► Lint          golangci-lint run
    ├─► Docker Build  docker build + push to Docker Hub
    └─► Helm Update   sed image tag in values.yaml → commit back to repo
                              │
                              └─► Argo CD detects change → auto-sync → rolling update
```

### What each step does

| Step | Details |
|---|---|
| **Build** | Compiles the Go application to catch any compilation errors |
| **Test** | Runs all unit tests with `go test ./...` |
| **Lint** | Runs `golangci-lint` to enforce code quality |
| **Docker Build & Push** | Builds a multi-stage image and pushes to Docker Hub with the GitHub Actions run ID as the tag |
| **Helm Tag Update** | Updates the `image.tag` in `values.yaml` to match the newly pushed Docker image tag, then commits and pushes the change back to the repo |

---

## Secrets Configuration

Add these secrets to your GitHub repository under **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (not your password) |
| `TOKEN` | GitHub personal access token with `repo` scope — used to commit the Helm tag update back to the repo |

---

## Troubleshooting

**Pods stuck in `Pending`**
```bash
kubectl describe pod <pod-name>
# Look for: Insufficient CPU/memory, no schedulable nodes, PVC not bound
```

**Ingress has no external address**
```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx
# If EXTERNAL-IP is <pending>, the LoadBalancer provisioner may still be initializing — wait ~2 minutes on EKS
```

**Argo CD not syncing**
```bash
kubectl get application go-web-app -n argocd -o yaml
# Check .status.conditions for error details
# Common cause: Git repo URL or chart path mismatch
```

**Docker image not found after CI push**
```bash
# Confirm the DOCKERHUB_USERNAME and DOCKERHUB_TOKEN secrets are set correctly
# Check the GitHub Actions run logs for the docker/push step
```

---

## Screenshot

![Website](static/images/image.png)

---

> Built by [VenkataNaveenReddyYaparla](https://github.com/VenkataNaveenReddyYaparla) as a hands-on DevOps portfolio project.
