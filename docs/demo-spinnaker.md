# Spinnaker End-to-End Demo: E-commerce Microservice Deployment

**Scenario:** Deploy a sample e-commerce microservice application with multiple versions using Spinnaker's full feature set through the UI and API.

**Duration:** 45-60 minutes  
**Difficulty:** Intermediate  
**Prerequisites:** 
- Spinnaker 1.33.0 running on Kubernetes
- Kubernetes cloud provider configured in Spinnaker
- Port forwards active (UI: 9000, API: 8084)
- `kubectl` access to the cluster

---

## 📋 Demo Overview

This demo showcases a complete deployment workflow for a fictional e-commerce "Product API" microservice using **Spinnaker-native operations** (not kubectl):

- **Application Management:** Create and configure application via Spinnaker
- **Load Balancers:** Deploy Kubernetes Services through Spinnaker
- **Server Groups:** Deploy multiple versions via Spinnaker deployments
- **Clusters:** Manage server groups across environments
- **Pipelines:** Automate deployment with blue/green strategy
- **Tasks & Executions:** Monitor deployment progress

**What You'll Deploy:**
- Application: `productapi`
- Load Balancer: `productapi-service` (Kubernetes Service)
- Server Groups: Multiple versions (v1.0.0, v1.1.0)
- Pipeline: Automated blue/green deployment
- Environments: Dev, Staging, Production

---

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Spinnaker Application                     │
│                        "productapi"                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Environment │  │ Environment │  │ Environment │        │
│  │    DEV      │  │   STAGING   │  │    PROD     │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         │                 │                 │               │
│  ┌──────▼──────┐   ┌─────▼──────┐   ┌─────▼──────┐        │
│  │   Cluster   │   │  Cluster   │   │  Cluster   │        │
│  │ productapi- │   │productapi- │   │productapi- │        │
│  │     dev     │   │   staging  │   │    prod    │        │
│  └──────┬──────┘   └─────┬──────┘   └─────┬──────┘        │
│         │                 │                 │               │
│  ┌──────▼──────┐   ┌─────▼──────┐   ┌─────▼──────┐        │
│  │Server Group │   │Server Group│   │Server Group│        │
│  │ v1.0.0 (3)  │   │ v1.0.0 (2) │   │ v1.1.0 (5) │        │
│  └─────────────┘   └────────────┘   └────────────┘        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Part 1: Prerequisites & Verification

### Step 1.1: Verify Spinnaker is Running

```bash
# Check Spinnaker services
kubectl get pods -n spinnaker

# Expected: All pods Running
# spin-clouddriver, spin-deck, spin-gate, spin-orca, spin-front50, spin-echo, spin-rosco
```

### Step 1.2: Verify Kubernetes Provider Configuration

```bash
# Check if Kubernetes cloud provider is configured
curl -s http://localhost:8084/credentials | jq '.'

# Expected output: List of cloud provider accounts
# Should include at least one kubernetes account
```

**If empty (`[]`), you need to configure Kubernetes provider first:**

#### Troubleshooting: Configure Kubernetes Provider

The Kubernetes provider must be configured in SpinnakerService before proceeding.

**Check Current Configuration:**
```bash
kubectl get spinsvc spinnaker -n spinnaker -o jsonpath='{.spec.spinnakerConfig.config.providers}' | jq '.'
```

**If providers.kubernetes is missing or disabled:**

1. **Backup current config:**
   ```bash
   kubectl get spinsvc spinnaker -n spinnaker -o yaml > spinnaker-backup.yaml
   ```

2. **Option A: Edit SpinnakerService directly (recommended):**
   ```bash
   kubectl edit spinsvc spinnaker -n spinnaker
   ```
   
   Add under `spec.spinnakerConfig.config.providers`:
   ```yaml
   providers:
     kubernetes:
       enabled: true
       accounts:
       - name: docker-desktop
         providerVersion: V2
         onlySpinnakerManaged: false
         kubeconfigFile: encryptedFile:k8s!n:spin-secrets!k:kubeconfig-docker-desktop
       primaryAccount: docker-desktop
   ```

3. **Option B: Use existing configuration file:**
   ```bash
   # If you have k8s/spinnaker/spinnakerservice.yaml with kubernetes provider configured
   kubectl apply -f k8s/spinnaker/spinnakerservice.yaml
   ```

