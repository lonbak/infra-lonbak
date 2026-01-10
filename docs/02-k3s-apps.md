# Deploying Apps to K3s

## Overview

This guide covers deploying your own applications to the K3s cluster.

## Prerequisites

- K3s cluster running
- Traefik ingress installed
- Pi-hole configured with wildcard DNS
- kubeconfig set up locally or SSH access to K3s node

## Setting Up Local kubectl

### Option 1: Copy kubeconfig locally

```bash
# Get kubeconfig from K3s node
ssh admin@10.10.11.10 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/config-home

# Update server address
sed -i 's/127.0.0.1/10.10.11.10/' ~/.kube/config-home

# Use this config
export KUBECONFIG=~/.kube/config-home
kubectl get nodes
```

### Option 2: SSH to K3s node

```bash
ssh admin@10.10.11.10
kubectl get nodes
```

## Deploying a Simple App

### Step 1: Create Namespace

```bash
kubectl create namespace my-app
```

### Step 2: Create Deployment

```yaml
# my-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: nginx:alpine  # Replace with your image
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
```

### Step 3: Create Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: my-app
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: my-app
```

### Step 4: Create Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: my-app
spec:
  rules:
    - host: my-app.lonbak.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

### Step 5: Apply and Test

```bash
kubectl apply -f my-app.yaml
kubectl get pods -n my-app
curl http://my-app.lonbak.local
```

## Using the Private Registry

### Build and Push Image

```bash
# Build
docker build -t registry.lonbak.local/my-app:v1 .

# Push
docker push registry.lonbak.local/my-app:v1
```

### Use in Deployment

```yaml
spec:
  containers:
    - name: my-app
      image: registry.lonbak.local/my-app:v1
```

## Adding Environment Variables

### Using ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
  namespace: my-app
data:
  API_URL: "http://api.lonbak.local"
  LOG_LEVEL: "info"
---
spec:
  containers:
    - name: my-app
      envFrom:
        - configMapRef:
            name: my-app-config
```

### Using Secrets

```bash
# Create secret
kubectl create secret generic my-app-secrets \
  --from-literal=DB_PASSWORD=supersecret \
  -n my-app
```

```yaml
spec:
  containers:
    - name: my-app
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: my-app-secrets
              key: DB_PASSWORD
```

## Persistent Storage

### Using PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
  namespace: my-app
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
spec:
  containers:
    - name: my-app
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: my-app-data
```

## Health Checks

```yaml
spec:
  containers:
    - name: my-app
      livenessProbe:
        httpGet:
          path: /health
          port: 80
        initialDelaySeconds: 30
        periodSeconds: 10
      readinessProbe:
        httpGet:
          path: /ready
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 5
```

## CI/CD Integration

### GitLab CI Example

```yaml
# .gitlab-ci.yml
variables:
  REGISTRY: registry.lonbak.local
  IMAGE: $REGISTRY/my-app

stages:
  - build
  - deploy

build:
  stage: build
  tags:
    - home
    - k3s
  script:
    - docker build -t $IMAGE:$CI_COMMIT_SHA .
    - docker push $IMAGE:$CI_COMMIT_SHA
    - docker tag $IMAGE:$CI_COMMIT_SHA $IMAGE:latest
    - docker push $IMAGE:latest

deploy:
  stage: deploy
  tags:
    - home
    - k3s
  script:
    - kubectl set image deployment/my-app my-app=$IMAGE:$CI_COMMIT_SHA -n my-app
  only:
    - main
```

## Monitoring with Uptime Kuma

1. Access Uptime Kuma: http://status.lonbak.local
2. Add new monitor
3. Set type: HTTP(s)
4. Set URL: http://my-app.lonbak.local
5. Configure notification (optional)

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n my-app
kubectl describe pod <pod-name> -n my-app
kubectl logs <pod-name> -n my-app -f
```

### Check Ingress

```bash
kubectl get ingress -n my-app
kubectl describe ingress my-app -n my-app
```

### Check Service

```bash
kubectl get svc -n my-app
kubectl get endpoints my-app -n my-app
```

### Test Internal Connectivity

```bash
# From within the cluster
kubectl run test --rm -it --image=alpine -- sh
wget -qO- http://my-app.my-app.svc.cluster.local
```
