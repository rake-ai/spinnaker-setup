#!/bin/bash
# Step 2: Deploy ProductAPI v1.0.0 via kubectl

set -e

echo "=========================================="
echo "Step 2: Deploy v1.0.0 via kubectl"
echo "=========================================="
echo

# Create deployment manifest
echo "Creating deployment manifest..."
cat > /tmp/productapi-v1.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productapi-v1
  namespace: default
  labels:
    app: productapi
    version: v1.0.0
  annotations:
    moniker.spinnaker.io/application: productapi
    moniker.spinnaker.io/cluster: productapi
spec:
  replicas: 2
  selector:
    matchLabels:
      app: productapi
      version: v1.0.0
  template:
    metadata:
      labels:
        app: productapi
        version: v1.0.0
    spec:
      containers:
      - name: productapi
        image: hashicorp/http-echo
        args:
        - "-text=ProductAPI v1.0.0 - Product Management System"
        - "-listen=:8080"
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
EOF

echo "✅ Manifest created: /tmp/productapi-v1.yaml"
echo

# Deploy to Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f /tmp/productapi-v1.yaml

echo
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/productapi-v1

echo
echo "Deployment status:"
kubectl get deployment productapi-v1

echo
echo "Pods:"
kubectl get pods -l app=productapi,version=v1.0.0

echo
echo "=========================================="
echo "✅ v1.0.0 deployed successfully!"
echo "=========================================="
echo
echo "Note: Spinnaker will discover this deployment in ~30 seconds"
echo
echo "Next step: Run ./03-create-service.sh"
echo
