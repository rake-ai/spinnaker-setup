#!/bin/bash
# Setup script - Verify prerequisites and start port forwards

set -e

echo "=========================================="
echo "Spinnaker Demo Setup"
echo "=========================================="
echo

# Check if running in correct directory
if [ ! -f "../../README.md" ]; then
    echo "❌ Please run this script from docs/demo/ directory"
    exit 1
fi

# Verify Spinnaker is running
echo "1. Checking Spinnaker pods..."
kubectl get pods -n spinnaker
echo

# Check if any port forwards are already running
echo "2. Checking for existing port forwards..."
if pgrep -f "port-forward.*spin-deck" > /dev/null; then
    echo "⚠️  Port forward for spin-deck already running"
else
    echo "Starting port forward for spin-deck (UI)..."
    kubectl port-forward -n spinnaker svc/spin-deck 9000:9000 > /dev/null 2>&1 &
    echo "✅ spin-deck port forward started (http://localhost:9000)"
fi

if pgrep -f "port-forward.*spin-gate" > /dev/null; then
    echo "⚠️  Port forward for spin-gate already running"
else
    echo "Starting port forward for spin-gate (API Gateway)..."
    kubectl port-forward -n spinnaker svc/spin-gate 8084:8084 > /dev/null 2>&1 &
    echo "✅ spin-gate port forward started (http://localhost:8084)"
fi

if pgrep -f "port-forward.*spin-front50" > /dev/null; then
    echo "⚠️  Port forward for spin-front50 already running"
else
    echo "Starting port forward for spin-front50 (Config)..."
    kubectl port-forward -n spinnaker svc/spin-front50 8080:8080 > /dev/null 2>&1 &
    echo "✅ spin-front50 port forward started (http://localhost:8080)"
fi

echo
echo "Waiting for services to be ready..."
sleep 3

# Verify API access
echo
echo "3. Verifying Spinnaker API access..."
if curl -s -u admin:admin123 http://localhost:8084/credentials > /dev/null 2>&1; then
    echo "✅ Spinnaker API is accessible"
    
    echo
    echo "4. Checking Kubernetes account..."
    curl -s -u admin:admin123 http://localhost:8084/credentials | jq -r '.[] | "   ✓ \(.type): \(.name)"'
else
    echo "❌ Cannot access Spinnaker API"
    exit 1
fi

echo
echo "=========================================="
echo "✅ Setup complete!"
echo "=========================================="
echo
echo "Access Points:"
echo "  - UI:  http://localhost:9000 (admin/admin123)"
echo "  - API: http://localhost:8084"
echo
echo "Next step: Run ./01-create-application.sh"
echo
