# Spinnaker on Kubernetes

**Status:** ✅ Operational | **Version:** 1.33.0 | **Auth:** Basic (admin/admin123)

---

## Quick Start

### Access
- **Web UI:** http://localhost:9000 (login: admin/admin123)
- **API:** http://localhost:8084 (HTTP Basic Auth)

### Start Port Forwards
```bash
kubectl -n spinnaker port-forward svc/spin-gate 8084:80 &
kubectl -n spinnaker port-forward svc/spin-deck 9000:80 &
```

### Verify
```bash
./verify-setup.sh
curl -u admin:admin123 http://localhost:8084/health
```

---

## Installation

### Prerequisites
- Docker Desktop with Kubernetes enabled
- kubectl configured
- Minimum 4GB RAM for Docker

### Setup Instructions

Run these commands in order to initialize the project:

```bash
# 1. Create MinIO namespace and deploy
kubectl create ns minio
kubectl apply -f k8s/minio/

# 2. Apply Spinnaker Operator CRDs
kubectl apply -f k8s/operator/crds

# 3. Create Spinnaker Operator namespace and deploy
kubectl create ns spinnaker-operator
kubectl -n spinnaker-operator apply -f k8s/operator/cluster

# 4. Create service accounts
kubectl apply -f k8s/serviceaccounts/

# 5. Create Spinnaker namespace and deploy
kubectl create ns spinnaker
kubectl -n spinnaker apply -f k8s/spinnaker/spinnakerservice-basic.yaml

# 6. Setup port forwards (run after pods are ready)
kubectl -n spinnaker port-forward svc/spin-gate 8084:80 &
kubectl -n spinnaker port-forward svc/spin-deck 9000:80 &
```

### Install Script
```bash
#!/bin/bash
set -e

echo "=== Installing Spinnaker with Basic Auth ==="

# 1. Deploy MinIO
echo "Step 1: Deploying MinIO..."
kubectl apply -f k8s/minio/
kubectl wait --for=condition=complete job/create-minio-buckets -n minio --timeout=120s

# 2. Install Spinnaker Operator
echo "Step 2: Installing Spinnaker Operator..."
kubectl apply -f k8s/operator/
kubectl wait --for=condition=available deployment/spinnaker-operator -n spinnaker-operator --timeout=120s

# 3. Create Service Accounts
echo "Step 3: Creating Service Accounts..."
kubectl apply -f k8s/serviceaccounts/

# 4. Deploy Spinnaker with Basic Auth
echo "Step 4: Deploying Spinnaker..."
kubectl apply -f k8s/spinnaker/spinnakerservice-basic.yaml

# 5. Wait for Spinnaker
echo "Step 5: Waiting for Spinnaker services..."
sleep 30
kubectl wait --for=condition=ready pod -l app=spin -n spinnaker --timeout=300s

# 6. Setup port forwards
echo "Step 6: Setting up port forwards..."
kubectl -n spinnaker port-forward svc/spin-gate 8084:80 &
kubectl -n spinnaker port-forward svc/spin-deck 9000:80 &

echo "=== Installation Complete ==="
echo "Web UI: http://localhost:9000"
echo "API: http://localhost:8084"
echo "Credentials: admin/admin123"
```

### Manual Steps

**Step 1: Deploy MinIO Storage**
```bash
kubectl apply -f k8s/minio/
kubectl get pods -n minio -w  # Wait for running
```

**Step 2: Install Spinnaker Operator**
```bash
kubectl apply -f k8s/operator/
kubectl get pods -n spinnaker-operator -w  # Wait for running
```

**Step 3: Create Service Accounts**
```bash
kubectl apply -f k8s/serviceaccounts/
```

**Step 4: Deploy Spinnaker with Basic Auth**
```bash
kubectl apply -f k8s/spinnaker/spinnakerservice-basic.yaml
kubectl get pods -n spinnaker -w  # Wait for all 8 pods
```

**Step 5: Setup Port Forwards**
```bash
kubectl -n spinnaker port-forward svc/spin-gate 8084:80 &
kubectl -n spinnaker port-forward svc/spin-deck 9000:80 &
```

