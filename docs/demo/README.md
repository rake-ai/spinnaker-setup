# Spinnaker Demo: ProductAPI Deployment

**Date:** January 6, 2026  
**Spinnaker Version:** 1.33.0  
**Environment:** Docker Desktop Kubernetes  
**Status:** ✅ Successfully Executed

---

## Demo Outline

### 1. SETUP
- **Spinnaker:** 1.33.0 on Docker Desktop Kubernetes
- **Account:** docker-desktop (configured and operational)
- **Authentication:** admin / admin123
- **UI Access:** http://localhost:9000
- **API Access:** http://localhost:8084

### 2. DEMO PART 1: KUBECTL-BASED (Visibility)
- Created application "productapi" via Spinnaker API
- Deployed v1.0.0 (2 pods) using kubectl with Spinnaker annotations
- Deployed v1.1.0 (2 pods) using kubectl with Spinnaker annotations
- Created LoadBalancer service
- **Result:** Spinnaker discovers and displays resources (viewer role)

### 3. DEMO PART 2: PIPELINE-BASED (Orchestration)
- Created pipeline "Deploy to Production" with 3 stages:
  1. Deploy Manifest (parameterized)
  2. Wait 10 seconds
  3. Manual Judgment (approval gate)
- Executed pipeline with parameters (VERSION=v2.0.0, REPLICAS=3)
- **Result:** Spinnaker orchestrates deployment via pipeline (3 pods)

### 4. CURRENT STATE
- **3 versions running:** v1.0.0, v1.1.0, v2.0.0
- **7 total pods** across 3 deployments
- **v2.0.0** deployed via PIPELINE ⭐ (others via kubectl)
- Pipeline paused at Manual Judgment stage (awaiting approval)

### 5. KEY DIFFERENCE
```
kubectl demo:  Spinnaker as viewer (discovers resources)
Pipeline demo: Spinnaker as orchestrator (deploys resources) ⭐
```

**This is why Spinnaker exists!** Pipelines are its core value proposition.

---

## Part 1: kubectl-Based Demo (Visibility)

### Objective
Demonstrate that Spinnaker can discover and display Kubernetes resources deployed outside of Spinnaker, as long as they have proper annotations.

### Prerequisites

```bash
# Verify Spinnaker is running
kubectl get pods -n spinnaker

# Port forward services
kubectl port-forward -n spinnaker svc/spin-deck 9000:9000 &
kubectl port-forward -n spinnaker svc/spin-gate 8084:8084 &

# Verify Kubernetes account
curl -u admin:admin123 http://localhost:8084/credentials
```

### Step 1: Create Application

```bash
curl -u admin:admin123 -X POST http://localhost:8080/v2/applications \
  -H "Content-Type: application/json" \
  -d '{
    "name": "productapi",
    "email": "admin@example.com",
    "description": "Product Management API - Demo Application",
    "cloudProviders": "kubernetes"
  }'
```

**Verify:**
```bash
curl -u admin:admin123 http://localhost:8080/v2/applications/productapi | jq
```

### Step 2: Deploy v1.0.0 via kubectl

Create deployment manifest with Spinnaker annotations:

```yaml
# /tmp/productapi-v1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productapi-v1
  namespace: default
  labels:
    app: productapi
    version: v1.0.0
  annotations:
    moniker.spinnaker.io/application: productapi
    moniker.spinnaker.io/cluster: productapi
spec:
  replicas: 2
  selector:
    matchLabels:
      app: productapi
      version: v1.0.0
  template:
    metadata:
      labels:
        app: productapi
        version: v1.0.0
    spec:
      containers:
      - name: productapi
        image: hashicorp/http-echo
        args:
        - "-text=ProductAPI v1.0.0 - Product Management System"
        - "-listen=:8080"
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
```

**Deploy:**
```bash
kubectl apply -f /tmp/productapi-v1.yaml
kubectl get deployment productapi-v1
kubectl get pods -l app=productapi
```

### Step 3: Create LoadBalancer Service

```yaml
# /tmp/productapi-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: productapi
  namespace: default
  labels:
    app: productapi
  annotations:
    moniker.spinnaker.io/application: productapi
spec:
  type: LoadBalancer
  selector:
    app: productapi
  ports:
  - name: http
    port: 80
    targetPort: 8080
```

**Deploy:**
```bash
kubectl apply -f /tmp/productapi-service.yaml
kubectl get svc productapi
```

