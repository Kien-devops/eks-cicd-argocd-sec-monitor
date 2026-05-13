# Kubernetes Setup

## 1. Configure kubeconfig

```bash
aws eks update-kubeconfig --region us-east-1 --name hospital-dev-eks
kubectl get nodes
```

## 2. Choose Environment

Kustomize overlays are split by environment:

| Environment | Path | Namespace |
|---|---|---|
| dev | `k8s/overlays/dev` | `hospital-dev` |
| stag | `k8s/overlays/stag` | `hospital-stag` |
| prod | `k8s/overlays/prod` | `hospital-prod` |

Set the environment you want to deploy:

```bash
export K8S_ENV=dev
export K8S_NAMESPACE=hospital-dev
```

The namespace is included in the rendered overlay, so `kubectl apply -k k8s/overlays/$K8S_ENV` will create it automatically.

## 3. Create Backend Secret

```bash
kubectl create namespace "$K8S_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "$K8S_NAMESPACE" create secret generic be-db-secret \
  --from-literal=default-connection='Server=<host>;Database=<db>;User Id=<user>;Password=<password>;TrustServerCertificate=True'
```

## 4. Deploy

```bash
kubectl apply -k "k8s/overlays/$K8S_ENV"
```

## 5. Verify

```bash
kubectl get all -n "$K8S_NAMESPACE"
kubectl get networkpolicy -n "$K8S_NAMESPACE"
kubectl describe pod -n "$K8S_NAMESPACE" -l app=be-v1
kubectl describe pod -n "$K8S_NAMESPACE" -l app=fe-v1
```

## 6. Remove

```bash
kubectl delete -k "k8s/overlays/$K8S_ENV"
```
