# Spinnaker Demo Scripts

Quick reference guide for running the Spinnaker ProductAPI demo.

## Directory Structure

```
docs/demo/
├── README.md                    # Complete demo documentation
├── QUICKSTART.md               # This file
├── setup.sh                    # Initial setup and verification
├── 01-create-application.sh    # Create ProductAPI application
├── 02-deploy-v1.sh            # Deploy v1.0.0 via kubectl
├── 03-create-service.sh       # Create LoadBalancer service
├── 04-verify-spinnaker.sh     # Verify resources in Spinnaker
├── 05-deploy-v1.1.sh          # Deploy v1.1.0 (Blue/Green)
├── 06-test-traffic.sh         # Test traffic distribution
├── 07-create-pipeline.sh      # Create deployment pipeline
├── 08-execute-pipeline.sh     # Execute pipeline (v2.0.0)
├── 09-monitor-pipeline.sh     # Monitor pipeline execution
├── 10-approve-pipeline.sh     # Approve Manual Judgment stage
└── cleanup.sh                  # Remove all demo resources
```

## Quick Start

### Prerequisites
- Spinnaker 1.33.0 running on Kubernetes
- kubectl configured for docker-desktop
- curl and jq installed

### Run Complete Demo

```bash
cd docs/demo

# Setup
./setup.sh

# Part 1: kubectl-based deployment (Visibility)
./01-create-application.sh
./02-deploy-v1.sh
./03-create-service.sh
./04-verify-spinnaker.sh
./05-deploy-v1.1.sh
./06-test-traffic.sh

# Part 2: Pipeline-based deployment (Orchestration)
./07-create-pipeline.sh
./08-execute-pipeline.sh
./09-monitor-pipeline.sh
./10-approve-pipeline.sh

# Cleanup (optional)
./cleanup.sh
```

## Script Details

### Setup Phase

**`setup.sh`**
- Verifies Spinnaker is running
- Starts port forwards (9000, 8084, 8080)
- Validates API access
- Checks Kubernetes account

### Part 1: kubectl-Based Demo (Visibility)

**`01-create-application.sh`**
- Creates "productapi" application in Spinnaker
- Sets up email and cloud providers
- **Result:** Application visible in UI

**`02-deploy-v1.sh`**
- Creates v1.0.0 deployment manifest
- Deploys via kubectl with Spinnaker annotations
- Waits for 2 pods to be ready
- **Result:** v1.0.0 running

**`03-create-service.sh`**
- Creates LoadBalancer service
- Exposes on localhost:80
- Tests endpoint connectivity
- **Result:** Traffic can reach pods

**`04-verify-spinnaker.sh`**
- Waits 30s for cache refresh
- Checks clusters, load balancers, server groups
- **Result:** All resources visible in Spinnaker

**`05-deploy-v1.1.sh`**
- Deploys v1.1.0 alongside v1.0.0
- Demonstrates blue/green deployment
- **Result:** 2 versions running (4 total pods)

**`06-test-traffic.sh`**
- Sends 20 requests to LoadBalancer
- Shows traffic distribution
- **Result:** Traffic split across versions

### Part 2: Pipeline-Based Demo (Orchestration)

**`07-create-pipeline.sh`**
- Creates "Deploy to Production" pipeline
- Configures 3 stages (Deploy → Wait → Approve)
- Sets up parameters (VERSION, REPLICAS)
- **Result:** Pipeline ready to execute

**`08-execute-pipeline.sh`**
- Prompts for VERSION and REPLICAS
- Executes pipeline via API
- Returns execution ID
- **Result:** Pipeline running

**`09-monitor-pipeline.sh`**
- Monitors pipeline execution in real-time
- Shows stage status updates
- Stops when PAUSED or COMPLETE
- **Result:** Live pipeline status

**`10-approve-pipeline.sh`**
- Approves or rejects Manual Judgment
- Submits decision via API
- Shows final pipeline status
- **Result:** Pipeline completed

### Cleanup

**`cleanup.sh`**
- Deletes all deployments
- Removes service
- Deletes Spinnaker application
- Cleans temporary files
- **Result:** Clean slate

## Common Commands

### Check Infrastructure

```bash
# All deployments
kubectl get deployments -l app=productapi

# All pods
kubectl get pods -l app=productapi

# Service
kubectl get svc productapi

# Test endpoint
curl http://localhost/
```

### Spinnaker API Queries