### Step 4: Wait for Spinnaker Discovery

Clouddriver caches Kubernetes resources every 30 seconds.

```bash
echo "Waiting for clouddriver cache refresh..."
sleep 35
```

### Step 5: Verify in Spinnaker

**Via API:**
```bash
# Check clusters
curl -u admin:admin123 http://localhost:8084/applications/productapi/clusters | jq

# Check load balancers
curl -u admin:admin123 http://localhost:8084/applications/productapi/loadBalancers | jq

# Check server groups
curl -u admin:admin123 http://localhost:8084/applications/productapi/serverGroups | jq
```

**Via UI:**
1. Open http://localhost:9000
2. Login: admin / admin123
3. Navigate: Applications → PRODUCTAPI
4. Check tabs: Clusters, Load Balancers, Infrastructure

### Step 6: Deploy v1.1.0 (Blue/Green)

```yaml
# /tmp/productapi-v1.1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productapi-v1-1
  namespace: default
  labels:
    app: productapi
    version: v1.1.0
  annotations:
    moniker.spinnaker.io/application: productapi
    moniker.spinnaker.io/cluster: productapi
spec:
  replicas: 2
  selector:
    matchLabels:
      app: productapi
      version: v1.1.0
  template:
    metadata:
      labels:
        app: productapi
        version: v1.1.0
    spec:
      containers:
      - name: productapi
        image: hashicorp/http-echo
        args:
        - "-text=ProductAPI v1.1.0 - Product Management System [NEW FEATURES: Advanced Search, Bulk Import]"
        - "-listen=:8080"
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
```

**Deploy:**
```bash
kubectl apply -f /tmp/productapi-v1.1.yaml
kubectl get deployments -l app=productapi
kubectl get pods -l app=productapi
```

### Step 7: Test Multi-Version Traffic

```bash
# Test traffic distribution
for i in {1..10}; do curl -s http://localhost/; echo; done | sort | uniq -c
```

**Expected output:**
```
  2 ProductAPI v1.0.0 - Product Management System
  8 ProductAPI v1.1.0 - Product Management System [NEW FEATURES: Advanced Search, Bulk Import]
```

### Results - Part 1

✅ **Application created** in Spinnaker  
✅ **Kubernetes resources discovered** by clouddriver  
✅ **Clusters visible** in Spinnaker UI  
✅ **Load balancers visible** in Spinnaker UI  
✅ **Server groups visible** with pod counts  
✅ **Multi-version deployment** working (blue/green)

**Limitation:** Spinnaker only **views** resources, doesn't orchestrate deployment.

---

## Part 2: Pipeline-Based Demo (Orchestration)

### Objective
Demonstrate Spinnaker's core feature: deployment orchestration via pipelines with automated stages, parameterization, and approval gates.

### Step 1: Create Deployment Pipeline

