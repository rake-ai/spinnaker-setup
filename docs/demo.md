# Spinnaker End-to-End Demo: E-commerce Microservice Deployment

**Scenario:** Deploy a sample e-commerce microservice application with multiple versions using Spinnaker's full feature set.

**Duration:** 45-60 minutes  
**Difficulty:** Intermediate  
**Prerequisites:** Spinnaker 1.33.0 running on Kubernetes with port forwards active

---

## 📋 Demo Overview

This demo showcases a complete deployment workflow for a fictional e-commerce "Product API" microservice:

- **Application Management:** Create and configure application
- **Projects:** Organize related applications (optional)
- **Load Balancers:** Set up Kubernetes Service for traffic routing
- **Server Groups:** Deploy multiple versions of the application
- **Clusters:** Manage server groups across environments
- **Pipelines:** Automate deployment with blue/green strategy

**What You'll Deploy:**
- Application: `productapi`
- Load Balancer: `productapi-service` (Kubernetes Service)
- Server Groups: Multiple versions (v1.0.0, v1.1.0, v2.0.0)
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
│  │Load Balancer│   │Load Balancer│  │Load Balancer│       │
│  │productapi-  │   │productapi-  │   │productapi-  │       │
│  │ dev-service │   │staging-svc  │   │ prod-svc    │       │
│  └──────┬──────┘   └─────┬──────┘   └─────┬──────┘        │
│         │                 │                 │               │
│  ┌──────▼──────┐   ┌─────▼──────┐   ┌─────▼──────┐        │
│  │Server Groups│   │Server Groups│  │Server Groups│       │
│  │  v1.0.0     │   │  v1.1.0     │   │  v1.1.0     │       │
│  │  (3 pods)   │   │  (5 pods)   │   │ (10 pods)   │       │
│  │             │   │             │   │  v2.0.0     │       │
│  │             │   │             │   │  (disabled) │       │
│  └─────────────┘   └─────────────┘   └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Part 1: Application Setup (15 minutes)

### Step 1.1: Create the Application

**Via UI:**

1. Navigate to http://localhost:9000
2. Click **Applications** in top navigation
3. Click **Actions** → **Create Application**
4. Fill in the form:
   ```
   Name: productapi
   Owner Email: demo@example.com
   Description: E-commerce Product API Microservice
   Consider only cloud provider health when executing tasks: ✓
   ```
5. **Cloud Providers:** Check **kubernetes**
6. **Instance Health:** 
   - Consider only cloud provider health: ✓
7. Click **Create**

**Via API (Alternative):**

```bash
curl -X POST http://localhost:8084/tasks \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "createApplication",
      "application": {
        "name": "productapi",
        "email": "demo@example.com",
        "description": "E-commerce Product API Microservice",
        "cloudProviders": "kubernetes",
        "instancePort": 8080,
        "platformHealthOnly": true,
        "platformHealthOnlyShowOverride": false
      },
      "user": "admin"
    }],
    "application": "productapi",
    "description": "Create application: productapi"
  }'
```

**Verify:**
```bash
# Check application was created
curl -u admin:admin123 http://localhost:8084/applications/productapi | jq .

# Expected output: Application details with name "productapi"
```

---

### Step 1.2: Configure Application Attributes

**Via UI:**

1. Go to **Applications** → **productapi**
2. Click **Config** tab
3. Under **Application Attributes**, click **Edit**
4. Add custom attributes:
   ```
   Repository URL: https://github.com/example/productapi
   Team: Platform Engineering
   Cost Center: CC-1234
   Slack Channel: #productapi-alerts
   ```
5. **Notifications** (optional):
   - Add notification preferences for pipeline events
6. Click **Save Changes**

---

### Step 1.3: Create Project (Optional)

Projects help organize related applications.

**Via UI:**

1. Click **Projects** in top navigation
2. Click **Create Project**
3. Fill in:
   ```
   Name: ecommerce-platform
   Email: platform-team@example.com
   ```
4. Under **Applications**, add:
   - `productapi`
5. Under **Clusters**, you can define cluster groupings
6. Click **Create**

**Note:** Projects are organizational containers and don't affect deployment behavior.

---

## 🌐 Part 2: Load Balancer Setup (10 minutes)

### Step 2.1: Create Development Load Balancer

**Via UI:**

1. Go to **Applications** → **productapi**
2. Click **Load Balancers** tab
3. Click **Create Load Balancer**
4. Select **kubernetes** provider
5. Switch to **Text** tab (easier for this demo)
6. Paste the following manifest:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: productapi-dev-service
  namespace: default
  labels:
    app: productapi
    env: dev
  annotations:
    spinnaker.io/application: productapi
    spinnaker.io/stack: dev