4. **Wait for clouddriver to restart (2-3 minutes):**
   ```bash
   kubectl rollout status deployment/spin-clouddriver -n spinnaker --timeout=5m
   ```

5. **Verify credentials now available:**
   ```bash
   curl -s http://localhost:8084/credentials | jq '.[] | {name, type, cloudProvider}'
   ```

**Note:** If clouddriver fails to start, check logs:
```bash
kubectl logs -n spinnaker deployment/spin-clouddriver --tail=100
```

Common issues:
- Missing kubeconfig in secrets
- Service account permissions
- Invalid provider configuration format

### Step 1.3: Access Spinnaker UI

1. **Verify port forwards are active:**
   ```bash
   # UI (Deck)
   kubectl port-forward -n spinnaker svc/spin-deck 9000:9000 &
   
   # API (Gate)
   kubectl port-forward -n spinnaker svc/spin-gate 8084:8084 &
   ```

2. **Open Spinnaker UI:**
   - URL: http://localhost:9000
   - Login: admin / admin123 (if basic auth enabled)

---

## 🚀 Part 2: Create Application

### Step 2.1: Create Application via UI

1. **Navigate to Applications:**
   - Click "Applications" in top navigation
   - Click "Create Application" button

2. **Fill Application Details:**
   - **Name:** `productapi`
   - **Owner Email:** `demo@example.com`
   - **Description:** `E-commerce Product API Microservice`
   - **Cloud Providers:** Select `kubernetes`
   - **Repo Type:** (leave default or select Git)

3. **Click "Create"**

### Step 2.2: Create Application via API

```bash
curl -X POST http://localhost:8084/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "application": "productapi",
    "job": [{
      "type": "createApplication",
      "application": {
        "name": "productapi",
        "email": "demo@example.com",
        "description": "E-commerce Product API Microservice",
        "cloudProviders": "kubernetes"
      },
      "user": "demo@example.com"
    }]
  }'
```

**Monitor task:**
```bash
# Get task ID from response, then:
TASK_ID="01KE8..."
curl -s http://localhost:8084/tasks/${TASK_ID} | jq '.status'
```

**Verify application created:**
```bash
curl -s http://localhost:8084/applications/productapi | jq '.name, .attributes'
```

---

## 🌐 Part 3: Create Load Balancers (Kubernetes Services)

Spinnaker uses "Load Balancers" to represent Kubernetes Services that route traffic to Server Groups (Deployments).

### Step 3.1: Create Development Service via UI

1. **Navigate to Application:**
   - Click "Applications" → "productapi"
   - Click "LOAD BALANCERS" tab

2. **Create Load Balancer:**
   - Click "Create Load Balancer"
   - **Account:** Select your Kubernetes account (e.g., `docker-desktop`)
   - **Namespace:** `default`
   - **Stack:** `dev`
   - **Detail:** (leave empty)
   - **Service Type:** `ClusterIP`
   - **Port:**
     - Protocol: `TCP`
     - Port: `80`
     - Target Port: `80`
   - **Selector:**
     - `app`: `productapi`
     - `env`: `dev`

3. **Click "Create"**

### Step 3.2: Create Production Service via UI

Repeat above with:
- **Stack:** `prod`
- **Service Type:** `LoadBalancer`
- **Selector:**
  - `app`: `productapi`
  - `env`: `prod`

### Step 3.3: Create Services via API (Spinnaker Tasks)

**Development Service:**
```bash
curl -X POST http://localhost:8084/applications/productapi/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "job": [{
      "cloudProvider": "kubernetes",
      "type": "upsertLoadBalancer",
      "account": "docker-desktop",
      "namespace": "default",
      "loadBalancerName": "productapi-dev",
      "serviceType": "ClusterIP",
      "selector": {
        "app": "productapi",
        "env": "dev"
      },
      "ports": [{
        "protocol": "TCP",
        "port": 80,
        "targetPort": 80,
        "name": "http"
      }]
    }],
    "application": "productapi",
    "description": "Create dev load balancer"
  }'
```

**Production Service:**
```bash
curl -X POST http://localhost:8084/applications/productapi/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "job": [{
      "cloudProvider": "kubernetes",
      "type": "upsertLoadBalancer",
      "account": "docker-desktop",
      "namespace": "default",
      "loadBalancerName": "productapi-prod",
      "serviceType": "LoadBalancer",
      "selector": {
        "app": "productapi",
        "env": "prod"
      },
      "ports": [{
        "protocol": "TCP",
        "port": 80,
        "targetPort": 80,
        "name": "http"
      }]
    }],
    "application": "productapi",
    "description": "Create prod load balancer"
  }'
```