---

## Authentication

### Configuration

Authentication is configured in `k8s/spinnaker/spinnakerservice-basic.yaml`:

```yaml
profiles:
  gate:
    security:
      basicform:
        enabled: true
    spring:
      security:
        user:
          name: admin
          password: admin123
  deck:
    settings-local.js: |
      window.spinnakerSettings.authEnabled = true;
      window.spinnakerSettings.authEndpoint = 'http://localhost:8084/login';
```

### Web UI Login
1. Navigate to http://localhost:9000
2. Click login button
3. Enter: admin/admin123

### API Authentication
```bash
# Health check
curl -u admin:admin123 http://localhost:8084/health

# List applications
curl -u admin:admin123 http://localhost:8084/applications

# Get application details
curl -u admin:admin123 http://localhost:8084/applications/myapp
```

### Change Credentials
Edit `k8s/spinnaker/spinnakerservice-basic.yaml`:
```yaml
spring:
  security:
    user:
      name: newuser
      password: newpassword
```

Apply changes:
```bash
kubectl apply -f k8s/spinnaker/spinnakerservice-basic.yaml
kubectl rollout restart deployment/spin-gate -n spinnaker
```

---

## Architecture

### Components

| Service | Purpose | Namespace |
|---------|---------|-----------|
| Spinnaker Operator | Manages Spinnaker lifecycle | spinnaker-operator |
| MinIO | S3-compatible storage | minio |
| clouddriver | Cloud provider integration | spinnaker |
| deck | Web UI | spinnaker |
| echo | Events/notifications | spinnaker |
| front50 | Metadata storage | spinnaker |
| gate | API gateway | spinnaker |
| orca | Orchestration engine | spinnaker |
| redis | Cache | spinnaker |
| rosco | Image bakery | spinnaker |

### Port Mappings
- Gate (API): localhost:8084 → svc/spin-gate:80
- Deck (UI): localhost:9000 → svc/spin-deck:80

---

## Common Commands

### Status Checks
```bash
# Spinnaker status
kubectl -n spinnaker get spinnakerservice

# All pods
kubectl -n spinnaker get pods

# API health
curl -u admin:admin123 http://localhost:8084/health

# Quick status
kubectl -n spinnaker get spinnakerservice && \
kubectl -n spinnaker get pods && \
curl -s -u admin:admin123 http://localhost:8084/health
```

### Port Forward Management
```bash
# Check running port-forwards
ps aux | grep port-forward

# Kill existing
pkill -f "port-forward.*spin-"

# Start fresh
kubectl -n spinnaker port-forward svc/spin-gate 8084:80 &
kubectl -n spinnaker port-forward svc/spin-deck 9000:80 &
```

### Logs
```bash
# Gate logs
kubectl -n spinnaker logs -f deployment/spin-gate

# Deck logs
kubectl -n spinnaker logs -f deployment/spin-deck

# Orca logs
kubectl -n spinnaker logs -f deployment/spin-orca

# All services
kubectl -n spinnaker logs -l app=spin --all-containers=true
```

### Restart Services
```bash
# Restart specific service
kubectl -n spinnaker rollout restart deployment/spin-gate

# Restart all Spinnaker
kubectl -n spinnaker rollout restart deployment

# Force restart
kubectl -n spinnaker delete pod -l app=spin
```

---

## Troubleshooting

### Port-forwards Not Responding
```bash
# Kill and restart
pkill -f "port-forward.*spin-"
kubectl -n spinnaker port-forward svc/spin-gate 8084:80 &
kubectl -n spinnaker port-forward svc/spin-deck 9000:80 &
```

### Authentication Not Working
```bash
# Check Gate configuration
kubectl -n spinnaker get spinnakerservice spinnaker -o yaml | grep -A 20 profiles

# Verify credentials
kubectl -n spinnaker get spinnakerservice spinnaker -o yaml | grep -A 5 "spring:"

# Check Gate logs for auth errors
kubectl -n spinnaker logs deployment/spin-gate | grep -i auth

# Test authentication
curl -I http://localhost:8084/  # Should redirect to /login
curl -u admin:admin123 http://localhost:8084/health  # Should return {"status":"UP"}
```

