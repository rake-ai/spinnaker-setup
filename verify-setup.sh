#!/bin/bash

echo "# Spinnaker Setup Verification Report"
echo ""
echo "## Generated: $(date)"
echo ""

echo "## 1. Namespace Verification"
echo ""
echo "### All Namespaces"
kubectl get ns | grep -E "spinnaker|minio|jenkins"
echo ""

echo "## 2. Spinnaker Operator Status"
echo ""
echo "### Operator Pods"
kubectl -n spinnaker-operator get pods
echo ""
echo "### Operator Deployment"
kubectl -n spinnaker-operator get deployment
echo ""

echo "## 3. MinIO Status"
echo ""
echo "### MinIO Pods"
kubectl -n minio get pods
echo ""
echo "### MinIO Services"
kubectl -n minio get svc
echo ""
echo "### Bucket Creation Job"
kubectl -n minio get job
echo ""

echo "## 4. Jenkins Status"
echo ""
echo "### Jenkins Pods"
kubectl -n jenkins get pods
echo ""
echo "### Jenkins Services"
kubectl -n jenkins get svc
echo ""

echo "## 5. Spinnaker Status"
echo ""
echo "### SpinnakerService"
kubectl -n spinnaker get spinsvc spinnaker
echo ""
echo "### Spinnaker Pods"
kubectl -n spinnaker get pods
echo ""
echo "### Spinnaker Services"
kubectl -n spinnaker get svc | grep spin-
echo ""

echo "## 6. Service Accounts"
echo ""
echo "### Spinnaker Namespace"
kubectl -n spinnaker get sa
echo ""
echo "### Cluster Roles"
kubectl get clusterrole | grep spinnaker
echo ""

echo "## 7. Port Forward Status"
echo ""
echo "### Running Port Forwards"
ps aux | grep -E "port-forward.*spin-(gate|deck)" | grep -v grep || echo "No port-forwards running"
echo ""

echo "## 8. API Health Check"
echo ""
echo "### Gate Health (if port-forward is running)"
curl -s http://localhost:8084/health 2>/dev/null || echo "Port-forward not running or gate not ready"
echo ""

echo "## 9. Authentication Configuration"
echo ""
echo "### Check Gate Profile Configuration"
kubectl -n spinnaker get spinsvc spinnaker -o yaml | grep -A 30 "profiles:" | head -40
echo ""

