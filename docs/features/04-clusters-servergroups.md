# Feature 4: Clusters & Server Groups

## 📋 Overview

**What are Clusters and Server Groups in Spinnaker?**

Clusters and Server Groups are Spinnaker's abstraction for managing deployed instances:

- **Cluster:** A logical grouping of Server Groups (e.g., "myapp-prod" cluster)
- **Server Group:** A collection of instances running the same version of your application
- **Instance:** Individual compute resource (VM, container, pod)

**Key Concepts:**
- **Immutable Infrastructure:** Deploy new server groups instead of updating existing ones
- **Red/Black (Blue/Green) Deployments:** New version alongside old, then switch traffic
- **Rolling Red/Black:** Gradually scale down old, scale up new
- **Capacity:** Min/max/desired instance counts
- **Health:** Platform health (Kubernetes/AWS) vs application health

---

## 🎯 Prerequisites

- ✅ Spinnaker running with cloud provider configured
- ✅ At least one application created
- ✅ Cloud provider account credentials configured
- ✅ Port forwards active
- ✅ Authentication working

**Note:** This guide focuses on Kubernetes provider, but concepts apply to AWS, GCP, Azure, etc.

---

## 📖 Understanding the Hierarchy

```
Application
  └── Cluster (logical grouping)
       ├── Server Group v001 (old version)
       │    ├── Instance 1
       │    ├── Instance 2
       │    └── Instance 3
       └── Server Group v002 (new version)
            ├── Instance 1
            ├── Instance 2
            └── Instance 3
```

**Naming Convention:**
- **Cluster:** `{app}-{stack}-{detail}`
- **Server Group:** `{cluster}-v{sequence}` (e.g., myapp-prod-detail-v001)
- Auto-incremented sequence number for each deployment

---

## 🔧 Common Operations

### 1. List Clusters for an Application