**Verify services created:**
```bash
kubectl get services -l app=productapi
```

---

## 📦 Part 4: Deploy Server Groups (Deployments)

Server Groups in Spinnaker represent Kubernetes Deployments/ReplicaSets.

### Step 4.1: Deploy v1.0.0 to Development via UI

1. **Navigate to Clusters:**
   - Click "CLUSTERS" tab
   - Click "Create Server Group"

2. **Configure Deployment:**
   - **Account:** `docker-desktop`
   - **Namespace:** `default`
   - **Stack:** `dev`
   - **Detail:** (leave empty or use `v100`)
   - **Containers:**
     - **Image:** `nginx:1.21-alpine`
     - **Name:** `productapi`
     - **Ports:** 
       - Container Port: `80`
       - Protocol: `TCP`
   - **Replicas:** `3`
   - **Labels:**
     - `app`: `productapi`
     - `env`: `dev`
     - `version`: `v1.0.0`
   - **Resource Limits:**
     - CPU: `100m` / `200m`
     - Memory: `128Mi` / `256Mi`

3. **Click "Create"**

### Step 4.2: Deploy v1.0.0 to Production via UI

Repeat above with:
- **Stack:** `prod`
- **Replicas:** `5`
- **Labels:**
  - `app`: `productapi`
  - `env`: `prod`
  - `version`: `v1.0.0`

### Step 4.3: Deploy Server Groups via API

**Development Deployment:**
```bash
curl -X POST http://localhost:8084/applications/productapi/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "job": [{
      "cloudProvider": "kubernetes",
      "type": "createServerGroup",
      "account": "docker-desktop",
      "application": "productapi",
      "stack": "dev",
      "freeFormDetails": "v100",
      "region": "default",
      "namespace": "default",
      "targetSize": 3,
      "containers": [{
        "name": "productapi",
        "imageDescription": {
          "repository": "nginx",
          "tag": "1.21-alpine",
          "registry": "index.docker.io"
        },
        "ports": [{
          "containerPort": 80,
          "protocol": "TCP",
          "name": "http"
        }],
        "resources": {
          "requests": {"cpu": "100m", "memory": "128Mi"},
          "limits": {"cpu": "200m", "memory": "256Mi"}
        },
        "livenessProbe": {
          "httpGet": {"path": "/", "port": 80},
          "initialDelaySeconds": 10,
          "periodSeconds": 10
        },
        "readinessProbe": {
          "httpGet": {"path": "/", "port": 80},
          "initialDelaySeconds": 5,
          "periodSeconds": 5
        }
      }],
      "labels": {
        "app": "productapi",
        "env": "dev",
        "version": "v1.0.0"
      },
      "loadBalancers": ["productapi-dev"]
    }],
    "application": "productapi",
    "description": "Deploy v1.0.0 to dev"
  }'
```

**Production Deployment:**
```bash
curl -X POST http://localhost:8084/applications/productapi/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "job": [{
      "cloudProvider": "kubernetes",
      "type": "createServerGroup",
      "account": "docker-desktop",
      "application": "productapi",
      "stack": "prod",
      "freeFormDetails": "v100",
      "region": "default",
      "namespace": "default",
      "targetSize": 5,
      "containers": [{
        "name": "productapi",
        "imageDescription": {
          "repository": "nginx",
          "tag": "1.21-alpine",
          "registry": "index.docker.io"
        },
        "ports": [{
          "containerPort": 80,
          "protocol": "TCP",
          "name": "http"
        }],
        "resources": {
          "requests": {"cpu": "100m", "memory": "128Mi"},
          "limits": {"cpu": "200m", "memory": "256Mi"}
        }
      }],
      "labels": {
        "app": "productapi",
        "env": "prod",
        "version": "v1.0.0"
      },
      "loadBalancers": ["productapi-prod"]
    }],
    "application": "productapi",
    "description": "Deploy v1.0.0 to prod"
  }'
```

**Monitor deployment progress:**
```bash
# Via Spinnaker UI: TASKS tab shows real-time progress
# Via kubectl:
kubectl get deployments -l app=productapi
kubectl get pods -l app=productapi
```

**Verify pods ready:**
```bash
kubectl wait --for=condition=ready pod -l app=productapi --timeout=120s
```