### Services Not Ready
```bash
# Check pod status
kubectl -n spinnaker get pods

# Describe problematic pod
kubectl -n spinnaker describe pod <pod-name>

# Check events
kubectl -n spinnaker get events --sort-by='.lastTimestamp' | tail -20

# Check SpinnakerService status
kubectl -n spinnaker describe spinnakerservice spinnaker
```

### API Returns 302/Redirect
This means authentication is working correctly. The API requires credentials:
```bash
# Wrong (no auth) - returns 302
curl http://localhost:8084/applications

# Correct (with auth) - returns data
curl -u admin:admin123 http://localhost:8084/applications
```

### UI Not Loading
```bash
# Check Deck pod
kubectl -n spinnaker get pod -l app=spin-deck

# Check Deck logs
kubectl -n spinnaker logs deployment/spin-deck

# Verify port-forward
ps aux | grep "port-forward.*spin-deck"
lsof -i :9000
```

### Complete Reset
```bash
# Delete Spinnaker
kubectl delete -f k8s/spinnaker/spinnakerservice-basic.yaml

# Wait for cleanup
kubectl wait --for=delete pod -l app=spin -n spinnaker --timeout=120s

# Redeploy
kubectl apply -f k8s/spinnaker/spinnakerservice-basic.yaml
```

---

## Verification

Run the verification script:
```bash
./verify-setup.sh
```

This checks:
- ✅ All namespaces present
- ✅ Operator status
- ✅ MinIO deployment
- ✅ All 8 Spinnaker services
- ✅ Service accounts
- ✅ Port-forwards running
- ✅ API health
- ✅ Authentication configuration

---

## Configuration Files

**Active Configuration:**
- `k8s/spinnaker/spinnakerservice-basic.yaml` - Main Spinnaker config with basic auth

**All Manifests:**
- `k8s/minio/` - MinIO storage (5 YAML files)
- `k8s/operator/` - Spinnaker Operator (3 YAML files)
- `k8s/serviceaccounts/` - RBAC config (3 YAML files)
- `k8s/spinnaker/` - Spinnaker services (5 YAML files)

---

## Resources

- **Spinnaker Docs:** https://spinnaker.io/docs/
- **Spinnaker Operator:** https://github.com/armory/spinnaker-operator
- **Spring Security:** https://spring.io/projects/spring-security

---

## Learning Spinnaker

📚 **Feature Guides:** [docs/features/](docs/features/)

Step-by-step guides for essential Spinnaker features:
1. **[Applications](docs/features/01-applications.md)** - Create and manage applications
2. **[Pipelines](docs/features/02-pipelines.md)** - Build deployment workflows
3. **Tasks & Executions** - Monitor pipeline runs (coming soon)
4. **Clusters & Server Groups** - Manage infrastructure (coming soon)
5. **Load Balancers** - Configure traffic routing (coming soon)

Each guide includes UI steps, API examples, and Postman collection references.

🔌 **Postman Collection:** [Spinnaker-API.postman_collection.json](Spinnaker-API.postman_collection.json)

Complete API collection with 22 tested endpoints:
- **Applications:** 9 endpoints (create, list, update, history, tasks, etc.)
- **Pipelines:** 11 endpoints (create, execute, monitor, control, etc.)
- **System:** 2 endpoints (health check, version info)

**Setup Guide:** [docs/POSTMAN-COLLECTION.md](docs/POSTMAN-COLLECTION.md)

Import the collection into Postman to:
- Test all Spinnaker APIs interactively
- Use pre-configured authentication
- Follow guided workflows
- Build custom automation

---

## Summary

- **Version:** Spinnaker 1.33.0
- **Services:** 8/8 running (clouddriver, deck, echo, front50, gate, orca, redis, rosco)
- **Authentication:** Spring Security Basic Form Auth
- **Credentials:** admin/admin123
- **Web UI:** http://localhost:9000
- **API:** http://localhost:8084
- **Verification:** `./verify-setup.sh`
- **Features Documentation:** [docs/features/](docs/features/)
