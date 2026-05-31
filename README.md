# Go Web App DevOps Project

This repository contains a simple Go web application and a complete DevOps practice setup around it. The app serves static HTML pages for Home, About, Contact, and Courses, while the project demonstrates how to build, containerize, deploy, and continuously update an application.

## Project Overview

- Go web server using the `net/http` package
- Static pages served from the `static/` directory
- Docker multi-stage build using Go 1.23 and a distroless runtime image
- GitHub Actions workflow for build, test, lint, Docker image push, and Helm chart tag updates
- Kubernetes manifests for direct deployment
- Helm chart for reusable Kubernetes deployment
- Argo CD compatible GitOps deployment from the Helm chart

## Prerequisites

Install these tools before running the full project:

- Git
- Go 1.23 or newer
- Docker
- kubectl
- Helm
- A Kubernetes cluster such as Minikube, Kind, Docker Desktop Kubernetes, EKS, AKS, or GKE
- Argo CD, if you want GitOps deployment

Check your versions:

```bash
git --version
go version
docker --version
kubectl version --client
helm version
```

## Installation

Clone the repository:

```bash
git clone https://github.com/VenkataNaveenReddyYaparla/go-web-app.git
cd go-web-app
```

Download Go modules:

```bash
go mod download
```

Run tests:

```bash
go test ./...
```

Start the application locally:

```bash
go run main.go
```

Open the app:

```text
http://localhost:8080/home
```

## Application Routes

```text
/home
/about
/contact
/courses
```

The application runs on port `8080`.

## Repository Structure

```text
.
|-- .github/workflows/ci.yaml
|-- Dockerfile
|-- go.mod
|-- main.go
|-- main_test.go
|-- static/
|   |-- home.html
|   |-- about.html
|   |-- contact.html
|   `-- courses.html
|-- k8s/manisfests/
|   |-- deployment.yaml
|   |-- service.yaml
|   `-- ingress.yaml
`-- helm/go-web-app-charts/
    |-- Chart.yaml
    |-- values.yaml
    `-- templates/
```

## Run Locally

```bash
go run main.go
```

Open the app:

```text
http://localhost:8080/home
```

Run tests:

```bash
go test ./...
```

## Build With Docker

Build the image:

```bash
docker build -t go-web-app:local .
```

Run the container:

```bash
docker run -p 8080:8080 go-web-app:local
```

Open the app:

```text
http://localhost:8080/home
```

## Deploy With Kubernetes Manifests

Apply the manifests:

```bash
kubectl apply -f k8s/manisfests/
```

Check the resources:

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
```

Remove the deployment:

```bash
kubectl delete -f k8s/manisfests/
```

## Deploy With Helm

Install the chart:

```bash
helm install go-web-app helm/go-web-app-charts
```

Check the release:

```bash
helm list
kubectl get pods
kubectl get svc
```

Upgrade after changes:

```bash
helm upgrade go-web-app helm/go-web-app-charts
```

Uninstall:

```bash
helm uninstall go-web-app
```

## Deploy With Argo CD

Use this repository as the Git source and point Argo CD to the Helm chart path:

```text
Repository URL: https://github.com/VenkataNaveenReddyYaparla/go-web-app.git
Revision: main
Path: helm/go-web-app-charts
Namespace: default
```

Example Argo CD Application manifest:

```yaml
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
      prune: true
      selfHeal: true
```

Apply it:

```bash
kubectl apply -f application.yaml
```

Argo CD can sync the Helm chart and keep the Kubernetes deployment updated from Git.

## CI/CD Workflow

The GitHub Actions workflow:

1. Builds the Go application.
2. Runs tests.
3. Runs `golangci-lint`.
4. Builds and pushes a Docker image to Docker Hub.
5. Updates the Helm chart image tag with the GitHub Actions run ID.

Required GitHub secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
TOKEN
```

## Screenshot

![Website](static/images/golang-website.png)