```bash
cat > /tmp/productapi-pipeline.json << 'EOF'
{
  "application": "productapi",
  "name": "Deploy to Production",
  "description": "Deploy ProductAPI to Kubernetes with automated stages",
  "expectedArtifacts": [],
  "keepWaitingPipelines": false,
  "limitConcurrent": true,
  "parameterConfig": [
    {
      "name": "VERSION",
      "description": "Version to deploy (e.g., v2.0.0)",
      "default": "v2.0.0",
      "required": true
    },
    {
      "name": "REPLICAS",
      "description": "Number of replicas",
      "default": "3",
      "required": true
    }
  ],
  "stages": [
    {
      "name": "Deploy Manifest",
      "refId": "1",
      "type": "deployManifest",
      "account": "docker-desktop",
      "cloudProvider": "kubernetes",
      "source": "text",
      "manifests": [
        {
          "apiVersion": "apps/v1",
          "kind": "Deployment",
          "metadata": {
            "name": "productapi-${parameters.VERSION}",
            "namespace": "default",
            "labels": {
              "app": "productapi",
              "version": "${parameters.VERSION}"
            },
            "annotations": {
              "moniker.spinnaker.io/application": "productapi",
              "moniker.spinnaker.io/cluster": "productapi"
            }
          },
          "spec": {
            "replicas": "${ #toInt( parameters.REPLICAS ) }",
            "selector": {
              "matchLabels": {
                "app": "productapi",
                "version": "${parameters.VERSION}"
              }
            },
            "template": {
              "metadata": {
                "labels": {
                  "app": "productapi",
                  "version": "${parameters.VERSION}"
                }
              },
              "spec": {
                "containers": [
                  {
                    "name": "productapi",
                    "image": "hashicorp/http-echo",
                    "args": [
                      "-text=ProductAPI ${parameters.VERSION} - Product Management System [Deployed via Pipeline]",
                      "-listen=:8080"
                    ],
                    "ports": [
                      {
                        "containerPort": 8080,
                        "name": "http"
                      }
                    ],
                    "resources": {
                      "requests": {
                        "cpu": "100m",
                        "memory": "64Mi"
                      },
                      "limits": {
                        "cpu": "200m",
                        "memory": "128Mi"
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      ],
      "moniker": {
        "app": "productapi"
      },
      "requisiteStageRefIds": [],
      "skipExpressionEvaluation": false
    },
    {
      "name": "Wait for Deployment",
      "refId": "2",
      "type": "wait",
      "waitTime": 10,
      "requisiteStageRefIds": ["1"]
    },
    {
      "name": "Manual Judgment",
      "refId": "3",
      "type": "manualJudgment",
      "failPipeline": true,
      "instructions": "Review the deployment and approve to continue, or reject to rollback.",
      "judgmentInputs": [
        {"value": "Approve"},
        {"value": "Reject"}
      ],
      "requisiteStageRefIds": ["2"]
    }
  ],
  "triggers": []
}
EOF

# Create pipeline
curl -u admin:admin123 -X POST http://localhost:8080/pipelines \
  -H "Content-Type: application/json" \
  -d @/tmp/productapi-pipeline.json | jq '{id, name}'
```

### Step 2: Verify Pipeline Created

```bash
curl -u admin:admin123 http://localhost:8080/pipelines/productapi | \
  jq '.[] | {id, name, stages: [.stages[].name]}'
```

**Expected output:**
```json
{
  "id": "8249104e-3075-42dd-b5f8-5f0fcdf23ed8",
  "name": "Deploy to Production",
  "stages": [
    "Deploy Manifest",
    "Wait for Deployment",
    "Manual Judgment"
  ]
}
```

### Step 3: Execute Pipeline

```bash
# Get pipeline ID from previous step
PIPELINE_ID="8249104e-3075-42dd-b5f8-5f0fcdf23ed8"

# Execute pipeline
curl -u admin:admin123 -X POST \
  "http://localhost:8084/pipelines/v2/productapi/$PIPELINE_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "parameters": {
      "VERSION": "v2.0.0",
      "REPLICAS": "3"
    },
    "trigger": {
      "type": "manual",
      "user": "admin"
    }
  }' | jq '{executionId: .ref}'
```

**Save execution ID:**
```bash
EXECUTION_ID="01KE92A2E7JH9D53ZWFNWXB8X5"  # From response
```

### Step 4: Monitor Pipeline Execution

```bash
# Check pipeline status
curl -u admin:admin123 \
  "http://localhost:8084/pipelines/$EXECUTION_ID" | \
  jq '{status, stages: [.stages[] | {name, status, type}]}'
```

**Watch deployment progress:**
```bash
kubectl get deployment productapi-v2.0.0 -w
```

### Step 5: Verify Deployment

```bash
# Check deployment
kubectl get deployment productapi-v2.0.0

# Check pods
kubectl get pods -l version=v2.0.0

# Test endpoint
for i in {1..10}; do curl -s http://localhost/; echo; done | sort | uniq -c
```

**Expected:** You should see responses with "Deployed via Pipeline" text.

### Step 6: Pipeline at Manual Judgment

At this point, the pipeline is paused at the Manual Judgment stage.

**Check stage status:**
```bash
curl -u admin:admin123 \
  "http://localhost:8084/pipelines/$EXECUTION_ID" | \
  jq '.stages[] | select(.name == "Manual Judgment") | {name, status, instructions}'
```

**To approve via UI:**
1. Go to http://localhost:9000
2. Navigate: Applications → PRODUCTAPI → Pipelines
3. Click on running execution
4. Click "Continue" button

**To approve via API:**
```bash
STAGE_ID=$(curl -s -u admin:admin123 \
  "http://localhost:8084/pipelines/$EXECUTION_ID" | \
  jq -r '.stages[] | select(.name == "Manual Judgment") | .id')

curl -u admin:admin123 -X PUT \
  "http://localhost:8084/pipelines/$EXECUTION_ID/stages/$STAGE_ID" \
  -H "Content-Type: application/json" \
  -d '{"judgmentStatus": "continue"}'
```

