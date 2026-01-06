#!/bin/bash
# Step 8: Execute deployment pipeline

set -e

echo "=========================================="
echo "Step 8: Execute Pipeline"
echo "=========================================="
echo

# Get pipeline ID
echo "Getting pipeline ID..."
PIPELINE_ID=$(curl -s -u admin:admin123 http://localhost:8080/pipelines/productapi | \
  jq -r '.[] | select(.name == "Deploy to Production") | .id')

if [ -z "$PIPELINE_ID" ]; then
    echo "❌ Pipeline not found. Please run ./07-create-pipeline.sh first"
    exit 1
fi

echo "Pipeline ID: $PIPELINE_ID"

# Get parameters
echo
echo "Pipeline parameters:"
echo "  - VERSION (default: v2.0.0)"
echo "  - REPLICAS (default: 3)"
echo

read -p "Enter VERSION [v2.0.0]: " VERSION
VERSION=${VERSION:-v2.0.0}

read -p "Enter REPLICAS [3]: " REPLICAS
REPLICAS=${REPLICAS:-3}

echo
echo "Executing pipeline with:"
echo "  VERSION: $VERSION"
echo "  REPLICAS: $REPLICAS"
echo

# Execute pipeline
RESPONSE=$(curl -s -u admin:admin123 -X POST \
  "http://localhost:8084/pipelines/v2/productapi/$PIPELINE_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"parameters\": {
      \"VERSION\": \"$VERSION\",
      \"REPLICAS\": \"$REPLICAS\"
    },
    \"trigger\": {
      \"type\": \"manual\",
      \"user\": \"admin\"
    }
  }")

EXECUTION_ID=$(echo "$RESPONSE" | jq -r '.ref' | cut -d'/' -f3)

if [ -z "$EXECUTION_ID" ] || [ "$EXECUTION_ID" == "null" ]; then
    echo "❌ Failed to execute pipeline"
    echo "$RESPONSE" | jq '.'
    exit 1
fi

echo "✅ Pipeline execution started!"
echo
echo "Execution ID: $EXECUTION_ID"

# Save execution ID for other scripts
echo "$EXECUTION_ID" > /tmp/productapi-execution-id.txt

echo
echo "Waiting for initial stages..."
sleep 5

# Show initial status
curl -s -u admin:admin123 "http://localhost:8084/pipelines/$EXECUTION_ID" | \
  jq '{
    status,
    stages: [.stages[] | {name, status, type}]
  }'

echo
echo "=========================================="
echo "✅ Pipeline execution initiated!"
echo "=========================================="
echo
echo "View execution in UI:"
echo "  http://localhost:9000/#/applications/productapi/executions/details/$EXECUTION_ID"
echo
echo "Next step: Run ./09-monitor-pipeline.sh"
echo
