#!/bin/bash
# Step 1: Create ProductAPI application in Spinnaker

set -e

echo "=========================================="
echo "Step 1: Create Application"
echo "=========================================="
echo

# Check if application already exists
echo "Checking if application already exists..."
if curl -s -u admin:admin123 http://localhost:8080/v2/applications/productapi 2>&1 | grep -q '"name":"productapi"'; then
    echo "⚠️  Application 'productapi' already exists"
    echo
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing application..."
        curl -s -u admin:admin123 -X DELETE http://localhost:8080/v2/applications/productapi
        echo "✅ Application deleted"
        echo "Waiting 2 seconds..."
        sleep 2
    else
        echo "Skipping application creation"
        exit 0
    fi
fi

echo "Creating application 'productapi'..."
curl -s -u admin:admin123 -X POST http://localhost:8080/v2/applications \
  -H "Content-Type: application/json" \
  -d '{
    "name": "productapi",
    "email": "admin@example.com",
    "description": "Product Management API - Demo Application",
    "cloudProviders": "kubernetes"
  }' | jq '.'

echo
echo "Waiting for application to be created..."
sleep 2

# Verify application creation
echo
echo "Verifying application..."
curl -s -u admin:admin123 http://localhost:8080/v2/applications/productapi | jq '{
  name: .name,
  email: .email,
  description: .description,
  cloudProviders: .cloudProviders
}'

echo
echo "=========================================="
echo "✅ Application created successfully!"
echo "=========================================="
echo
echo "You can view it in the UI:"
echo "  http://localhost:9000/#/applications/productapi"
echo
echo "Next step: Run ./02-deploy-v1.sh"
echo
