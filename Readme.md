
# k8s-pages Helm Chart

This repository contains a Helm chart for deploying an NGINX reverse proxy configured with dynamic site definitions, configurable caching headers for Cloudflare (using `stale-while-revalidate`), and more. The chart is designed to be deployed either via the Helm CLI or using Argo CD for GitOps-style continuous delivery.

## Features

- **Dynamic Site Configuration:** Define multiple sites with individual hosts, backend URLs, and host headers.
- **Configurable Caching:** Set the `Cache-Control` header to control browser/CDN caching with `max-age` and `stale-while-revalidate` directives.
- **NGINX Reverse Proxy:** Leverages a ConfigMap to generate the NGINX configuration, a Deployment to run NGINX, and a Service/Ingress for routing.
- **GitOps Ready:** Easily deploy via Argo CD by pointing to this GitHub repository.

## Prerequisites

- **Kubernetes Cluster:** Ensure you have a running Kubernetes cluster.
- **Helm 3:** [Install Helm 3](https://helm.sh/docs/intro/install/).
- **Argo CD (optional):** If you prefer a GitOps approach, install [Argo CD](https://argo-cd.readthedocs.io/en/stable/getting_started/).

## Configuration

The default configuration is defined in `helm-chart/values.yaml`. Here you can set:

``` yaml
# The namespace where all resources will be created.
namespace: k8s-pages
# Number of replicas for the deployment.
replicaCount: 1
# List of sites to configure.
bucket: "k8s-pages"
sites:
  - name: pages
    host: example.com
    # URL to which the proxy_pass should direct traffic. (Include protocol and path)
    minioURL: "minio.minio.svc.cluster.local:9000"
    # The host header to set when proxying.
    minioHost: "minio.example.com"
    # Error Page
    errorPage: "/404.html"
    maxAge: 31536000
    staleWhileRevalidate: 86400
```

## Deploying with Argo CD

``` yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: k8s-pages
  namespace: argocd  # Namespace where Argo CD is installed
spec:
  project: default
  source:
    repoURL: 'https://github.com/waylonwalker/k8s-pages.git'
    targetRevision: HEAD
    path: helm-chart
    helm:
      valueFiles:
        - values.yaml
      # Optional: Override values with parameters
      # parameters:
      #   - name: replicaCount
      #     value: "2"
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: mypages  # Target namespace for deployment
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