---

## 🔄 Part 5: Blue/Green Deployment (Deploy New Version)

### Step 5.1: Deploy v1.1.0 via UI

1. **Navigate to Clusters:**
   - Find `productapi-prod-v100` server group
   - Click the 3-dot menu → "Clone Server Group"

2. **Modify Configuration:**
   - **Detail:** `v110`
   - **Image Tag:** `nginx:1.22-alpine`
   - **Labels:** Update `version` to `v1.1.0`
   - **Replicas:** `5`

3. **Strategy:** Select "None" (both versions will run simultaneously)

4. **Click "Create"**

**Result:** Now you have two server groups running:
- `productapi-prod-v100` (5 replicas) - OLD (Blue)
- `productapi-prod-v110` (5 replicas) - NEW (Green)

### Step 5.2: Test Both Versions Running

```bash
# Both versions should be running
kubectl get deployments -l app=productapi,env=prod

# Test traffic distribution (service routes to both)
for i in {1..10}; do
  kubectl run test-curl-$i --image=curlimages/curl --rm -i --restart=Never -- \
    curl -s http://productapi-prod.default.svc.cluster.local/ | grep -o "v1\.[0-1]\.0"
done
```

### Step 5.3: Cutover Traffic to New Version

**Option A: Via UI:**
1. Go to Load Balancer `productapi-prod`
2. Edit selector to point only to `version: v1.1.0`

**Option B: Via kubectl (direct Service patch):**
```bash
kubectl patch svc productapi-prod -n default --type='json' \
  -p='[{"op": "replace", "path": "/spec/selector", "value": {"app": "productapi", "env": "prod", "version": "v1.1.0"}}]'
```

**Verify cutover:**
```bash
# All requests should now go to v1.1.0
for i in {1..5}; do
  kubectl run test-verify-$i --image=curlimages/curl --rm -i --restart=Never -- \
    curl -s http://productapi-prod.default.svc.cluster.local/ | grep -o "v1\.1\.0"
done
```

### Step 5.4: Disable Old Version

**Via UI:**
1. Navigate to Clusters → `productapi-prod-v100`
2. Click "Server Group Actions" → "Disable"

**Via API:**
```bash
curl -X POST http://localhost:8084/applications/productapi/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "job": [{
      "cloudProvider": "kubernetes",
      "type": "disableServerGroup",
      "account": "docker-desktop",
      "serverGroupName": "productapi-prod-v100",
      "region": "default",
      "namespace": "default"
    }],
    "application": "productapi",
    "description": "Disable old version after cutover"
  }'
```

**Or scale down directly:**
```bash
kubectl scale deployment productapi-prod-v100 -n default --replicas=0
```

**Verify:**
```bash
kubectl get deployments -l app=productapi,env=prod
# Expected: v100 shows 0/0, v110 shows 5/5
```

---

## 🎭 Part 6: Create Automated Pipeline

Automate the blue/green deployment process with a pipeline.

### Step 6.1: Create Pipeline via UI

1. **Navigate to Pipelines:**
   - Click "PIPELINES" tab
   - Click "Configure a new pipeline"

2. **Pipeline Configuration:**
   - **Name:** `Deploy to Production`
   - **Type:** `Pipeline`

3. **Add Stages:**

   **Stage 1: Deploy New Version**
   - **Type:** Deploy
   - **Account:** `docker-desktop`
   - **Namespace:** `default`
   - **Strategy:** Red/Black (Blue/Green)
   - **Server Group:** Clone from `productapi-prod-*`
   - **Image:** `nginx:1.22-alpine`
   - **Replicas:** `5`

   **Stage 2: Manual Judgment**
   - **Type:** Manual Judgment
   - **Instructions:** "Verify new version is healthy before proceeding"
   - **Judgments:** `Continue`, `Rollback`

   **Stage 3: Disable Old Version**
   - **Type:** Disable Server Group
   - **Target:** Previous server group
   - **Condition:** Only if Manual Judgment = "Continue"

   **Stage 4: Destroy Old Version** (Optional)
   - **Type:** Destroy Server Group
   - **Target:** Previous server group
   - **Wait:** 30 minutes
   - **Condition:** Only after Stage 3 succeeds

4. **Save Pipeline**

### Step 6.2: Trigger Pipeline

**Manual Trigger:**
- Click "Start Manual Execution"
- Monitor progress in Execution Details