**Via UI:**
1. Navigate to **Applications** in Spinnaker (http://localhost:9000)
2. Click on your application (e.g., **myapp**)
3. Click **Clusters** tab in the left sidebar
4. View all clusters grouped by account
5. Each cluster shows:
   - Server groups (with version numbers)
   - Instance counts
   - Load balancers
   - Health status

**Via API:**
```bash
# Get all clusters for an application
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/clusters

# For specific account/provider
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/clusters?account=my-k8s-account"
```

**Expected Response:**
```json
[
  {
    "name": "myapp-prod",
    "accountName": "my-k8s-account",
    "serverGroups": [
      {
        "name": "myapp-prod-v001",
        "region": "default",
        "zones": ["default"],
        "instances": 3,
        "capacity": {
          "min": 2,
          "max": 5,
          "desired": 3
        }
      }
    ]
  }
]
```

---

### 2. Get Cluster Details

**Via UI:**
1. Go to **Applications** → **myapp** → **Clusters**
2. Click on a cluster name (e.g., **myapp-prod**)
3. The cluster detail panel opens showing:
   - **Server Groups**: All versions (v001, v002, etc.)
   - **Capacity**: Min/Max/Desired instance counts
   - **Health**: Overall cluster health status
   - **Load Balancers**: Associated LBs
4. Click on individual server groups to drill down further

**Via API:**
```bash
# Get detailed cluster information
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/clusters/my-k8s-account/myapp-prod"

# For Kubernetes with namespace
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/clusters/my-k8s-account/myapp-prod/kubernetes/default"
```

**Response includes:**
- All server groups in the cluster
- Instance details
- Load balancers attached
- Security groups
- Capacity settings

---

### 3. List Server Groups for an Application

**Via UI:**
1. Navigate to **Applications** → **myapp** → **Clusters**
2. Server groups are displayed under each cluster
3. Each server group shows:
   - **Name** with version (e.g., myapp-prod-v001)
   - **Instance count** (e.g., 3/3 healthy)
   - **Build info** (image, version)
   - **Status badge** (Enabled/Disabled)
4. Use the **Filter** box at top to search by name
5. Group by **Account**, **Region**, or **Stack**

**Via API:**
```bash
# Get all server groups across all clusters
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/serverGroups

# Filter by account
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/serverGroups?account=my-k8s-account"

# Filter by region/namespace
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/serverGroups?region=default"
```

---

### 4. Get Server Group Details

**Via UI:**
1. Go to **Clusters** tab
2. Click on a **server group name** (e.g., myapp-prod-v001)
3. The details panel opens with multiple tabs:
   - **Details**: Capacity, health, creation time
   - **Status**: Running instances and their health
   - **Build**: Image, tags, commit info
   - **Capacity**: Min/Max/Desired settings
   - **Load Balancers**: Associated LBs and health
   - **Launch Config**: Cloud provider configuration
4. Click **Actions** dropdown for operations (resize, disable, etc.)

**Via API:**
```bash
# Get specific server group details
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/serverGroups/my-k8s-account/default/myapp-prod-v001"

# Response includes extensive details:
# - Instance list with health status
# - Capacity configuration
# - Build info and image
# - Load balancer associations
# - Scaling policies
# - Launch configuration
```

---

### 5. Create/Deploy Server Group

**Via UI (Recommended):**

**Method 1: Manual Deploy from Clusters Tab**
1. Navigate to **Applications** → **myapp** → **Clusters**
2. Click **Create Server Group** button (top right)
3. In the Create Server Group wizard:
   
   **Basic Settings:**
   - **Account**: Select your cloud account (e.g., my-k8s-account)
   - **Namespace/Region**: Select namespace (e.g., default)
   - **Stack**: Optional stack name (e.g., prod)
   - **Detail**: Optional detail suffix
   
   **For Kubernetes - Choose deployment method:**
   
   **Option A: Text (Manifest)**
   - Select **Text** tab
   - Paste your Kubernetes manifest:
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: myapp
     spec:
       replicas: 3
       selector:
         matchLabels:
           app: myapp
       template:
         metadata:
           labels:
             app: myapp
         spec:
           containers:
           - name: myapp
             image: nginx:latest
             ports:
             - containerPort: 80
     ```
   
   **Option B: Form (UI Fields)**
   - Select **Form** tab
   - **Containers**:
     - Image: nginx:latest
     - Name: myapp
     - Ports: 80
   - **Replicas**: 3
   - **Labels**: app=myapp
   - Configure probes, volumes, etc.
   
4. **Capacity**:
   - Min: 2
   - Max: 5
   - Desired: 3

5. **Load Balancers** (optional):
   - Select load balancers to attach

6. Click **Create** at the bottom

7. Monitor deployment in **Tasks** tab

**Method 2: Deploy via Pipeline (Most Common)**
1. Go to **Pipelines** tab
2. Click **Configure** on a pipeline (or create new)
3. Add **Deploy (Manifest)** stage:
   - Stage Name: Deploy to Production
   - Account: my-k8s-account
   - Manifest Source: Text or Artifact
   - Paste/upload your manifest
4. Save pipeline
5. Trigger pipeline to deploy server group

**Via API:**
```bash
# Deploy new server group (via task)
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "createServerGroup",
      "application": "myapp",
      "stack": "prod",
      "account": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "namespace": "default",
      "manifest": {
        "apiVersion": "apps/v1",
        "kind": "Deployment",
        "metadata": {
          "name": "myapp-prod",
          "namespace": "default"
        },
        "spec": {
          "replicas": 3,
          "selector": {
            "matchLabels": {
              "app": "myapp"
            }
          },
          "template": {
            "metadata": {
              "labels": {
                "app": "myapp"
              }
            },
            "spec": {
              "containers": [{
                "name": "myapp",
                "image": "nginx:latest",
                "ports": [{
                  "containerPort": 80
                }]
              }]
            }
          }
        }
      }
    }],
    "application": "myapp",
    "description": "Deploy myapp-prod server group"
  }' \
  http://localhost:8084/tasks
```

**Note:** 
- **UI Method** is recommended for manual deployments and learning
- **Pipeline Method** is recommended for production (automation, rollback, approvals)
- **API Method** is for advanced automation or custom tooling

---

### 6. Resize Server Group

**Via UI:**
1. Navigate to **Clusters** tab
2. Click on the server group you want to resize
3. In the details panel, click **Server Group Actions** dropdown
4. Select **Resize**
5. In the Resize dialog:
   - Set **Min** capacity (e.g., 2)
   - Set **Max** capacity (e.g., 10)
   - Set **Desired** capacity (e.g., 5)
6. Click **Submit**
7. Monitor the task progress in **Tasks** tab
8. Instances will be added/removed to match desired capacity

**Via API:**
```bash
# Resize server group (scale instances)
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "resizeServerGroup",
      "serverGroupName": "myapp-prod-v001",
      "capacity": {
        "min": 2,
        "max": 10,
        "desired": 5
      },
      "region": "default",
      "credentials": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "user": "admin"
    }],
    "application": "myapp",
    "description": "Resize myapp-prod-v001 to 5 instances"
  }' \
  http://localhost:8084/tasks