### Results - Part 2

✅ **Pipeline created** with 3 stages  
✅ **Pipeline executed** with parameters (VERSION=v2.0.0, REPLICAS=3)  
✅ **Deployment automated** by Spinnaker (not kubectl)  
✅ **3 pods deployed** via pipeline orchestration  
✅ **Manual approval gate** working correctly  
✅ **Multi-version deployment** - 3 versions serving traffic simultaneously  

**Achievement:** Spinnaker **orchestrates** deployment, not just viewing.

---

## Current Infrastructure State

### Deployments

```bash
kubectl get deployments -l app=productapi
```

| Deployment | Version | Replicas | Method | Age |
|------------|---------|----------|--------|-----|
| productapi-v1 | v1.0.0 | 2/2 | kubectl | 8m28s |
| productapi-v1-1 | v1.1.0 | 2/2 | kubectl | 6m22s |
| productapi-v2.0.0 | v2.0.0 | 3/3 | **Pipeline** | 71s |

### Pods

```bash
kubectl get pods -l app=productapi
```

**Total:** 7 pods running
- 2 pods: v1.0.0 (kubectl)
- 2 pods: v1.1.0 (kubectl)
- 3 pods: v2.0.0 (pipeline) ⭐

### Service

```bash
kubectl get svc productapi
```

**Type:** LoadBalancer  
**External IP:** localhost  
**Port:** 80 → 8080  
**Selector:** app=productapi (routes to all versions)

### Traffic Distribution

```bash
for i in {1..10}; do curl -s http://localhost/; echo; done | sort | uniq -c
```

**Current distribution:**
- 20% → v1.0.0 (kubectl)
- 30% → v1.1.0 (kubectl)
- 50% → v2.0.0 (pipeline) ⭐

---

## Key Differences: kubectl vs Pipeline

### kubectl Approach (Part 1)

**What happens:**
1. You manually run `kubectl apply`
2. Kubernetes creates resources
3. Spinnaker discovers resources via clouddriver cache (every 30s)
4. Spinnaker displays resources in UI

**Spinnaker's role:** **Viewer** (passive)

**Characteristics:**
- ❌ No orchestration
- ❌ No approval gates
- ❌ No deployment audit trail in Spinnaker
- ❌ No automated workflows
- ❌ No rollback capability
- ✅ Simple for testing
- ✅ Quick for one-off deployments
- ✅ Resources still visible in Spinnaker (via annotations)

### Pipeline Approach (Part 2)

**What happens:**
1. You trigger pipeline execution (UI or API)
2. Spinnaker orchestrates multi-stage workflow
3. Stage 1: Spinnaker deploys manifest to Kubernetes
4. Stage 2: Spinnaker waits for stabilization
5. Stage 3: Spinnaker pauses for manual approval
6. Spinnaker tracks entire execution with audit trail

**Spinnaker's role:** **Orchestrator** (active)

**Characteristics:**
- ✅ Full orchestration
- ✅ Automated multi-stage workflows
- ✅ Manual approval gates
- ✅ Complete audit trail (who deployed what when)
- ✅ Parameterized deployments
- ✅ Built-in rollback support
- ✅ Integration with CI/CD systems
- ✅ Production-ready workflows
- ✅ Conditional execution
- ✅ Notifications (Slack, email, etc.)

---

## Pipeline Features Demonstrated

### 1. Parameterization

```json
"parameterConfig": [
  {
    "name": "VERSION",
    "default": "v2.0.0",
    "required": true
  },
  {
    "name": "REPLICAS",
    "default": "3",
    "required": true
  }
]
```

**Benefit:** Same pipeline deploys any version with any replica count.

### 2. Expression Language

```yaml
spec:
  replicas: "${ #toInt( parameters.REPLICAS ) }"
```

**Benefit:** Type conversion, conditional logic, dynamic manifest generation.

### 3. Stage Dependencies

```json
{
  "name": "Wait for Deployment",
  "requisiteStageRefIds": ["1"]  // Runs after Deploy Manifest
}
```

**Benefit:** Ensures proper execution order.

### 4. Manual Judgment (Approval Gates)