spec:
  type: ClusterIP
  selector:
    app: productapi
    env: dev
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8080
  - name: metrics
    protocol: TCP
    port: 9090
    targetPort: 9090
```

7. Click **Create**
8. Wait for task to complete (check **Tasks** tab)

**Via API (Alternative):**

```bash
curl -X POST http://localhost:8084/tasks \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "deployManifest",
      "account": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "manifestArtifactId": "",
      "moniker": {
        "app": "productapi",
        "stack": "dev"
      },
      "source": "text",
      "manifests": [{
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
          "name": "productapi-dev-service",
          "namespace": "default",
          "labels": {
            "app": "productapi",
            "env": "dev"
          }
        },
        "spec": {
          "type": "ClusterIP",
          "selector": {
            "app": "productapi",
            "env": "dev"
          },
          "ports": [
            {"name": "http", "protocol": "TCP", "port": 80, "targetPort": 8080},
            {"name": "metrics", "protocol": "TCP", "port": 9090, "targetPort": 9090}
          ]
        }
      }]
    }],
    "application": "productapi",
    "description": "Create load balancer: productapi-dev-service"
  }'
```

**Verify:**

```bash
# Check load balancer in Spinnaker
curl -u admin:admin123 \
  "http://localhost:8084/applications/productapi/loadBalancers" | jq .

# Check in Kubernetes
kubectl get svc -n default | grep productapi-dev
```

---

### Step 2.2: Create Staging and Production Load Balancers

Repeat Step 2.1 for staging and production environments:

**Staging Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: productapi-staging-service
  namespace: default
  labels:
    app: productapi
    env: staging
spec:
  type: NodePort
  selector:
    app: productapi
    env: staging
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8080
    nodePort: 30080  # External access for testing
```

**Production Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: productapi-prod-service
  namespace: default
  labels:
    app: productapi
    env: prod
spec:
  type: LoadBalancer
  selector:
    app: productapi
    env: prod
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8080
  - name: https
    protocol: TCP
    port: 443
    targetPort: 8443
```

**Quick API Script to Create All Three:**

```bash
#!/bin/bash
# create-all-loadbalancers.sh

ENVS=("dev" "staging" "prod")
TYPES=("ClusterIP" "NodePort" "LoadBalancer")

for i in "${!ENVS[@]}"; do
  ENV="${ENVS[$i]}"
  TYPE="${TYPES[$i]}"
  
  echo "Creating $ENV load balancer..."
  
  curl -X POST http://localhost:8084/tasks \
    -u admin:admin123 \
    -H "Content-Type: application/json" \
    -d "{
      \"job\": [{
        \"type\": \"deployManifest\",
        \"account\": \"my-k8s-account\",
        \"cloudProvider\": \"kubernetes\",
        \"source\": \"text\",
        \"manifests\": [{
          \"apiVersion\": \"v1\",
          \"kind\": \"Service\",
          \"metadata\": {
            \"name\": \"productapi-${ENV}-service\",
            \"namespace\": \"default\",
            \"labels\": {
              \"app\": \"productapi\",
              \"env\": \"${ENV}\"
            }
          },
          \"spec\": {
            \"type\": \"${TYPE}\",
            \"selector\": {
              \"app\": \"productapi\",
              \"env\": \"${ENV}\"
            },
            \"ports\": [{
              \"name\": \"http\",
              \"protocol\": \"TCP\",
              \"port\": 80,
              \"targetPort\": 8080
            }]
          }
        }]
      }],
      \"application\": \"productapi\",
      \"description\": \"Create load balancer: productapi-${ENV}-service\"
    }"
  
  echo ""
  sleep 2
done

