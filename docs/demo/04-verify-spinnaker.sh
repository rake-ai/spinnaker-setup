#!/bin/bash
# Step 4: Verify resources in Spinnaker

echo "=========================================="
echo "Step 4: Verify in Spinnaker"
echo "=========================================="
echo

echo "Waiting for Spinnaker cache refresh (30 seconds)..."
sleep 35

echo
echo "1. Checking Clusters..."
CLUSTERS=$(curl -s -u admin:admin123 http://localhost:8084/applications/productapi/clusters 2>/dev/null)
if [ -n "$CLUSTERS" ] && [ "$CLUSTERS" != "[]" ] && echo "$CLUSTERS" | jq -e '.' >/dev/null 2>&1; then
    echo "$CLUSTERS" | jq -r '.[] | "   ✓ Cluster: \(.name) (\(.type))"' 2>/dev/null || echo "   ⚠️  Error parsing cluster data"
else
    echo "   ⚠️  No clusters found yet (may need more time)"
fi

echo
echo "2. Checking Load Balancers..."
LBS=$(curl -s -u admin:admin123 http://localhost:8084/applications/productapi/loadBalancers 2>/dev/null)
if [ -n "$LBS" ] && [ "$LBS" != "[]" ] && echo "$LBS" | jq -e '.' >/dev/null 2>&1; then
    echo "$LBS" | jq -r '.[] | "   ✓ LoadBalancer: \(.name)"' 2>/dev/null || echo "   ⚠️  Error parsing load balancer data"
else
    echo "   ⚠️  No load balancers found yet (may need more time)"
fi

echo
echo "3. Checking Server Groups..."
SGS=$(curl -s -u admin:admin123 http://localhost:8084/applications/productapi/serverGroups 2>/dev/null)
if [ -n "$SGS" ] && [ "$SGS" != "[]" ] && echo "$SGS" | jq -e '.' >/dev/null 2>&1; then
    echo "$SGS" | jq -r '.[] | "   ✓ Server Group: \(.name) (\(.instances | length) instances)"' 2>/dev/null || echo "   ⚠️  Error parsing server group data"
else
    echo "   ⚠️  No server groups found yet (may need more time)"
fi

echo
echo "=========================================="
echo "✅ Verification complete!"
echo "=========================================="
echo
echo "View in Spinnaker UI:"
echo "  - Clusters: http://localhost:9000/#/applications/productapi/clusters"
echo "  - Load Balancers: http://localhost:9000/#/applications/productapi/loadBalancers"
echo "  - Infrastructure: http://localhost:9000/#/applications/productapi/insight"
echo
echo "Next step: Run ./05-deploy-v1.1.sh"
echo