```

---

### 7. Enable Server Group

**Via UI:**
1. Go to **Clusters** tab
2. Click on the **disabled** server group
3. Click **Server Group Actions** dropdown
4. Select **Enable**
5. Confirm the action in the dialog
6. Click **Submit**
7. The server group will:
   - Be added to load balancer target groups
   - Start receiving traffic
   - Status badge changes to "Enabled"

**Via API:**
```bash
# Enable server group (start receiving traffic)
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "enableServerGroup",
      "serverGroupName": "myapp-prod-v001",
      "region": "default",
      "credentials": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "user": "admin"
    }],
    "application": "myapp",
    "description": "Enable myapp-prod-v001"
  }' \
  http://localhost:8084/tasks
```

---

### 8. Disable Server Group

**Via UI:**
1. Navigate to **Clusters** tab
2. Click on the server group to disable
3. Click **Server Group Actions** dropdown
4. Select **Disable**
5. Review the warning dialog:
   - "This will remove the server group from load balancers"
   - "Instances will continue running"
6. Click **Submit**
7. The server group:
   - Stops receiving new traffic
   - Status badge changes to "Disabled"
   - Instances remain running

**Use case:** Blue/Green deployments - disable old version after new is verified

**Via API:**
```bash
# Disable server group (stop receiving new traffic)
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "disableServerGroup",
      "serverGroupName": "myapp-prod-v001",
      "region": "default",
      "credentials": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "user": "admin"
    }],
    "application": "myapp",
    "description": "Disable myapp-prod-v001"
  }' \
  http://localhost:8084/tasks
```

---

### 9. Destroy Server Group

**Via UI:**
1. Go to **Clusters** tab
2. Click on the server group to destroy
3. Click **Server Group Actions** dropdown
4. Select **Destroy**
5. Review the **critical warning dialog**:
   - "This will permanently delete the server group"
   - "All instances will be terminated"
   - "This action cannot be undone"
6. Type the server group name to confirm
7. Click **Submit**
8. Monitor task completion in **Tasks** tab

**Safety:** Spinnaker prevents destroying the last server group in a cluster

**Via API:**
```bash
# Delete/destroy server group
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "destroyServerGroup",
      "serverGroupName": "myapp-prod-v001",
      "region": "default",
      "credentials": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "user": "admin"
    }],
    "application": "myapp",
    "description": "Destroy myapp-prod-v001"
  }' \
  http://localhost:8084/tasks
```

**Warning:** This is destructive and removes the server group permanently.

---

### 10. Rollback Server Group

**Via UI:**
1. Navigate to **Clusters** tab
2. Click on the **current/newest** server group (e.g., v002)
3. Click **Server Group Actions** dropdown
4. Select **Rollback**
5. In the Rollback dialog:
   - Shows previous server group to restore (v001)
   - Option: **Disable current server group** (checked)
   - Option: **Destroy current server group** (optional)
6. Click **Submit**
7. Spinnaker automatically:
   - Enables previous version (v001)
   - Disables/destroys current version (v002)
   - Traffic shifts to previous version

**Use case:** Quick recovery from bad deployment

**Via API:**
```bash
# Rollback to previous server group
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "rollbackServerGroup",
      "serverGroupName": "myapp-prod-v002",
      "region": "default",
      "credentials": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "user": "admin"
    }],
    "application": "myapp",
    "description": "Rollback from myapp-prod-v002"
  }' \
  http://localhost:8084/tasks
```

**What happens:**
- Enables previous server group (v001)
- Disables current server group (v002)
- Optionally destroys current server group

---

### 11. Get Instance Details

**Via UI:**
1. Go to **Clusters** tab
2. Click on a server group to open details
3. Click the **Status** tab
4. View list of all instances with:
   - Instance ID/name
   - Health status (Up/Down/Unknown)
   - Launch time
   - Zone/availability zone
5. Click on an **instance name** to open instance details panel:
   - Health checks status
   - Cloud provider metadata
   - Load balancer associations
   - Console output (for debugging)

**Via API:**
```bash
# Get details for a specific instance
curl -u admin:admin123 \
  "http://localhost:8084/instances/my-k8s-account/default/myapp-prod-v001-abc123"

