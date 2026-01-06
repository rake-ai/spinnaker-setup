#!/bin/bash
# Step 5: Deploy ProductAPI v1.1.0 (Blue/Green deployment)

set -e

echo "=========================================="
echo "Step 5: Deploy v1.1.0 (Blue/Green)"
echo "=========================================="
echo

# Create deployment manifest
echo "Creating deployment manifest for v1.1.0..."
cat > /tmp/productapi-v1.1.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productapi-v1-1
  namespace: default
  labels:
    app: productapi
    version: v1.1.0
  annotations:
    moniker.spinnaker.io/application: productapi
    moniker.spinnaker.io/cluster: productapi
spec:
  replicas: 2
  selector:
    matchLabels:
      app: productapi
      version: v1.1.0
  template:
    metadata:
      labels:
        app: productapi
        version: v1.1.0
    spec:
      containers:
      - name: productapi
        image: hashicorp/http-echo
        args:
        - "-text=ProductAPI v1.1.0 - Product Management System [NEW FEATURES: Advanced Search, Bulk Import]"
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

echo "✅ Manifest created: /tmp/productapi-v1.1.yaml"
echo

# Deploy to Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f /tmp/productapi-v1.1.yaml

echo
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/productapi-v1-1

echo
echo "All deployments:"
kubectl get deployments -l app=productapi

echo
echo "All pods:"
kubectl get pods -l app=productapi

echo
echo "=========================================="
echo "✅ v1.1.0 deployed successfully!"
echo "=========================================="
echo
echo "You now have 2 versions running (Blue/Green deployment)"
echo
echo "Next step: Run ./06-test-traffic.sh"
echo
