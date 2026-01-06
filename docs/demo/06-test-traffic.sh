#!/bin/bash
# Step 6: Test traffic distribution across versions

set -e

echo "=========================================="
echo "Step 6: Test Traffic Distribution"
echo "=========================================="
echo

echo "Current deployments:"
kubectl get deployments -l app=productapi -o custom-columns=NAME:.metadata.name,VERSION:.metadata.labels.version,REPLICAS:.spec.replicas

echo
echo "Sending 20 requests to http://localhost/ ..."
echo

# Send requests and capture responses
RESPONSES=$(for i in {1..20}; do 
    curl -s http://localhost/
    echo
done)

echo "Response summary:"
echo "$RESPONSES" | sort | uniq -c | while read count response; do
    echo "  $count requests → $response"
done

echo
echo "Expected distribution:"
echo "  - ~50% to v1.0.0 (2 pods)"
echo "  - ~50% to v1.1.0 (2 pods)"

echo
echo "=========================================="
echo "✅ Traffic test complete!"
echo "=========================================="
echo
echo "This demonstrates:"
echo "  ✓ Multiple versions running simultaneously"
echo "  ✓ Load balancer distributing traffic"
echo "  ✓ Blue/Green deployment pattern"
echo
echo "Part 1 (kubectl-based demo) is complete!"
echo
echo "Next: Part 2 - Pipeline-based deployment"
echo "Run ./07-create-pipeline.sh"
echo