**Watch execution:**
```bash
# Via UI: PIPELINES → Executions
# Or via API:
curl -s http://localhost:8084/applications/productapi/pipelines | jq '.'
```

---

## 🔍 Part 7: Monitor and Verify

### Step 7.1: View Infrastructure in Spinnaker UI

1. **Clusters Tab:**
   - Shows all server groups organized by cluster
   - View instance counts, health status
   - See load balancer associations

2. **Load Balancers Tab:**
   - Lists all Kubernetes Services
   - Shows attached server groups
   - View service endpoints

3. **Tasks Tab:**
   - Real-time task execution logs
   - View operation history
   - Monitor deployment progress

### Step 7.2: View via API

**List clusters:**
```bash
curl -s http://localhost:8084/applications/productapi/clusters | jq '.[] | {account, name, serverGroups: .serverGroups[].name}'
```

**List load balancers:**
```bash
curl -s http://localhost:8084/applications/productapi/loadBalancers | jq '.[] | {account, name, region, serverGroups}'
```

**List server groups:**
```bash
curl -s http://localhost:8084/applications/productapi/serverGroups | jq '.[] | {account, name, region, instances: .instances | length, disabled}'
```

### Step 7.3: Verify Kubernetes Resources

```bash
# Services
kubectl get services -l app=productapi

# Deployments
kubectl get deployments -l app=productapi

# Pods
kubectl get pods -l app=productapi -o wide

# Test production service
kubectl run test-final --image=curlimages/curl --rm -i --restart=Never -- \
  curl -s http://productapi-prod.default.svc.cluster.local/
```

---

## 🔧 Part 8: Rollback Scenario

### Scenario: New version has issues, need to rollback

**Step 1: Enable old version:**

**Via UI:**
- Clusters → Find disabled `productapi-prod-v100`
- Click "Enable Server Group"

**Via API:**
```bash
curl -X POST http://localhost:8084/applications/productapi/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "job": [{
      "cloudProvider": "kubernetes",
      "type": "enableServerGroup",
      "account": "docker-desktop",
      "serverGroupName": "productapi-prod-v100",
      "region": "default",
      "namespace": "default"
    }],
    "application": "productapi",
    "description": "Rollback: Enable v1.0.0"
  }'
```

**Step 2: Update load balancer to point to old version:**

```bash
kubectl patch svc productapi-prod -n default --type='json' \
  -p='[{"op": "replace", "path": "/spec/selector", "value": {"app": "productapi", "env": "prod", "version": "v1.0.0"}}]'
```

**Step 3: Disable new version:**

```bash
curl -X POST http://localhost:8084/applications/productapi/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "job": [{
      "cloudProvider": "kubernetes",
      "type": "disableServerGroup",
      "account": "docker-desktop",
      "serverGroupName": "productapi-prod-v110",
      "region": "default",
      "namespace": "default"
    }],
    "application": "productapi",
    "description": "Rollback: Disable v1.1.0"
  }'
```

**Verify rollback:**
```bash
kubectl get deployments -l app=productapi,env=prod
# Expected: v100 active, v110 scaled to 0
```

---

## 🧹 Part 9: Cleanup

### Option A: Delete via Spinnaker UI

1. **Delete Server Groups:**
   - Clusters → Each server group → "Destroy Server Group"

2. **Delete Load Balancers:**
   - Load Balancers → Each LB → "Delete Load Balancer"

3. **Delete Application:**
   - Applications → productapi → Actions → "Delete Application"

### Option B: Delete via API

```bash
# Delete server groups
for sg in productapi-dev-v100 productapi-prod-v100 productapi-prod-v110; do
  curl -X POST http://localhost:8084/applications/productapi/tasks \
    -H 'Content-Type: application/json' \
    -d "{
      \"job\": [{
        \"cloudProvider\": \"kubernetes\",
        \"type\": \"destroyServerGroup\",
        \"account\": \"docker-desktop\",
        \"serverGroupName\": \"$sg\",
        \"region\": \"default\",
        \"namespace\": \"default\"
      }],
      \"application\": \"productapi\",
      \"description\": \"Cleanup: Delete $sg\"
    }"
  sleep 5
done

# Delete load balancers
for lb in productapi-dev productapi-prod; do
  curl -X POST http://localhost:8084/applications/productapi/tasks \
    -H 'Content-Type: application/json' \
    -d "{
      \"job\": [{
        \"cloudProvider\": \"kubernetes\",
        \"type\": \"deleteLoadBalancer\",
        \"account\": \"docker-desktop\",
        \"loadBalancerName\": \"$lb\",
        \"region\": \"default\",
        \"namespace\": \"default\"
      }],
      \"application\": \"productapi\",
      \"description\": \"Cleanup: Delete $lb\"
    }"
  sleep 5
done
```

