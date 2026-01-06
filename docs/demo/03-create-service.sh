#!/bin/bash
# Step 3: Create LoadBalancer service

set -e

echo "=========================================="
echo "Step 3: Create LoadBalancer Service"
echo "=========================================="
echo

# Check if service already exists
if kubectl get service productapi > /dev/null 2>&1; then
    echo "⚠️  Service 'productapi' already exists"
    echo
    kubectl get service productapi
    echo
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing service..."
        kubectl delete service productapi
        echo "✅ Service deleted"
        sleep 2
    else
        echo "Skipping service creation"
        exit 0
    fi
fi

# Create service manifest
echo "Creating service manifest..."
cat > /tmp/productapi-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: productapi
  namespace: default
  labels:
    app: productapi
  annotations:
    moniker.spinnaker.io/application: productapi
spec:
  type: LoadBalancer
  selector:
    app: productapi
  ports:
  - name: http
    port: 80
    targetPort: 8080
EOF

echo "✅ Manifest created: /tmp/productapi-service.yaml"
echo

# Deploy service
echo "Creating service..."
kubectl apply -f /tmp/productapi-service.yaml

echo
echo "Waiting for LoadBalancer to be ready..."
sleep 3

echo
echo "Service status:"
kubectl get service productapi

echo
echo "Testing endpoint..."
if curl -s --connect-timeout 5 http://localhost/ > /dev/null 2>&1; then
    echo "✅ Service is responding"
    echo
    echo "Response:"
    curl -s http://localhost/
else
    echo "⚠️  Service not yet accessible (may need a moment)"
fi

echo
echo "=========================================="
echo "✅ Service created successfully!"
echo "=========================================="
echo
echo "Access the API at: http://localhost/"
echo
echo "Next step: Run ./04-verify-spinnaker.sh"
echo
