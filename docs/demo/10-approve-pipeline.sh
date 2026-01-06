#!/bin/bash
# Step 10: Approve Manual Judgment stage

set -e

echo "=========================================="
echo "Step 10: Approve Pipeline"
echo "=========================================="
echo

# Get execution ID
if [ -f /tmp/productapi-execution-id.txt ]; then
    EXECUTION_ID=$(cat /tmp/productapi-execution-id.txt)
else
    echo "⚠️  No saved execution ID found"
    read -p "Enter execution ID: " EXECUTION_ID
fi

if [ -z "$EXECUTION_ID" ]; then
    echo "❌ No execution ID provided"
    exit 1
fi

echo "Execution ID: $EXECUTION_ID"
echo

# Get stage information
echo "Getting Manual Judgment stage information..."
STAGE_INFO=$(curl -s -u admin:admin123 "http://localhost:8084/pipelines/$EXECUTION_ID" | \
  jq '.stages[] | select(.name == "Manual Judgment")')

if [ -z "$STAGE_INFO" ] || [ "$STAGE_INFO" == "null" ]; then
    echo "❌ Manual Judgment stage not found"
    exit 1
fi

STAGE_ID=$(echo "$STAGE_INFO" | jq -r '.id')
STAGE_STATUS=$(echo "$STAGE_INFO" | jq -r '.status')
INSTRUCTIONS=$(echo "$STAGE_INFO" | jq -r '.context.instructions // "No instructions"')

echo "Stage ID: $STAGE_ID"
echo "Status: $STAGE_STATUS"
echo
echo "Instructions:"
echo "  $INSTRUCTIONS"
echo

if [ "$STAGE_STATUS" != "RUNNING" ]; then
    echo "⚠️  Stage is not in RUNNING state (current: $STAGE_STATUS)"
    echo "Cannot approve at this time"
    exit 1
fi

# Confirm approval
echo "Available actions:"
echo "  1) Approve (continue)"
echo "  2) Reject (stop)"
echo
read -p "Select action [1]: " ACTION
ACTION=${ACTION:-1}

if [ "$ACTION" == "1" ]; then
    JUDGMENT="continue"
    echo "Approving pipeline..."
elif [ "$ACTION" == "2" ]; then
    JUDGMENT="stop"
    echo "Rejecting pipeline..."
else
    echo "❌ Invalid selection"
    exit 1
fi

# Submit judgment
RESPONSE=$(curl -s -u admin:admin123 -X PUT \
  "http://localhost:8084/pipelines/$EXECUTION_ID/stages/$STAGE_ID" \
  -H "Content-Type: application/json" \
  -d "{\"judgmentStatus\": \"$JUDGMENT\"}")

echo "✅ Judgment submitted: $JUDGMENT"

echo
echo "Waiting for pipeline to process..."
sleep 3

# Show updated status
curl -s -u admin:admin123 "http://localhost:8084/pipelines/$EXECUTION_ID" | \
  jq '{
    status,
    stages: [.stages[] | {name, status}]
  }'

echo
echo "=========================================="
echo "✅ Pipeline judgment complete!"
echo "=========================================="
echo
echo "View execution:"
echo "  http://localhost:9000/#/applications/productapi/executions/details/$EXECUTION_ID"
echo
echo "Check deployed resources:"
echo "  kubectl get deployments -l app=productapi"
echo "  kubectl get pods -l app=productapi"
echo
echo "Test traffic:"
echo "  for i in {1..10}; do curl -s http://localhost/; echo; done | sort | uniq -c"
echo
