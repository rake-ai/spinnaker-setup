#!/bin/bash
# Cleanup script - Remove all demo resources

set -e

echo "=========================================="
echo "Demo Cleanup"
echo "=========================================="
echo

echo "This will remove:"
echo "  - All ProductAPI deployments"
echo "  - ProductAPI service"
echo "  - ProductAPI application from Spinnaker"
echo "  - All pipelines"
echo

read -p "Are you sure you want to cleanup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled"
    exit 0
fi

echo
echo "1. Deleting Kubernetes resources..."

# Delete deployments
if kubectl get deployments -l app=productapi > /dev/null 2>&1; then
    echo "   Deleting deployments..."
    kubectl delete deployments -l app=productapi
    echo "   ✅ Deployments deleted"
else
    echo "   ⚠️  No deployments found"
fi

# Delete service
if kubectl get service productapi > /dev/null 2>&1; then
    echo "   Deleting service..."
    kubectl delete service productapi
    echo "   ✅ Service deleted"
else
    echo "   ⚠️  No service found"
fi

echo
echo "2. Waiting for clouddriver cache refresh..."
sleep 35

echo
echo "3. Deleting Spinnaker application..."
if curl -s -u admin:admin123 http://localhost:8084/applications/productapi 2>&1 | grep -q '"name":"productapi"'; then
    echo "   Submitting application deletion task..."
    TASK_RESPONSE=$(curl -s -u admin:admin123 -X POST http://localhost:8084/tasks \
      -H "Content-Type: application/json" \
      -d '{
        "application": "productapi",
        "description": "Delete productapi application",
        "job": [{
          "type": "deleteApplication",
          "application": {
            "name": "productapi"
          },
          "user": "admin"
        }]
      }')
    
    TASK_ID=$(echo "$TASK_RESPONSE" | jq -r '.id // .ref // empty' 2>/dev/null)
    
    if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "null" ]; then
        echo "   Task submitted: $TASK_ID"
        echo "   Waiting for deletion to complete..."
        sleep 5
        echo "   ✅ Application deletion initiated"
    else
        echo "   Note: Application deletion submitted (task tracking not available)"
        echo "   ✅ Deletion in progress"
    fi
else
    echo "   ⚠️  Application not found"
fi

echo
echo "4. Cleaning up temporary files..."
rm -f /tmp/productapi-*.yaml
rm -f /tmp/productapi-*.json
rm -f /tmp/productapi-execution-id.txt
echo "   ✅ Temporary files removed"

echo
echo "Verifying cleanup..."
echo
echo "Kubernetes resources:"
kubectl get all -l app=productapi 2>/dev/null || echo "   ✅ No Kubernetes resources found"

echo
echo "Spinnaker application:"
if curl -s -u admin:admin123 http://localhost:8084/applications/productapi 2>&1 | grep -q '"name":"productapi"'; then
    echo "   ⚠️  Application still exists in Spinnaker"
    echo "   Note: Application data may take a few moments to clear from cache"
else
    echo "   ✅ Application removed from Spinnaker"
fi

echo
echo "=========================================="
echo "✅ Cleanup complete!"
echo "=========================================="
echo
echo "To run the demo again, start with:"
echo "  ./setup.sh"
echo