```json
{
  "name": "Manual Judgment",
  "type": "manualJudgment",
  "instructions": "Review the deployment...",
  "judgmentInputs": [
    {"value": "Approve"},
    {"value": "Reject"}
  ],
  "failPipeline": true
}
```

**Benefit:** Human approval before completing deployment.

### 5. Multi-Stage Orchestration

**Workflow:** Deploy → Wait → Approve

Each stage has a specific purpose:
- **Deploy:** Creates resources in Kubernetes
- **Wait:** Allows pods to stabilize
- **Approve:** Requires human review before marking complete

---

## Access Points

### Spinnaker UI
- **URL:** http://localhost:9000
- **Login:** admin / admin123
- **Navigate to:** Applications → PRODUCTAPI

**What you'll see:**
- **Clusters tab:** All 3 deployments visible
- **Load Balancers tab:** service/productapi
- **Pipelines tab:** "Deploy to Production" pipeline
- **Infrastructure tab:** All 7 pods
- **Execution History:** Pipeline runs with stage-by-stage progress

### Spinnaker API
- **Gate (API Gateway):** http://localhost:8084
- **Front50 (Config):** http://localhost:8080

### ProductAPI Application
- **URL:** http://localhost/
- **Test:** `curl http://localhost/`

---

## Next Steps

### 1. Complete Manual Judgment

**Via UI:**
```
1. Open http://localhost:9000
2. Go to PRODUCTAPI → Pipelines
3. Click on running execution
4. Click "Continue" button
```

**Via API:**
```bash
EXECUTION_ID="01KE92A2E7JH9D53ZWFNWXB8X5"
STAGE_ID=$(curl -s -u admin:admin123 \
  "http://localhost:8084/pipelines/$EXECUTION_ID" | \
  jq -r '.stages[] | select(.name == "Manual Judgment") | .id')

curl -u admin:admin123 -X PUT \
  "http://localhost:8084/pipelines/$EXECUTION_ID/stages/$STAGE_ID" \
  -H "Content-Type: application/json" \
  -d '{"judgmentStatus": "continue"}'
```

### 2. Deploy Another Version

```bash
PIPELINE_ID="8249104e-3075-42dd-b5f8-5f0fcdf23ed8"

curl -u admin:admin123 -X POST \
  "http://localhost:8084/pipelines/v2/productapi/$PIPELINE_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "parameters": {
      "VERSION": "v2.1.0",
      "REPLICAS": "5"
    }
  }'
```

### 3. Scale Deployments

```bash
# Scale up v2.0.0 (pipeline deployed)
kubectl scale deployment productapi-v2.0.0 --replicas=5

# Scale down old versions
kubectl scale deployment productapi-v1 --replicas=1
kubectl scale deployment productapi-v1-1 --replicas=0
```

### 4. Create Rollback Pipeline

```json
{
  "name": "Rollback to Previous Version",
  "stages": [
    {
      "name": "Scale Down New Version",
      "type": "scaleManifest",
      "replicas": 0
    },
    {
      "name": "Scale Up Old Version",
      "type": "scaleManifest",
      "replicas": 3
    }
  ]
}
```

### 5. Add More Pipeline Stages

```json
{
  "stages": [
    {"name": "Deploy to Staging", "type": "deployManifest"},
    {"name": "Run Integration Tests", "type": "webhook"},
    {"name": "Wait for Approval", "type": "manualJudgment"},
    {"name": "Deploy to Production", "type": "deployManifest"},
    {"name": "Send Slack Notification", "type": "slack"}
  ]
}
```

### 6. Enable Pipeline Triggers

```json
{
  "triggers": [
    {
      "type": "webhook",
      "source": "github",
      "enabled": true
    },
    {
      "type": "cron",
      "cronExpression": "0 0 2 * * ?",
      "enabled": true
    }
  ]
}
```

---

## Cleanup

### Remove Specific Version

```bash
# Delete v1.0.0
kubectl delete deployment productapi-v1

# Wait for cache refresh
sleep 35

# Verify in Spinnaker
curl -u admin:admin123 \
  http://localhost:8084/applications/productapi/serverGroups | jq
```

### Remove All ProductAPI Resources

```bash
# Delete all deployments
kubectl delete deployment -l app=productapi

# Delete service
kubectl delete service productapi

# Verify cleanup
kubectl get all -l app=productapi
```

### Delete Application from Spinnaker