echo "All load balancers created!"
```

---

## 🖥️ Part 3: Deploy Server Groups (15 minutes)

### Step 3.1: Deploy First Version to Dev (v1.0.0)

**Via UI:**

1. Go to **Applications** → **productapi**
2. Click **Clusters** tab
3. Click **Create Server Group**
4. Select **kubernetes** provider
5. Configure:
   ```
   Account: my-k8s-account
   Namespace: default
   Stack: dev
   Detail: (leave empty)
   ```
6. Switch to **Text** tab
7. Paste this manifest:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productapi-dev-v100
  namespace: default
  labels:
    app: productapi
    env: dev
    version: v1.0.0
  annotations:
    moniker.spinnaker.io/application: productapi
    moniker.spinnaker.io/cluster: productapi-dev
    moniker.spinnaker.io/stack: dev
spec:
  replicas: 3
  selector:
    matchLabels:
      app: productapi
      env: dev
  template:
    metadata:
      labels:
        app: productapi
        env: dev
        version: v1.0.0
    spec:
      containers:
      - name: productapi
        image: nginx:1.21  # Using nginx as a placeholder
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: metrics
        env:
        - name: APP_VERSION
          value: "1.0.0"
        - name: ENVIRONMENT
          value: "dev"
        - name: PORT
          value: "8080"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

8. Click **Create**
9. Monitor deployment in **Tasks** tab

**Via API (Alternative):**

```bash
curl -X POST http://localhost:8084/tasks \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "deployManifest",
      "account": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "source": "text",
      "moniker": {
        "app": "productapi",
        "cluster": "productapi-dev",
        "stack": "dev"
      },
      "manifests": [{
        "apiVersion": "apps/v1",
        "kind": "Deployment",
        "metadata": {
          "name": "productapi-dev-v100",
          "namespace": "default",
          "labels": {
            "app": "productapi",
            "env": "dev",
            "version": "v1.0.0"
          }
        },
        "spec": {
          "replicas": 3,
          "selector": {
            "matchLabels": {
              "app": "productapi",
              "env": "dev"
            }
          },
          "template": {
            "metadata": {
              "labels": {
                "app": "productapi",
                "env": "dev",
                "version": "v1.0.0"
              }
            },
            "spec": {
              "containers": [{
                "name": "productapi",
                "image": "nginx:1.21",
                "ports": [
                  {"containerPort": 8080, "name": "http"},
                  {"containerPort": 9090, "name": "metrics"}
                ],
                "env": [
                  {"name": "APP_VERSION", "value": "1.0.0"},
                  {"name": "ENVIRONMENT", "value": "dev"}
                ],
                "resources": {
                  "requests": {"memory": "128Mi", "cpu": "100m"},
                  "limits": {"memory": "256Mi", "cpu": "200m"}
                }
              }]
            }
          }
        }
      }]
    }],
    "application": "productapi",
    "description": "Deploy server group: productapi-dev-v100"
  }' | jq -r '.ref'
```

**Verify Deployment:**

```bash
# Check in Spinnaker
curl -u admin:admin123 \
  "http://localhost:8084/applications/productapi/clusters" | jq .

# Check in Kubernetes
kubectl get deployments -n default | grep productapi
kubectl get pods -n default | grep productapi

# Check cluster view
curl -u admin:admin123 \
  "http://localhost:8084/applications/productapi/serverGroups" | jq .
```

**Expected Output:**
- Cluster: `productapi-dev`
- Server Group: `productapi-dev-v100`
- Instances: 3 pods running

---

### Step 3.2: View Cluster Organization

**Via UI:**

1. Go to **Clusters** tab
2. You should see:
   ```
   Cluster: productapi-dev
   ├── Server Group: productapi-dev-v100
   │   ├── Instance: productapi-dev-v100-xxxxx (Running)
   │   ├── Instance: productapi-dev-v100-yyyyy (Running)
   │   └── Instance: productapi-dev-v100-zzzzz (Running)
   └── Load Balancers:
       └── productapi-dev-service
   ```

**Cluster Explanation:**
- **Cluster** = Logical grouping of server groups (e.g., `productapi-dev`)
- **Server Group** = Specific deployment version (e.g., `productapi-dev-v100`)
- **Instances** = Individual pods in the server group

---

### Step 3.3: Test the Deployment

```bash
# Get the service cluster IP
SERVICE_IP=$(kubectl get svc productapi-dev-service -n default -o jsonpath='{.spec.clusterIP}')
echo "Service IP: $SERVICE_IP"

# Test from within the cluster (create a test pod)
kubectl run test-curl --image=curlimages/curl -i --rm --restart=Never -- \
  curl -s http://$SERVICE_IP/

# Or port-forward to test locally
kubectl port-forward svc/productapi-dev-service 8080:80 &
curl http://localhost:8080/