### Option C: Quick cleanup via kubectl

```bash
kubectl delete deployments,services -n default -l app=productapi
```

---

## 📊 Part 10: Demo Summary

### What You Accomplished:

✅ **Application Management**
- Created application in Spinnaker
- Configured cloud provider integration

✅ **Load Balancers**
- Deployed Kubernetes Services via Spinnaker
- Configured traffic routing with selectors

✅ **Server Groups & Clusters**
- Deployed multiple versions to different environments
- Managed replica scaling
- Organized by logical clusters

✅ **Blue/Green Deployment**
- Deployed new version alongside old
- Tested both versions simultaneously
- Performed zero-downtime cutover
- Disabled old version while preserving for rollback

✅ **Automation**
- Created automated pipeline
- Added manual approval gates
- Configured deployment strategies

✅ **Monitoring & Operations**
- Monitored tasks and executions
- Viewed infrastructure topology
- Performed rollback scenario

### Key Spinnaker Concepts Demonstrated:

1. **Applications** - Logical grouping of resources
2. **Clusters** - Collections of server groups
3. **Server Groups** - Immutable deployment units (Kubernetes Deployments)
4. **Load Balancers** - Traffic routing (Kubernetes Services)
5. **Pipelines** - Automated deployment workflows
6. **Tasks** - Individual operations tracked and monitored
7. **Strategies** - Blue/Green, Rolling, Canary deployment patterns

---

## 🐛 Troubleshooting Guide

### Issue: Empty credentials list

**Problem:** `curl http://localhost:8084/credentials` returns `[]`

**Solution:** Kubernetes cloud provider not configured. See "Part 1: Prerequisites & Verification" → Step 1.2

---

### Issue: Clouddriver won't start after config change

**Check logs:**
```bash
kubectl logs -n spinnaker deployment/spin-clouddriver --tail=100
```

**Common causes:**
- Invalid kubeconfig reference
- Missing service account
- Configuration syntax errors

**Fix:**
```bash
# Rollback to previous config
kubectl apply -f spinnaker-backup.yaml

# Or delete failing pod to retry
kubectl delete pod -n spinnaker -l cluster=spin-clouddriver
```

---

### Issue: Server group deployment fails

**Check task details:**
- UI: Tasks tab → Click failing task → View Exception
- API: `curl http://localhost:8084/tasks/{taskId}`

**Common causes:**
- Invalid image name/tag
- Insufficient cluster resources
- Invalid manifest syntax

---

### Issue: Load balancer not routing traffic

**Verify selector matches:**
```bash
# Get service selector
kubectl get svc productapi-prod -o jsonpath='{.spec.selector}'

# Get pod labels
kubectl get pods -l app=productapi --show-labels
```

**Fix:** Update service selector or pod labels to match

---

## 📚 Next Steps

1. **Explore Advanced Pipelines:**
   - Add automated testing stages
   - Implement canary deployments
   - Configure webhooks for CI/CD integration

2. **Integrate with CI Tools:**
   - Connect Jenkins triggers
   - Use GitHub webhooks
   - Automate artifact promotion

3. **Implement Monitoring:**
   - Add Prometheus metrics
   - Configure Kayenta for automated canary analysis
   - Set up alerting

4. **Security & Governance:**
   - Configure RBAC
   - Add manual approval gates
   - Implement deployment windows

---

## 📖 References

- [Spinnaker Applications Guide](features/01-applications.md)
- [Spinnaker Pipelines Guide](features/02-pipelines.md)
- [Spinnaker Tasks & Executions](features/03-tasks-executions.md)
- [Clusters & Server Groups](features/04-clusters-servergroups.md)
- [Load Balancers Guide](features/05-loadbalancers.md)
- [XL Release Integration Tasks](spinnaker-integration.md)
- [Spinnaker API Collection](../Spinnaker-API.postman_collection.json)

---

**Demo Complete! 🎉**

You've successfully deployed a microservice through Spinnaker using UI and API, demonstrated blue/green deployment, and learned key Spinnaker concepts for production-grade continuous delivery.