```bash
curl -u admin:admin123 -X DELETE \
  http://localhost:8080/v2/applications/productapi
```

---

## Troubleshooting

### Resources Not Visible in Spinnaker

**Problem:** Deployed resources don't appear in Spinnaker UI.

**Solutions:**
1. Check annotations are present:
   ```bash
   kubectl get deployment productapi-v1 -o yaml | grep moniker
   ```

2. Wait for cache refresh (30 seconds):
   ```bash
   sleep 35
   ```

3. Force cache refresh:
   ```bash
   curl -u admin:admin123 -X POST \
     http://localhost:8084/cache/kubernetes/docker-desktop
   ```

### Pipeline Execution Fails

**Problem:** Pipeline fails at Deploy Manifest stage.

**Solutions:**
1. Check clouddriver logs:
   ```bash
   kubectl logs -n spinnaker deployment/spin-clouddriver --tail=100
   ```

2. Check parameter types (common issue):
   ```
   Error: "got string, expected integer"
   Solution: Use ${ #toInt( parameters.REPLICAS ) }
   ```

3. Verify Kubernetes account access:
   ```bash
   curl -u admin:admin123 http://localhost:8084/credentials
   ```

### Port Forwards Not Working

```bash
# Kill existing port forwards
pkill -f "port-forward"

# Restart port forwards
kubectl port-forward -n spinnaker svc/spin-deck 9000:9000 &
kubectl port-forward -n spinnaker svc/spin-gate 8084:8084 &
kubectl port-forward -n spinnaker svc/spin-front50 8080:8080 &
```

---

## Summary

### What Was Demonstrated

#### Part 1: kubectl-Based (Visibility)
✅ Application creation via Spinnaker API  
✅ Kubernetes resource discovery via annotations  
✅ Multi-version deployment (v1.0.0, v1.1.0)  
✅ Load balancer traffic distribution  
✅ Complete visibility in Spinnaker UI  

**Limitation:** Spinnaker acts as viewer only.

#### Part 2: Pipeline-Based (Orchestration)
✅ Pipeline creation with 3 stages  
✅ Parameterized deployment (VERSION, REPLICAS)  
✅ Expression language for type conversion  
✅ Automated workflow execution  
✅ Manual approval gate (production-ready)  
✅ Deployment via Spinnaker (v2.0.0 with 3 pods)  
✅ Complete audit trail  

**Achievement:** Spinnaker orchestrates entire deployment workflow.

### Key Insight

```
Spinnaker without pipelines = Kubernetes dashboard
Spinnaker with pipelines    = Enterprise CD platform
```

**Pipelines are Spinnaker's core value:**
- Deployment orchestration
- Automated multi-stage workflows
- Approval gates for governance
- Complete audit trails
- Production-ready continuous delivery

### Current State

- **3 versions running:** v1.0.0, v1.1.0, v2.0.0
- **7 pods total:** All healthy and serving traffic
- **1 LoadBalancer:** Distributing traffic across all versions
- **1 Pipeline:** "Deploy to Production" (paused at Manual Judgment)
- **Pipeline deployed:** v2.0.0 serving 50% of traffic

### Success Criteria

✅ **100% Success Rate**

- [x] Application created in Spinnaker
- [x] Kubernetes resources discovered (kubectl deployed)
- [x] Resources visible in Spinnaker UI
- [x] Pipeline created with multiple stages
- [x] Pipeline executed successfully
- [x] Deployment orchestrated by Spinnaker
- [x] Multi-version deployment working
- [x] Load balancer distributing traffic
- [x] Manual approval gate functioning
- [x] All pods healthy and running
- [x] Complete audit trail available

---

## References

### Documentation
- **Feature Guides:** [docs/features/](./features/)
- **API Collection:** [Spinnaker-API.postman_collection.json](../Spinnaker-API.postman_collection.json)
- **XL Release Integration:** [docs/spinnaker-integration.md](./spinnaker-integration.md)
- **Kubernetes Account Setup:** [docs/add-kubernetes-account.md](./add-kubernetes-account.md)

### Spinnaker Resources
- **Official Docs:** https://spinnaker.io/docs
- **Kubernetes Provider:** https://spinnaker.io/docs/setup/install/providers/kubernetes-v2
- **Pipeline Expressions:** https://spinnaker.io/docs/reference/pipeline/expressions

---

**Status:** ✅ Demo completed successfully - both visibility and orchestration demonstrated!