# Clean up port-forward
pkill -f "port-forward svc/productapi-dev-service"
```

---

## 🔄 Part 4: Create Deployment Pipeline (20 minutes)

### Step 4.1: Create Blue/Green Deployment Pipeline

**Via UI:**

1. Go to **Applications** → **productapi**
2. Click **Pipelines** tab
3. Click **Create** (or **Configure a new pipeline**)
4. Enter:
   ```
   Pipeline Name: Deploy to Production
   Type: Pipeline
   ```
5. Click **Create**

---

### Step 4.2: Configure Pipeline Parameters

1. In **Configuration** section, add **Parameters**:

   **Parameter 1:**
   ```
   Name: version
   Label: Application Version
   Description: Version to deploy (e.g., v1.1.0)
   Default Value: v1.0.0
   ```

   **Parameter 2:**
   ```
   Name: replicaCount
   Label: Replica Count
   Description: Number of instances
   Default Value: 5
   ```

   **Parameter 3:**
   ```
   Name: imageTag
   Label: Docker Image Tag
   Description: Docker image tag
   Default Value: 1.21
   ```

---

### Step 4.3: Add Pipeline Stages

#### **Stage 1: Find Existing Server Group (Preparation)**

1. Click **Add stage**
2. Select **Find Image From Cluster**
3. Configure:
   ```
   Stage Name: Find Current Version
   Account: my-k8s-account
   Cluster: productapi-prod
   Namespace: default
   Server Group Selection: Newest
   ```
4. This stage identifies the current production version

#### **Stage 2: Deploy New Version (Blue)**

1. Click **Add stage**
2. Select **Deploy (Manifest)**
3. Configure:
   ```
   Stage Name: Deploy New Version
   Account: my-k8s-account
   ```
4. Under **Manifest Source**, select **Text**
5. Paste manifest (using parameters):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productapi-prod-v${parameters.version.replace(".", "")}
  namespace: default
  labels:
    app: productapi
    env: prod
    version: ${parameters.version}
  annotations:
    moniker.spinnaker.io/application: productapi
    moniker.spinnaker.io/cluster: productapi-prod
    moniker.spinnaker.io/stack: prod
spec:
  replicas: ${parameters.replicaCount}
  selector:
    matchLabels:
      app: productapi
      env: prod
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: productapi
        env: prod
        version: ${parameters.version}
    spec:
      containers:
      - name: productapi
        image: nginx:${parameters.imageTag}
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: metrics
        env:
        - name: APP_VERSION
          value: "${parameters.version}"
        - name: ENVIRONMENT
          value: "prod"
        - name: REPLICAS
          value: "${parameters.replicaCount}"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 5
          failureThreshold: 3
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
```

#### **Stage 3: Wait for New Version to Stabilize**

1. Click **Add stage**
2. Select **Wait**
3. Configure:
   ```
   Stage Name: Stabilization Wait
   Wait time: 300 seconds (5 minutes)
   Skip Wait Text: Skip wait - new version stable
   ```

#### **Stage 4: Manual Judgment (Quality Gate)**

1. Click **Add stage**
2. Select **Manual Judgment**
3. Configure:
   ```
   Stage Name: Approve New Version
   Instructions: Review new version health and metrics before proceeding.
   
   Judgment Inputs:
   - Continue (green) - New version is healthy
   - Rollback (red) - Issues detected, rollback
   ```

#### **Stage 5: Disable Old Version (Complete Cutover)**

1. Click **Add stage**
2. Select **Disable Server Group**
3. Configure:
   ```
   Stage Name: Disable Old Version
   Account: my-k8s-account
   Cluster: productapi-prod
   Namespace: default
   Target: Previous Server Group
   ```
4. Under **Conditional on Expression**, add:
   ```
   ${#judgment("Approve New Version") == "Continue"}
   ```

#### **Stage 6: Destroy Old Version (Cleanup)**

1. Click **Add stage**
2. Select **Destroy Server Group**
3. Configure:
   ```
   Stage Name: Cleanup Old Version
   Account: my-k8s-account
   Cluster: productapi-prod
   Namespace: default
   Target: Oldest Disabled Server Group
   ```
4. Under **Conditional on Expression**, add:
   ```
   ${#judgment("Approve New Version") == "Continue"}
   ```

#### **Stage 7 (Conditional): Rollback on Rejection**

1. Click **Add stage**
2. Select **Delete (Manifest)**
3. Configure:
   ```
   Stage Name: Rollback - Delete New Version
   Account: my-k8s-account
   Location: default
   ```
4. Under **Manifest**, select **Dynamic**
5. Under **Conditional on Expression**, add:
   ```
   ${#judgment("Approve New Version") == "Rollback"}
   ```

---

### Step 4.4: Save and Validate Pipeline

1. Click **Save Changes**
2. Review pipeline visualization
3. Expected flow:
   ```
   Start
     ↓
   [Find Current Version]
     ↓
   [Deploy New Version]
     ↓
   [Stabilization Wait]
     ↓
   [Manual Judgment: Approve?]
     ├─ Continue ──→ [Disable Old] → [Cleanup Old] → Success
     └─ Rollback ──→ [Delete New Version] → End
   ```