```bash
# Application info
curl -u admin:admin123 http://localhost:8080/v2/applications/productapi | jq

# Clusters
curl -u admin:admin123 http://localhost:8084/applications/productapi/clusters | jq

# Pipelines
curl -u admin:admin123 http://localhost:8080/pipelines/productapi | jq

# Pipeline execution
curl -u admin:admin123 http://localhost:8084/pipelines/<EXECUTION_ID> | jq
```

### Access Points

- **Spinnaker UI:** http://localhost:9000 (admin/admin123)
- **Gate API:** http://localhost:8084
- **Front50 API:** http://localhost:8080
- **ProductAPI:** http://localhost/

## Troubleshooting

### Port forwards not working

```bash
# Kill and restart
pkill -f "port-forward"
./setup.sh
```

### Resources not visible in Spinnaker

```bash
# Wait for cache refresh
sleep 35

# Force cache refresh
curl -u admin:admin123 -X POST \
  http://localhost:8084/cache/kubernetes/docker-desktop
```

### Pipeline execution fails

```bash
# Check clouddriver logs
kubectl logs -n spinnaker deployment/spin-clouddriver --tail=100

# Verify account
curl -u admin:admin123 http://localhost:8084/credentials
```

### Service not responding

```bash
# Check pods
kubectl get pods -l app=productapi

# Check service
kubectl get svc productapi

# Wait a moment for LoadBalancer
sleep 5
```

## Demo Flow Summary

```
┌──────────────────────────────────────────────┐
│          PART 1: kubectl-based               │
│         (Spinnaker as Viewer)                │
├──────────────────────────────────────────────┤
│ 1. Create application                        │
│ 2. Deploy v1.0.0 via kubectl                │
│ 3. Create LoadBalancer                       │
│ 4. Verify in Spinnaker (discovered)          │
│ 5. Deploy v1.1.0 (blue/green)               │
│ 6. Test traffic distribution                 │
│                                              │
│ Result: 4 pods (2x v1.0.0, 2x v1.1.0)       │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│         PART 2: Pipeline-based               │
│      (Spinnaker as Orchestrator)             │
├──────────────────────────────────────────────┤
│ 7. Create pipeline (3 stages)               │
│ 8. Execute pipeline (v2.0.0)                │
│ 9. Monitor execution                         │
│ 10. Approve at Manual Judgment               │
│                                              │
│ Result: +3 pods (v2.0.0 via pipeline)       │
│ Total: 7 pods across 3 versions             │
└──────────────────────────────────────────────┘
```

## Key Differences

| Aspect | kubectl Demo | Pipeline Demo |
|--------|--------------|---------------|
| **Deployment Method** | Manual kubectl apply | Spinnaker pipeline |
| **Spinnaker Role** | Viewer (discovers) | Orchestrator (deploys) |
| **Automation** | None | Multi-stage workflow |
| **Approval Gates** | No | Yes (Manual Judgment) |
| **Audit Trail** | Kubernetes only | Full Spinnaker history |
| **Parameterization** | Manual edits | Pipeline parameters |
| **Rollback** | Manual kubectl | Built-in support |

## Time Estimates

- **Setup:** 1-2 minutes
- **Part 1 (kubectl):** 5-7 minutes
- **Part 2 (pipeline):** 5-7 minutes
- **Total Demo:** ~15 minutes

## Success Criteria

After completing the demo, you should have:

- ✅ 3 deployments running (v1.0.0, v1.1.0, v2.0.0)
- ✅ 7 total pods (2+2+3)
- ✅ 1 LoadBalancer service
- ✅ 1 completed pipeline execution
- ✅ All resources visible in Spinnaker UI
- ✅ Traffic distributed across all versions

## Next Steps

After the demo:

1. **Scale deployments:**
   ```bash
   kubectl scale deployment productapi-v2.0.0 --replicas=5
   ```

2. **Deploy new version:**
   ```bash
   ./08-execute-pipeline.sh
   # Enter: VERSION=v2.1.0, REPLICAS=4
   ```

3. **Create more pipelines:**
   - Add webhook triggers
   - Add Slack notifications
   - Add integration tests
   - Add staging environment

4. **Explore Spinnaker features:**
   - Bake stages (image building)
   - Find artifacts stages
   - Conditional execution
   - Traffic management
   - Canary deployments

## Documentation

- **Full Documentation:** [README.md](README.md)
- **Kubernetes Account:** [../add-kubernetes-account.md](../add-kubernetes-account.md)
- **XL Release Integration:** [../spinnaker-integration.md](../spinnaker-integration.md)
- **Feature Guides:** [../features/](../features/)

---

**Happy demoing! 🚀**