# Response includes:
# - Health status
# - Launch time
# - Zone/availability
# - Associated load balancers
# - Cloud provider metadata
```

---

### 12. Terminate Instance

**Via UI:**
1. Navigate to **Clusters** tab
2. Click on the server group containing the instance
3. Click **Status** tab to view instances
4. Click on the **instance** you want to terminate
5. In the instance details panel, click **Instance Actions**
6. Select **Terminate**
7. Confirm the termination dialog:
   - Warning: "Instance will be terminated immediately"
   - If auto-scaling is enabled, a replacement will be created
8. Click **Submit**
9. Monitor in **Tasks** tab

**Via API:**
```bash
# Terminate a specific instance
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "terminateInstances",
      "instanceIds": ["myapp-prod-v001-abc123"],
      "region": "default",
      "credentials": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "user": "admin"
    }],
    "application": "myapp",
    "description": "Terminate instance myapp-prod-v001-abc123"
  }' \
  http://localhost:8084/tasks
```

**Use case:** Remove unhealthy instance (auto-scaling will create replacement)

---

## 📝 Practical Examples

### Example 1: Blue/Green Deployment Simulation

```bash
#!/bin/bash
# Simulate a blue/green deployment workflow

APP="myapp"
CLUSTER="myapp-prod"
ACCOUNT="my-k8s-account"
REGION="default"

echo "=== Blue/Green Deployment ==="
echo ""

# Step 1: Deploy new version (green)
echo "1. Deploying new version (green)..."
DEPLOY_RESPONSE=$(curl -s -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "createServerGroup",
      "application": "'$APP'",
      "stack": "prod",
      "account": "'$ACCOUNT'",
      "cloudProvider": "kubernetes",
      "namespace": "'$REGION'"
    }],
    "application": "'$APP'",
    "description": "Deploy new version"
  }' \
  http://localhost:8084/tasks)

TASK_ID=$(echo "$DEPLOY_RESPONSE" | jq -r '.ref' | cut -d'/' -f2)
echo "Deploy task: $TASK_ID"

# Wait for deployment
echo "Waiting for deployment..."
while true; do
  STATUS=$(curl -s -u admin:admin123 \
    http://localhost:8084/tasks/$TASK_ID | jq -r '.status')
  echo "  Status: $STATUS"
  [[ "$STATUS" != "RUNNING" ]] && break
  sleep 5
done

# Step 2: Get new server group name
echo ""
echo "2. Finding new server group..."
NEW_SG=$(curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/serverGroups" \
  | jq -r '.[0].name')
echo "New server group: $NEW_SG"

# Step 3: Verify new version is healthy
echo ""
echo "3. Verifying health..."
sleep 10  # Wait for health checks

# Step 4: Get old server group
OLD_SG=$(curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/serverGroups" \
  | jq -r '.[1].name')
echo "Old server group: $OLD_SG"

# Step 5: Disable old version (blue)
echo ""
echo "4. Disabling old version..."
curl -s -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "disableServerGroup",
      "serverGroupName": "'$OLD_SG'",
      "region": "'$REGION'",
      "credentials": "'$ACCOUNT'",
      "cloudProvider": "kubernetes",
      "user": "admin"
    }],
    "application": "'$APP'",
    "description": "Disable old version"
  }' \
  http://localhost:8084/tasks | jq .

echo ""
echo "✅ Blue/Green deployment complete!"
echo "  Green (new): $NEW_SG - ENABLED"
echo "  Blue (old):  $OLD_SG - DISABLED"
```

---

### Example 2: Scale Server Group Based on Load

```bash
#!/bin/bash
# Scale server group based on simulated load

APP="myapp"
SG_NAME="myapp-prod-v001"
ACCOUNT="my-k8s-account"
REGION="default"

echo "=== Auto-Scaling Simulation ==="
echo ""