---

### Step 4.5: Execute the Pipeline

**Via UI:**

1. Click **Pipelines** tab
2. Click **Start Manual Execution** on "Deploy to Production"
3. Enter parameters:
   ```
   version: v1.1.0
   replicaCount: 5
   imageTag: 1.22
   ```
4. Click **Run**

**Via API:**

```bash
curl -X POST http://localhost:8084/pipelines/productapi/Deploy%20to%20Production \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "type": "manual",
    "parameters": {
      "version": "v1.1.0",
      "replicaCount": "5",
      "imageTag": "1.22"
    }
  }' | jq .
```

---

### Step 4.6: Monitor Pipeline Execution

**Via UI:**

1. Click **Pipelines** tab
2. Click on the running execution
3. Watch stages progress:
   - ✅ Find Current Version (completes immediately)
   - ✅ Deploy New Version (deploys new server group)
   - ⏳ Stabilization Wait (5 minutes)
   - ⏸️ Manual Judgment (waits for approval)

**Via API:**

```bash
# Get latest execution
EXECUTION_ID=$(curl -s -u admin:admin123 \
  "http://localhost:8084/applications/productapi/pipelines?limit=1" | \
  jq -r '.[0].id')

echo "Execution ID: $EXECUTION_ID"

# Monitor status
watch -n 5 "curl -s -u admin:admin123 \
  http://localhost:8084/pipelines/$EXECUTION_ID | \
  jq '{status, currentStage: .stages[-1].name, stageStatus: .stages[-1].status}'"
```

---

### Step 4.7: Validate New Deployment

While the pipeline is in **Stabilization Wait** stage:

```bash
# Check both server groups are running (blue/green)
kubectl get deployments -n default | grep productapi-prod

# Expected output:
# productapi-prod-v100    3/3     3            3           10m   (old version)
# productapi-prod-v110    5/5     5            5           2m    (new version)

# Check pods
kubectl get pods -n default -l app=productapi,env=prod

# Get pod details with versions
kubectl get pods -n default -l app=productapi,env=prod \
  -o custom-columns=NAME:.metadata.name,VERSION:.metadata.labels.version,STATUS:.status.phase

# Test new version (if accessible)
# Note: Both versions are running but old one still receives traffic
kubectl port-forward svc/productapi-prod-service 8080:80 &
curl http://localhost:8080/
pkill -f "port-forward svc/productapi-prod-service"
```

---

### Step 4.8: Approve or Rollback

**To Continue (Approve):**

**Via UI:**
1. In pipeline execution, find **Approve New Version** stage
2. Click **Continue**
3. Add optional comments: "Health checks passed, metrics look good"
4. Click **Submit**

**Via API:**
```bash
curl -X PUT "http://localhost:8084/pipelines/$EXECUTION_ID/stages/$(curl -s -u admin:admin123 http://localhost:8084/pipelines/$EXECUTION_ID | jq -r '.stages[] | select(.name=="Approve New Version") | .id')" \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "judgmentStatus": "Continue"
  }'
```

**To Rollback (Reject):**

**Via UI:**
1. Click **Rollback**
2. Add reason: "High error rate detected"
3. Pipeline will delete new version and keep old one

---

### Step 4.9: Verify Final State

After approval, the pipeline completes the remaining stages:

```bash
# Check only new version is running
kubectl get deployments -n default | grep productapi-prod

# Expected: Only v110 deployment exists
# productapi-prod-v110    5/5     5            5           15m

# Verify in Spinnaker
curl -u admin:admin123 \
  "http://localhost:8084/applications/productapi/clusters/my-k8s-account/productapi-prod" | \
  jq '.serverGroups[].name'

# Check Spinnaker UI
# Clusters tab should show:
# - Cluster: productapi-prod
#   - Server Group: productapi-prod-v110 (5 instances, enabled)
#   - Server Group: productapi-prod-v100 (destroyed/removed)
```

---

## 📊 Part 5: Explore Complete Infrastructure (10 minutes)

### Step 5.1: View Cluster Organization

**Via UI:**

1. Go to **Clusters** tab
2. Expand all clusters to see hierarchy:

```
productapi Application
│
├── Cluster: productapi-dev
│   ├── Server Group: productapi-dev-v100 (3 instances)
│   │   ├── Instance: pod-1 (Up)
│   │   ├── Instance: pod-2 (Up)
│   │   └── Instance: pod-3 (Up)
│   └── Load Balancer: productapi-dev-service
│
├── Cluster: productapi-staging  (if created)
│   └── ... (similar structure)
│
└── Cluster: productapi-prod
    ├── Server Group: productapi-prod-v110 (5 instances)
    │   ├── Instance: pod-1 (Up)
    │   ├── Instance: pod-2 (Up)
    │   ├── Instance: pod-3 (Up)
    │   ├── Instance: pod-4 (Up)
    │   └── Instance: pod-5 (Up)
    └── Load Balancer: productapi-prod-service
```

---

### Step 5.2: View Load Balancer Details

**Via UI:**

1. Click **Load Balancers** tab
2. Click on **productapi-prod-service**
3. Observe:
   - Type: LoadBalancer
   - Ports: 80:8080, 443:8443
   - Attached Server Groups: productapi-prod-v110
   - Healthy Instances: 5/5
   - Endpoints: [External IP or pending]

**Via API:**

```bash
curl -u admin:admin123 \
  "http://localhost:8084/applications/productapi/loadBalancers/my-k8s-account/default/service%20productapi-prod-service" | \
  jq '{
    name: .name,
    type: .type,
    serverGroups: .serverGroups[].name,
    instances: [.serverGroups[].instances[].health[0].state]
  }'
```

---

### Step 5.3: View Application Summary

**Via UI:**

1. Go to application **productapi** main page
2. You should see dashboard with:
   - **Clusters:** 3 (dev, staging, prod)
   - **Load Balancers:** 3
   - **Server Groups:** 3 active
   - **Instances:** 13 total (3 dev + 5 staging + 5 prod)
   - **Pipelines:** 1 (Deploy to Production)
   - **Recent Activity:** Recent executions and tasks

**Via API:**

```bash
# Complete application overview
curl -u admin:admin123 \
  http://localhost:8084/applications/productapi | jq '{
  name: .name,
  email: .email,
  clusters: [.clusters[]?.name],
  pipelinesCount: (.pipelineConfigs | length),
  loadBalancersCount: ([.loadBalancers[]] | length)
}'
```

---

### Step 5.4: Generate Infrastructure Report

Create a comprehensive report of your demo infrastructure:

```bash
#!/bin/bash
# generate-infrastructure-report.sh

echo "=========================================="
echo "  PRODUCTAPI INFRASTRUCTURE REPORT"
echo "=========================================="
echo ""

# Application info
echo "📱 APPLICATION"
curl -s -u admin:admin123 http://localhost:8084/applications/productapi | \
  jq -r '"Name: \(.name)\nEmail: \(.email)\nCloud Providers: \(.cloudProviders)"'
echo ""

# Clusters
echo "🗂️  CLUSTERS"
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/productapi/clusters" | \
  jq -r '.[] | "- \(.name) (\(.account))"'
echo ""

# Server Groups
echo "💻 SERVER GROUPS"
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/productapi/serverGroups" | \
  jq -r '.[] | "- \(.name): \(.instances | length) instances, Status: \(.disabled | if . then "Disabled" else "Enabled" end)"'
echo ""

# Load Balancers
echo "⚖️  LOAD BALANCERS"
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/productapi/loadBalancers" | \
  jq -r '.[] | "- \(.name) (\(.type))"'
echo ""

# Pipelines
echo "🔄 PIPELINES"
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/productapi/pipelineConfigs" | \
  jq -r '.[] | "- \(.name): \(.stages | length) stages"'
echo ""

# Recent executions
echo "📊 RECENT PIPELINE EXECUTIONS (Last 5)"
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/productapi/pipelines?limit=5" | \
  jq -r '.[] | "- \(.name) at \(.startTime): \(.status)"'
echo ""

# Kubernetes resources
echo "☸️  KUBERNETES RESOURCES"
echo "Deployments:"
kubectl get deployments -n default -l app=productapi --no-headers | \
  awk '{print "- "$1": "$2" ready"}'
echo ""
echo "Services:"
kubectl get svc -n default -l app=productapi --no-headers | \
  awk '{print "- "$1" ("$2"): "$5}'
echo ""
echo "Pods:"
kubectl get pods -n default -l app=productapi --no-headers | wc -l | \
  awk '{print "Total: "$1" pods"}'
echo ""

echo "=========================================="
echo "Report generated: $(date)"
echo "=========================================="
```

Run it:
```bash
chmod +x generate-infrastructure-report.sh
./generate-infrastructure-report.sh
```

---

## 🎭 Part 6: Advanced Scenarios (Optional)

### Scenario A: Rolling Update with Canary Analysis

Modify the pipeline to add a canary stage:

1. After **Deploy New Version**, add:
   - **Scale New Version** to 1 instance (10% traffic)
   - **Canary Wait** for 10 minutes
   - **Manual Judgment**: Continue or Abort
   - **Scale New Version** to full capacity

---

### Scenario B: Multi-Environment Pipeline

Create a promotion pipeline:

```
[Deploy to Dev] → [Run Tests] → [Manual Approval] → 
[Deploy to Staging] → [Integration Tests] → [Manual Approval] →
[Deploy to Prod] (using blue/green)
```

---

### Scenario C: Automated Rollback

Add a **Check Preconditions** stage after deployment:
- Check pod health percentage > 95%
- If fails, trigger automatic rollback
- Send notification to Slack

---

## 🧪 Part 7: Testing and Verification

### Test 1: Traffic Routing

```bash
# Port forward to production service
kubectl port-forward svc/productapi-prod-service 8080:80 -n default &

# Make requests
for i in {1..10}; do
  echo "Request $i:"
  curl -s http://localhost:8080/ | grep -i nginx || echo "Response received"
  sleep 1
done

# Cleanup
pkill -f "port-forward svc/productapi-prod-service"
```

### Test 2: Scaling Test

```bash
# Via Spinnaker UI
# 1. Go to Clusters → productapi-prod-v110
# 2. Click "Server Group Actions" → "Resize"
# 3. Set capacity to 10
# 4. Watch pods scale

# Via API
curl -X POST http://localhost:8084/tasks \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "resizeServerGroup",
      "application": "productapi",
      "serverGroupName": "productapi-prod-v110",
      "account": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "location": "default",
      "capacity": {
        "desired": 10
      }
    }],
    "application": "productapi",
    "description": "Resize server group: productapi-prod-v110 to 10"
  }'

# Verify
kubectl get deployment productapi-prod-v110 -n default
```

### Test 3: Disable/Enable Test

```bash
# Disable server group (stop traffic)
curl -X POST http://localhost:8084/tasks \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "disableServerGroup",
      "application": "productapi",
      "serverGroupName": "productapi-prod-v110",
      "account": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "location": "default"
    }],
    "application": "productapi",
    "description": "Disable server group for testing"
  }'

# Wait 30 seconds, then re-enable
sleep 30

curl -X POST http://localhost:8084/tasks \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "enableServerGroup",
      "application": "productapi",
      "serverGroupName": "productapi-prod-v110",
      "account": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "location": "default"
    }],
    "application": "productapi",
    "description": "Re-enable server group"
  }'
```

---

## 🔄 Part 8: Deploy Additional Versions

Practice the complete workflow by deploying v2.0.0:

### Quick Deploy Script

```bash
#!/bin/bash
# deploy-new-version.sh

VERSION="$1"
IMAGE_TAG="$2"
REPLICAS="${3:-5}"

if [ -z "$VERSION" ] || [ -z "$IMAGE_TAG" ]; then
  echo "Usage: $0 <version> <image-tag> [replicas]"
  echo "Example: $0 v2.0.0 1.23 5"
  exit 1
fi

echo "Deploying version $VERSION with image tag $IMAGE_TAG..."

# Trigger pipeline via API
curl -X POST "http://localhost:8084/pipelines/productapi/Deploy%20to%20Production" \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"manual\",
    \"parameters\": {
      \"version\": \"$VERSION\",
      \"imageTag\": \"$IMAGE_TAG\",
      \"replicaCount\": \"$REPLICAS\"
    }
  }" | jq -r '.ref'

echo ""
echo "Pipeline started! Monitor at:"
echo "http://localhost:9000/#/applications/productapi/executions"
```

Usage:
```bash
chmod +x deploy-new-version.sh
./deploy-new-version.sh v2.0.0 1.23 8
```

---

## 📈 Part 9: Monitoring and Observability

### View Pipeline Execution History

```bash
# Get last 10 executions
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/productapi/pipelines?limit=10" | \
  jq -r '.[] | "\(.startTime | todate): \(.name) - \(.status)"'

# Get execution statistics
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/productapi/pipelines?limit=50" | \
  jq 'group_by(.status) | map({status: .[0].status, count: length})'
```

### Monitor Instance Health

```bash
# Real-time health monitoring
watch -n 5 '
echo "=== PRODUCTAPI HEALTH STATUS ==="
echo ""
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/productapi/serverGroups" | \
  jq -r ".[] | \"\(.name): \(.instances | map(select(.health[].state == \"Up\")) | length)/\(.instances | length) healthy\""
'
```

---

## 🧹 Part 10: Cleanup (Optional)

