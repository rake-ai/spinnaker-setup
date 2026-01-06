#!/bin/bash
# Step 9: Monitor pipeline execution

set -e

echo "=========================================="
echo "Step 9: Monitor Pipeline Execution"
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

echo "Monitoring execution: $EXECUTION_ID"
echo

# Monitor pipeline
while true; do
    RESPONSE=$(curl -s -u admin:admin123 "http://localhost:8084/pipelines/$EXECUTION_ID")
    STATUS=$(echo "$RESPONSE" | jq -r '.status')
    
    clear
    echo "=========================================="
    echo "Pipeline Execution Monitor"
    echo "=========================================="
    echo
    echo "Execution ID: $EXECUTION_ID"
    echo "Status: $STATUS"
    echo
    echo "Stages:"
    echo "$RESPONSE" | jq -r '.stages[] | "  [\(.status)] \(.name) (\(.type))"'
    
    if [ "$STATUS" == "TERMINAL" ] || [ "$STATUS" == "SUCCEEDED" ] || [ "$STATUS" == "CANCELED" ]; then
        echo
        echo "Pipeline completed with status: $STATUS"
        break
    fi
    
    if [ "$STATUS" == "PAUSED" ]; then
        echo
        echo "⏸️  Pipeline is PAUSED (likely at Manual Judgment stage)"
        echo
        echo "To approve: Run ./10-approve-pipeline.sh"
        break
    fi
    
    echo
    echo "Press Ctrl+C to stop monitoring"
    echo "Refreshing in 5 seconds..."
    sleep 5
done

echo
echo "Checking deployed resources..."
kubectl get deployments -l app=productapi

echo
echo "=========================================="
echo "✅ Monitoring complete!"
echo "=========================================="
echo
echo "View in UI:"
echo "  http://localhost:9000/#/applications/productapi/executions/details/$EXECUTION_ID"
echo