# Get current capacity
CURRENT=$(curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/serverGroups/$ACCOUNT/$REGION/$SG_NAME" \
  | jq -r '.capacity.desired')

echo "Current capacity: $CURRENT instances"

# Simulate high load - scale up
NEW_CAPACITY=$((CURRENT + 2))
echo "Scaling up to $NEW_CAPACITY instances..."

curl -s -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "resizeServerGroup",
      "serverGroupName": "'$SG_NAME'",
      "capacity": {
        "min": 2,
        "max": 10,
        "desired": '$NEW_CAPACITY'
      },
      "region": "'$REGION'",
      "credentials": "'$ACCOUNT'",
      "cloudProvider": "kubernetes",
      "user": "admin"
    }],
    "application": "'$APP'",
    "description": "Scale up to '$NEW_CAPACITY' instances"
  }' \
  http://localhost:8084/tasks | jq '.ref'

echo "Waiting 30 seconds for scale-up..."
sleep 30

# Verify new capacity
UPDATED=$(curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/serverGroups/$ACCOUNT/$REGION/$SG_NAME" \
  | jq -r '.capacity.desired')

echo ""
echo "✅ Scaled from $CURRENT to $UPDATED instances"
```

---

### Example 3: Health Check and Recovery

```bash
#!/bin/bash
# Check server group health and terminate unhealthy instances

APP="myapp"
SG_NAME="myapp-prod-v001"
ACCOUNT="my-k8s-account"
REGION="default"

echo "=== Health Check and Recovery ==="
echo ""

# Get server group with instances
SG_DATA=$(curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/serverGroups/$ACCOUNT/$REGION/$SG_NAME")

# Check instance health
echo "Instance Health Status:"
echo "$SG_DATA" | jq -r '.instances[] | "\(.name): \(.health[0].state)"'

# Find unhealthy instances
UNHEALTHY=$(echo "$SG_DATA" | jq -r '.instances[] | select(.health[0].state != "Up") | .name')

if [ -z "$UNHEALTHY" ]; then
  echo ""
  echo "✅ All instances healthy!"
else
  echo ""
  echo "⚠️  Unhealthy instances found:"
  echo "$UNHEALTHY"
  
  read -p "Terminate unhealthy instances? (y/n): " CONFIRM
  
  if [ "$CONFIRM" = "y" ]; then
    for INSTANCE in $UNHEALTHY; do
      echo "Terminating $INSTANCE..."
      curl -s -u admin:admin123 \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{
          "job": [{
            "type": "terminateInstances",
            "instanceIds": ["'$INSTANCE'"],
            "region": "'$REGION'",
            "credentials": "'$ACCOUNT'",
            "cloudProvider": "kubernetes",
            "user": "admin"
          }],
          "application": "'$APP'",
          "description": "Terminate unhealthy instance"
        }' \
        http://localhost:8084/tasks > /dev/null
    done
    echo "✅ Terminated unhealthy instances (auto-scaling will replace them)"
  fi
fi
```

---

### Example 4: Cluster Summary Report

```bash
#!/bin/bash
# Generate comprehensive cluster summary

APP="myapp"

echo "=== Cluster Summary Report: $APP ==="
echo ""

# Get all clusters
CLUSTERS=$(curl -s -u admin:admin123 \
  http://localhost:8084/applications/$APP/clusters)

echo "$CLUSTERS" | jq -r '.[] | 
  "Cluster: \(.name)
  Account: \(.accountName)
  Provider: \(.type)
  Server Groups: \(.serverGroups | length)
  
  Server Group Details:"
'

echo "$CLUSTERS" | jq -r '.[] | .serverGroups[] |
  "  - \(.name)
    Region: \(.region)
    Instances: \(.instances | length)
    Capacity: min=\(.capacity.min) desired=\(.capacity.desired) max=\(.capacity.max)
    Disabled: \(.disabled)
    Created: \(.createdTime)
"'
```

---

## 🐛 Troubleshooting

### Issue 1: Server group not receiving traffic
**Symptoms:** New server group deployed but no requests reaching it
**Causes:**
- Server group is disabled
- No load balancer attached
- Health checks failing

**Solution:**
```bash
# Check if disabled
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/serverGroups" \
  | jq '.[] | {name, disabled}'

# Enable if needed
curl -u admin:admin123 -X POST -H "Content-Type: application/json" \
  -d '{"job":[{"type":"enableServerGroup",...}]}' \
  http://localhost:8084/tasks

# Check load balancer association
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/serverGroups/account/region/sg-name" \
  | jq '.loadBalancers'
```

### Issue 2: Cannot destroy server group
**Cause:** Server group is the only one in the cluster (safety check)
**Solution:** Deploy new version first, then destroy old one

### Issue 3: Scaling not working
**Symptoms:** Resize task succeeds but instance count doesn't change
**Causes:**
- Cloud provider quota limits
- Auto-scaling policies overriding manual changes
- Platform constraints (min/max)

**Solution:**
```bash
# Check task details for errors
curl -u admin:admin123 \
  http://localhost:8084/tasks/{task-id} \
  | jq '.execution.stages[] | select(.type == "resizeServerGroup")'

# Verify cloud provider quota
# Check platform-specific logs
```

### Issue 4: Instance health always "Unknown"
**Cause:** Health check misconfiguration or provider issues
**Solution:**
- For Kubernetes: Check liveness/readiness probes
- Verify platform health provider is configured
- Check application responds on health endpoint

---

## 📚 API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/applications/{app}/clusters` | List all clusters |
| GET | `/applications/{app}/clusters/{account}/{cluster}` | Get cluster details |
| GET | `/applications/{app}/clusters/{account}/{cluster}/{provider}/{region}` | Get cluster by provider/region |
| GET | `/applications/{app}/serverGroups` | List all server groups |
| GET | `/applications/{app}/serverGroups/{account}/{region}/{name}` | Get server group details |
| POST | `/tasks` with `createServerGroup` | Deploy new server group |
| POST | `/tasks` with `resizeServerGroup` | Scale server group |
| POST | `/tasks` with `enableServerGroup` | Enable server group |
| POST | `/tasks` with `disableServerGroup` | Disable server group |
| POST | `/tasks` with `destroyServerGroup` | Destroy server group |
| POST | `/tasks` with `rollbackServerGroup` | Rollback deployment |
| GET | `/instances/{account}/{region}/{id}` | Get instance details |
| POST | `/tasks` with `terminateInstances` | Terminate instances |

---

## 🎯 Server Group Operations

| Operation | Use Case | Traffic Impact |
|-----------|----------|----------------|
| **Deploy** | New version release | None (new group created) |
| **Enable** | Start receiving traffic | Adds to load balancer |
| **Disable** | Stop new traffic | Removes from load balancer |
| **Resize** | Scale capacity | None (adjusts instance count) |
| **Destroy** | Remove old version | Deletes all instances |
| **Rollback** | Revert deployment | Enables old, disables new |

---

## ✅ Verification Checklist

After completing this section, you should be able to:

- [ ] List all clusters for an application
- [ ] Get detailed cluster and server group information
- [ ] Deploy a new server group
- [ ] Resize (scale) a server group
- [ ] Enable/disable server groups
- [ ] Perform blue/green deployment manually
- [ ] Rollback to previous server group
- [ ] Terminate unhealthy instances
- [ ] Monitor server group health
- [ ] Destroy old server groups safely

---

## 🎯 Next Steps

Once you're comfortable with clusters and server groups, proceed to:
- **[05-loadbalancers.md](05-loadbalancers.md)** - Configure load balancing and traffic management

---

## 📎 Postman Collection

**Collection:** Spinnaker API  
**Folder:** 04 - Clusters & Server Groups

**Requests:**
1. List application clusters - `GET /applications/{app}/clusters`
2. Get cluster details - `GET /applications/{app}/clusters/{account}/{cluster}`
3. List server groups - `GET /applications/{app}/serverGroups`
4. Get server group details - `GET /applications/{app}/serverGroups/{account}/{region}/{name}`
5. Resize server group - `POST /tasks` (resizeServerGroup)
6. Enable server group - `POST /tasks` (enableServerGroup)
7. Disable server group - `POST /tasks` (disableServerGroup)
8. Destroy server group - `POST /tasks` (destroyServerGroup)
9. Rollback server group - `POST /tasks` (rollbackServerGroup)
10. Get instance details - `GET /instances/{account}/{region}/{id}`
11. Terminate instance - `POST /tasks` (terminateInstances)

**Note:** Server group creation is typically done through pipeline deploy stages rather than direct API calls. The API supports it but requires cloud provider-specific manifest/configuration.