To clean up the demo environment:

### Via UI

1. **Delete Pipelines:**
   - Pipelines tab → Configure → Delete Pipeline

2. **Delete Server Groups:**
   - Clusters tab → Select each server group → Actions → Destroy

3. **Delete Load Balancers:**
   - Load Balancers tab → Select each → Actions → Delete

4. **Delete Application:**
   - Config tab → Application Attributes → Delete Application

### Via API

```bash
#!/bin/bash
# cleanup-demo.sh

echo "Cleaning up productapi demo infrastructure..."

# 1. Delete all server groups
echo "Deleting server groups..."
for SG in $(kubectl get deployments -n default -l app=productapi -o name); do
  kubectl delete $SG -n default
done

# 2. Delete all services/load balancers
echo "Deleting services..."
for SVC in $(kubectl get svc -n default -l app=productapi -o name); do
  kubectl delete $SVC -n default
done

# 3. Delete application (this also removes pipelines)
echo "Deleting Spinnaker application..."
curl -X POST http://localhost:8084/tasks \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "deleteApplication",
      "application": {
        "name": "productapi"
      },
      "user": "admin"
    }],
    "application": "productapi",
    "description": "Delete application: productapi"
  }'

echo ""
echo "Cleanup complete!"
echo "Verify with: kubectl get all -n default -l app=productapi"
```

Run cleanup:
```bash
chmod +x cleanup-demo.sh
./cleanup-demo.sh
```

---

## 📚 Summary

### What You Demonstrated

✅ **Applications** - Created `productapi` application with proper configuration  
✅ **Projects** - (Optional) Organized application in `ecommerce-platform` project  
✅ **Load Balancers** - Created 3 Services for dev, staging, and prod environments  
✅ **Server Groups** - Deployed multiple versions across environments  
✅ **Clusters** - Organized server groups into logical clusters by environment  
✅ **Pipelines** - Built blue/green deployment pipeline with manual judgment  

### Key Concepts Covered

1. **Application Lifecycle** - Create, configure, deploy, manage
2. **Infrastructure as Code** - Kubernetes manifests via Spinnaker
3. **Blue/Green Deployment** - Zero-downtime deployments
4. **Pipeline Orchestration** - Multi-stage automated workflows
5. **Manual Judgments** - Quality gates and approvals
6. **Cluster Organization** - Logical grouping of deployments
7. **Load Balancer Management** - Traffic routing and service exposure

### Demo Flow Summary

```
Application Creation
        ↓
Load Balancers Setup (Dev/Staging/Prod)
        ↓
Initial Deployment (v1.0.0 to Dev)
        ↓
Pipeline Creation (Blue/Green Strategy)
        ↓
Pipeline Execution (Deploy v1.1.0 to Prod)
        ↓
Manual Approval (Quality Gate)
        ↓
Cutover Completion (Disable old, cleanup)
        ↓
Verification & Monitoring
        ↓
(Optional) Deploy v2.0.0
```

---

## 🎓 Next Steps

### Extend the Demo

1. **Add More Pipelines:**
   - Promote from Dev → Staging → Prod
   - Automated testing pipeline
   - Scheduled deployments

2. **Implement Canary Analysis:**
   - Deploy to 10% of traffic
   - Monitor metrics
   - Automated rollback on failures

3. **Add Notifications:**
   - Slack alerts on pipeline status
   - Email notifications for manual judgments
   - PagerDuty integration for failures

4. **Integrate with CI/CD:**
   - Trigger from Jenkins builds
   - GitHub webhook triggers
   - Docker Hub artifact integration

5. **Multi-Region Deployment:**
   - Deploy across multiple Kubernetes clusters
   - Region-specific configurations
   - Global load balancing

---

## 📖 Reference Documentation

- [Applications Guide](features/01-applications.md)
- [Pipelines Guide](features/02-pipelines.md)
- [Tasks & Executions Guide](features/03-tasks-executions.md)
- [Clusters & Server Groups Guide](features/04-clusters-servergroups.md)
- [Load Balancers Guide](features/05-loadbalancers.md)
- [Postman Collection](../Spinnaker-API.postman_collection.json)
- [XL Release Integration](spinnaker-integration.md)

---

**Demo Version:** 1.0  
**Last Updated:** January 6, 2026  
**Tested On:** Spinnaker 1.33.0 + Kubernetes (Docker Desktop)  
**Total Demo Time:** 45-60 minutes  
**Difficulty:** Intermediate

🎉 **Congratulations! You've completed a comprehensive end-to-end Spinnaker demo!**
