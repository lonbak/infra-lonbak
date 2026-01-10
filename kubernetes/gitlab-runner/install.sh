#!/bin/bash
# Install GitLab Runner via Helm
set -e

# Check if token is provided
if [ -z "$GITLAB_RUNNER_TOKEN" ]; then
  echo "ERROR: GITLAB_RUNNER_TOKEN environment variable is required"
  echo ""
  echo "Get your runner token from GitLab:"
  echo "1. Go to your project/group Settings > CI/CD > Runners"
  echo "2. Click 'New project runner' or 'New group runner'"
  echo "3. Copy the token (starts with glrt-)"
  echo ""
  echo "Usage: GITLAB_RUNNER_TOKEN=glrt-xxxx ./install.sh"
  exit 1
fi

echo "Adding GitLab Helm repository..."
helm repo add gitlab https://charts.gitlab.io
helm repo update

# Create cache PVC
echo "Creating runner cache PVC..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: runner-cache
  namespace: gitlab-runner
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

echo "Installing GitLab Runner..."
helm upgrade --install gitlab-runner gitlab/gitlab-runner \
  --namespace gitlab-runner \
  --create-namespace \
  -f values.yaml \
  --set runnerToken="$GITLAB_RUNNER_TOKEN" \
  --wait

echo "GitLab Runner installed successfully!"
echo ""
echo "Verify with: kubectl get pods -n gitlab-runner"
