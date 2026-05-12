# Kubernetes Setup

## 1. Configure kubeconfig

```bash
aws eks update-kubeconfig --region us-east-1 --name hospital-dev-eks
kubectl get nodes
```

## 2. Create Namespace

The namespace is included in `k8s/base/namespace.yaml`, so `kubectl apply -k k8s/base` will create it automatically.

## 3. Create Backend Secret

```bash
kubectl create namespace hospital --dry-run=client -o yaml | kubectl apply -f -
kubectl -n hospital create secret generic be-db-secret \
  --from-literal=default-connection='Server=<host>;Database=<db>;User Id=<user>;Password=<password>;TrustServerCertificate=True'
```

## 4. Deploy

```bash
kubectl apply -k k8s/base
```

## 5. Verify

```bash
kubectl get all -n hospital
kubectl get networkpolicy -n hospital
kubectl describe pod -n hospital -l app=be-v1
kubectl describe pod -n hospital -l app=fe-v1
```

## 6. Remove

```bash
kubectl delete -k k8s/base
```

