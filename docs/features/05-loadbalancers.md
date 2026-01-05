# Feature 5: Load Balancers

## 📋 Overview

**What are Load Balancers in Spinnaker?**

Load Balancers distribute incoming traffic across multiple server group instances, providing high availability and fault tolerance:

- **Load Balancer:** Traffic distribution endpoint (AWS ELB, Kubernetes Service, GCP Load Balancer, etc.)
- **Target Group:** Group of instances that receive traffic
- **Health Checks:** Automated checks to ensure instances are healthy
- **Listeners:** Rules that define how traffic is routed

**Key Concepts:**
- **Service Discovery:** Automatic registration/deregistration of instances
- **Health-Based Routing:** Only healthy instances receive traffic
- **Session Affinity:** Optional sticky sessions to same instance
- **SSL/TLS Termination:** Handle encryption at load balancer level
- **Multiple Protocols:** HTTP, HTTPS, TCP, UDP support

---

## 🎯 Prerequisites

- ✅ Spinnaker running with cloud provider configured
- ✅ At least one application created
- ✅ Cloud provider account credentials configured
- ✅ Understanding of server groups (Feature 4)
- ✅ Port forwards active
- ✅ Authentication working

**Note:** This guide focuses on Kubernetes Services, but concepts apply to AWS ELB/ALB, GCP Load Balancers, etc.

---

## 📖 Understanding Load Balancers

### Load Balancer Types by Cloud Provider

**Kubernetes:**
- **ClusterIP**: Internal cluster access only
- **NodePort**: Exposes on each node's IP
- **LoadBalancer**: External cloud load balancer
- **Ingress**: HTTP/HTTPS routing with rules

**AWS:**
- **Classic Load Balancer (CLB)**: Legacy, layer 4/7
- **Application Load Balancer (ALB)**: HTTP/HTTPS, layer 7
- **Network Load Balancer (NLB)**: TCP/UDP, layer 4

**GCP:**
- **HTTP(S) Load Balancer**: Global, layer 7
- **TCP/SSL Proxy**: Global, layer 4
- **Network Load Balancer**: Regional, layer 4

---

## 🔧 Common Operations

### 1. List Load Balancers for an Application

**Via UI:**
1. Navigate to **Applications** → **myapp**
2. Click **Load Balancers** tab in left sidebar
3. View all load balancers organized by:
   - Account
   - Region/Namespace
   - Type (Service, Ingress, etc.)
4. Each load balancer shows:
   - Name and type
   - Target server groups
   - Health status
   - Endpoints/IPs

**Via API:**
```bash
# Get all load balancers for an application
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/loadBalancers

# Filter by account
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/loadBalancers?account=my-k8s-account"

# Filter by region/namespace
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/loadBalancers?region=default"
```

**Expected Response:**
```json
[
  {
    "name": "myapp-lb",
    "account": "my-k8s-account",
    "region": "default",
    "type": "kubernetes",
    "serverGroups": ["myapp-prod-v001"],
    "health": {
      "healthy": 3,
      "unhealthy": 0
    }
  }
]
```

---

### 2. Get Load Balancer Details

**Via UI:**
1. Go to **Load Balancers** tab
2. Click on a **load balancer name**
3. Details panel opens showing:
   - **Details**: Type, account, region, creation time
   - **Server Groups**: Attached server groups
   - **Health**: Instance health status
   - **Ingress/Endpoints**: External access points
   - **Configuration**: Ports, protocols, rules

**Via API:**
```bash
# Get specific load balancer details
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/loadBalancers/my-k8s-account/default/myapp-lb"

# Response includes:
# - Load balancer configuration
# - Attached server groups
# - Target instances and health
# - Listener rules and ports
# - External endpoints
```

---

### 3. Create Load Balancer

**Via UI:**

**For Kubernetes (Service):**
1. Navigate to **Load Balancers** tab
2. Click **Create Load Balancer** button
3. In the Create wizard:
   
   **Basic Settings:**
   - **Account**: my-k8s-account
   - **Namespace**: default
   - **Stack**: prod (optional)
   - **Detail**: (optional)
   
   **Service Configuration:**
   - **Name**: myapp-service (or auto-generated)
   - **Type**: 
     - ClusterIP (internal only)
     - NodePort (expose on nodes)
     - LoadBalancer (external)
   
   **Ports:**
   - Protocol: TCP
   - Port: 80 (external)
   - Target Port: 8080 (container)
   - Node Port: 30080 (if NodePort type)
   
   **Selector:**
   - Add labels to match server groups
   - Example: app=myapp, stack=prod
   
   **Advanced:**
   - Session Affinity: ClientIP or None
   - External Traffic Policy: Cluster or Local

4. Click **Create**

**For Kubernetes (Ingress):**
1. Click **Create Load Balancer** → **Ingress**
2. Configure:
   - **Ingress Class**: nginx, alb, etc.
   - **Rules**:
     - Host: myapp.example.com
     - Path: /
     - Backend Service: myapp-service
     - Backend Port: 80
   - **TLS**:
     - Add TLS certificate
     - Hosts: myapp.example.com

**Via API:**
```bash
# Create Kubernetes Service load balancer
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "upsertLoadBalancer",
      "application": "myapp",
      "account": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "namespace": "default",
      "manifest": {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
          "name": "myapp-service",
          "namespace": "default"
        },
        "spec": {
          "type": "LoadBalancer",
          "selector": {
            "app": "myapp"
          },
          "ports": [{
            "protocol": "TCP",
            "port": 80,
            "targetPort": 8080
          }]
        }
      }
    }],
    "application": "myapp",
    "description": "Create load balancer: myapp-service"
  }' \
  http://localhost:8084/tasks
```

---

### 4. Update Load Balancer

**Via UI:**
1. Go to **Load Balancers** tab
2. Click on the load balancer to update
3. Click **Load Balancer Actions** dropdown
4. Select **Edit**
5. Modify configuration:
   - Change port mappings
   - Update selectors
   - Modify health check settings
   - Add/remove annotations
6. Click **Update**
7. Monitor task in **Tasks** tab

**Via API:**
```bash
# Update load balancer (uses upsertLoadBalancer with modified manifest)
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "upsertLoadBalancer",
      "application": "myapp",
      "account": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "namespace": "default",
      "manifest": {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
          "name": "myapp-service",
          "namespace": "default"
        },
        "spec": {
          "type": "LoadBalancer",
          "selector": {
            "app": "myapp"
          },
          "ports": [{
            "protocol": "TCP",
            "port": 80,
            "targetPort": 9090
          }]
        }
      }
    }],
    "application": "myapp",
    "description": "Update load balancer: myapp-service"
  }' \
  http://localhost:8084/tasks
```

---

### 5. Delete Load Balancer

**Via UI:**
1. Navigate to **Load Balancers** tab
2. Click on the load balancer to delete
3. Click **Load Balancer Actions** dropdown
4. Select **Delete**
5. Confirm deletion dialog:
   - Warning: "Load balancer will be permanently deleted"
   - Type load balancer name to confirm
6. Click **Submit**
7. Monitor task completion

**Via API:**
```bash
# Delete load balancer
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "deleteLoadBalancer",
      "loadBalancerName": "myapp-service",
      "account": "my-k8s-account",
      "cloudProvider": "kubernetes",
      "namespace": "default",
      "user": "admin"
    }],
    "application": "myapp",
    "description": "Delete load balancer: myapp-service"
  }' \
  http://localhost:8084/tasks
```

**Warning:** Deleting a load balancer stops traffic to all associated server groups.

---

### 6. Attach Server Group to Load Balancer

**Via UI:**

**Method 1: From Server Group**
1. Go to **Clusters** tab
2. Click on a server group
3. Click **Server Group Actions** dropdown
4. Select **Edit**
5. In the **Load Balancers** section:
   - Select load balancers to attach
   - Click checkboxes for desired LBs
6. Click **Update**

**Method 2: From Pipeline Deploy Stage**
1. When deploying server group via pipeline
2. In Deploy stage configuration
3. **Load Balancers** section:
   - Select load balancers to attach
4. Save pipeline
5. Server group auto-attaches on deployment

**Via API:**
```bash
# Attach happens automatically via selector matching in Kubernetes
# For AWS/GCP, use registerInstancesWithLoadBalancer task

# For Kubernetes, ensure server group has matching labels
# Labels in Service selector must match pod labels
```

**Note:** In Kubernetes, attachment is automatic via label selectors. The Service's `selector` field matches pod labels.

---

### 7. Detach Server Group from Load Balancer

**Via UI:**
1. Go to **Clusters** tab
2. Click on the server group
3. Click **Server Group Actions** dropdown
4. Select **Edit**
5. In **Load Balancers** section:
   - Uncheck load balancers to detach
6. Click **Update**
7. Traffic will stop flowing to this server group

**Via API:**
```bash
# Detach by removing labels or using deregisterInstancesFromLoadBalancer

# For Kubernetes, modify pod labels to not match Service selector
# Or disable the server group (automatically removes from LB)
```

---

### 8. Get Load Balancer Health Status

**Via UI:**
1. Navigate to **Load Balancers** tab
2. Load balancer list shows health summary:
   - **Green**: All targets healthy
   - **Yellow**: Some targets unhealthy
   - **Red**: All targets unhealthy
3. Click load balancer for detailed health:
   - **Health** tab shows per-instance status
   - Instance name, status, reason

**Via API:**
```bash
# Get load balancer with health information
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/loadBalancers/my-k8s-account/default/myapp-lb" \
  | jq '.serverGroups[].instances[] | {name, health: .health[0].state}'

# Summary health across all instances
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/loadBalancers" \
  | jq '.[] | {name, healthy: .health.healthy, unhealthy: .health.unhealthy}'
```

---

### 9. Configure Health Checks

**Via UI:**
1. Go to **Load Balancers** tab
2. Click **Create Load Balancer** or **Edit** existing
3. In **Health Check** section (varies by provider):
   
   **For Kubernetes (via Probe in Pod Spec):**
   - Configured in server group deployment
   - Go to **Clusters** → Server Group → **Edit**
   - **Container** section:
     - **Liveness Probe**:
       - Type: HTTP, TCP, or Command
       - Path: /health
       - Port: 8080
       - Initial Delay: 30s
       - Period: 10s
     - **Readiness Probe**:
       - Path: /ready
       - Port: 8080
       - Initial Delay: 5s
       - Period: 5s
   
   **For AWS ALB/NLB:**
   - Protocol: HTTP, HTTPS, TCP
   - Path: /health
   - Port: 8080
   - Interval: 30s
   - Timeout: 5s
   - Healthy Threshold: 2
   - Unhealthy Threshold: 3

**Via API:**
```bash
# For Kubernetes, health checks are defined in pod spec (not Service)
# Include readiness/liveness probes in container manifest

# Example with readiness probe
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "createServerGroup",
      "application": "myapp",
      "manifest": {
        "spec": {
          "template": {
            "spec": {
              "containers": [{
                "name": "myapp",
                "image": "nginx:latest",
                "readinessProbe": {
                  "httpGet": {
                    "path": "/health",
                    "port": 8080
                  },
                  "initialDelaySeconds": 5,
                  "periodSeconds": 10
                }
              }]
            }
          }
        }
      }
    }]
  }' \
  http://localhost:8084/tasks
```

---

### 10. View Load Balancer Endpoints

**Via UI:**
1. Navigate to **Load Balancers** tab
2. Click on a load balancer
3. In the details panel:
   - **Type LoadBalancer**: Shows External IP or hostname
   - **Type NodePort**: Shows node IPs with NodePort
   - **Type ClusterIP**: Shows internal cluster IP
   - **Ingress**: Shows ingress hostname/IP
4. Copy endpoint to access application

**Via API:**
```bash
# Get load balancer endpoints
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/loadBalancers/my-k8s-account/default/myapp-lb" \
  | jq '{
    name: .name,
    type: .type,
    clusterIP: .clusterIp,
    externalIPs: .externalIps,
    loadBalancerIP: .loadBalancerIp,
    ingress: .ingress
  }'

# For all load balancers
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/loadBalancers" \
  | jq '.[] | {name, type, endpoints: .ingress}'
```

---

## 📝 Practical Examples

### Example 1: Create Complete Service with Load Balancer

```bash
#!/bin/bash
# Create application with server group and load balancer

APP="myapp"
ACCOUNT="my-k8s-account"
NAMESPACE="default"

echo "=== Creating Application Stack ==="
echo ""

# Step 1: Create load balancer (Service)
echo "1. Creating load balancer..."
LB_RESPONSE=$(curl -s -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "upsertLoadBalancer",
      "application": "'$APP'",
      "account": "'$ACCOUNT'",
      "cloudProvider": "kubernetes",
      "namespace": "'$NAMESPACE'",
      "manifest": {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
          "name": "'$APP'-service",
          "namespace": "'$NAMESPACE'"
        },
        "spec": {
          "type": "LoadBalancer",
          "selector": {
            "app": "'$APP'"
          },
          "ports": [{
            "protocol": "TCP",
            "port": 80,
            "targetPort": 8080
          }]
        }
      }
    }],
    "application": "'$APP'",
    "description": "Create load balancer"
  }' \
  http://localhost:8084/tasks)

LB_TASK_ID=$(echo "$LB_RESPONSE" | jq -r '.ref' | cut -d'/' -f2)
echo "Load balancer task: $LB_TASK_ID"

# Wait for completion
while true; do
  STATUS=$(curl -s -u admin:admin123 \
    http://localhost:8084/tasks/$LB_TASK_ID | jq -r '.status')
  echo "  Status: $STATUS"
  [[ "$STATUS" != "RUNNING" ]] && break
  sleep 3
done

# Step 2: Verify load balancer created
echo ""
echo "2. Verifying load balancer..."
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/loadBalancers" \
  | jq '.[] | {name, type, namespace: .region}'

echo ""
echo "✅ Load balancer created successfully!"
```

---

### Example 2: Update Load Balancer Port Mapping

```bash
#!/bin/bash
# Update load balancer to use different port

APP="myapp"
LB_NAME="myapp-service"
ACCOUNT="my-k8s-account"
NAMESPACE="default"

echo "=== Updating Load Balancer Port ==="
echo ""

# Get current configuration
echo "Current configuration:"
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/loadBalancers/$ACCOUNT/$NAMESPACE/$LB_NAME" \
  | jq '.ports'

# Update to new port
echo ""
echo "Updating to port 8080 → 9090..."
UPDATE_RESPONSE=$(curl -s -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "upsertLoadBalancer",
      "application": "'$APP'",
      "account": "'$ACCOUNT'",
      "cloudProvider": "kubernetes",
      "namespace": "'$NAMESPACE'",
      "manifest": {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
          "name": "'$LB_NAME'",
          "namespace": "'$NAMESPACE'"
        },
        "spec": {
          "type": "LoadBalancer",
          "selector": {
            "app": "'$APP'"
          },
          "ports": [{
            "protocol": "TCP",
            "port": 80,
            "targetPort": 9090
          }]
        }
      }
    }],
    "application": "'$APP'",
    "description": "Update load balancer port"
  }' \
  http://localhost:8084/tasks)

TASK_ID=$(echo "$UPDATE_RESPONSE" | jq -r '.ref' | cut -d'/' -f2)

# Wait for completion
while true; do
  STATUS=$(curl -s -u admin:admin123 \
    http://localhost:8084/tasks/$TASK_ID | jq -r '.status')
  [[ "$STATUS" != "RUNNING" ]] && break
  sleep 2
done

# Verify update
echo ""
echo "Updated configuration:"
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/loadBalancers/$ACCOUNT/$NAMESPACE/$LB_NAME" \
  | jq '.ports'

echo ""
echo "✅ Load balancer updated!"
```

---

### Example 3: Monitor Load Balancer Health

```bash
#!/bin/bash
# Monitor load balancer and target health

APP="myapp"

echo "=== Load Balancer Health Monitor ==="
echo ""

while true; do
  clear
  echo "=== $(date) ==="
  echo ""
  
  # Get all load balancers
  LBS=$(curl -s -u admin:admin123 \
    "http://localhost:8084/applications/$APP/loadBalancers")
  
  echo "Load Balancer Status:"
  echo "$LBS" | jq -r '.[] | 
    "  \(.name):
      Type: \(.type)
      Healthy: \(.health.healthy // 0)
      Unhealthy: \(.health.unhealthy // 0)
      Server Groups: \(.serverGroups | join(", "))
  "'
  
  # Detailed instance health
  echo ""
  echo "Instance Health:"
  echo "$LBS" | jq -r '.[] | 
    .serverGroups[] as $sg | 
    "  Server Group: \($sg)
    " + (.instances[]? | "    - \(.name): \(.health[0].state)")
  '
  
  echo ""
  echo "Press Ctrl+C to stop monitoring..."
  sleep 10
done
```

---

### Example 4: Load Balancer Summary Report

```bash
#!/bin/bash
# Generate comprehensive load balancer report

APP="myapp"

echo "=== Load Balancer Summary Report ==="
echo ""

LBS=$(curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/loadBalancers")

echo "Application: $APP"
echo "Total Load Balancers: $(echo "$LBS" | jq 'length')"
echo ""

echo "$LBS" | jq -r '.[] | 
  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Name: \(.name)
  Type: \(.type)
  Account: \(.account)
  Region: \(.region)
  
  Health Summary:
    Healthy Instances: \(.health.healthy // 0)
    Unhealthy Instances: \(.health.unhealthy // 0)
  
  Server Groups: \(.serverGroups | length)
    \(.serverGroups | join("\n    "))
  
  Endpoints:
    Cluster IP: \(.clusterIp // "N/A")
    External IPs: \(.externalIps[]? // "N/A")
    Load Balancer IP: \(.loadBalancerIp // "N/A")
  "
'
```

---

## 🐛 Troubleshooting

### Issue 1: Load balancer not receiving external IP
**Symptoms:** Service type LoadBalancer created but no external IP assigned
**Causes:**
- Cloud provider doesn't support LoadBalancer type
- Insufficient permissions
- Quota limits reached

**Solution:**
```bash
# Check service status
kubectl get service myapp-service -n default

# Check events
kubectl describe service myapp-service -n default

# For local/dev environments, use NodePort or port-forward instead
# Or use MetalLB for bare-metal load balancing
```

### Issue 2: Server group not showing in load balancer targets
**Cause:** Label selectors don't match
**Solution:**
```bash
# Check Service selector
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/loadBalancers/.../myapp-lb" \
  | jq '.selector'

# Check pod labels in server group
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/serverGroups/.../myapp-v001" \
  | jq '.labels'

# Labels must match exactly
```

### Issue 3: Health checks always failing
**Symptoms:** All instances marked unhealthy
**Causes:**
- Wrong health check path
- Wrong port
- Application not responding on health endpoint
- Initial delay too short

**Solution:**
```bash
# Test health endpoint directly
kubectl exec -it myapp-pod -- curl localhost:8080/health

# Check readiness probe configuration
kubectl describe pod myapp-pod | grep -A 10 "Readiness"

# Increase initial delay if app needs startup time
# Update readiness probe in server group manifest
```

### Issue 4: Cannot delete load balancer
**Cause:** Load balancer in use by server groups
**Solution:**
```bash
# Check attached server groups
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/loadBalancers/.../myapp-lb" \
  | jq '.serverGroups'

# Detach or destroy server groups first
# Then delete load balancer
```

---

## 📚 API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/applications/{app}/loadBalancers` | List all load balancers |
| GET | `/applications/{app}/loadBalancers/{account}/{region}/{name}` | Get load balancer details |
| POST | `/tasks` with `upsertLoadBalancer` | Create/update load balancer |
| POST | `/tasks` with `deleteLoadBalancer` | Delete load balancer |
| GET | `/loadBalancers/{account}/{region}/{name}` | Get LB by account/region |

**Note:** Load balancer attachment to server groups is typically automatic via label selectors (Kubernetes) or configured during server group deployment (AWS/GCP).

---

## 🎯 Load Balancer Types Comparison

| Feature | ClusterIP | NodePort | LoadBalancer | Ingress |
|---------|-----------|----------|--------------|---------|
| **Scope** | Internal | External | External | External |
| **Access** | Cluster only | Node IP:Port | Cloud LB IP | Domain name |
| **Use Case** | Microservices | Dev/Test | Production | HTTP routing |
| **Cost** | Free | Free | Cloud cost | Varies |
| **Protocols** | All | All | All | HTTP(S) |

---

## ✅ Verification Checklist

After completing this section, you should be able to:

- [ ] List all load balancers for an application
- [ ] Get detailed load balancer information
- [ ] Create a new load balancer (Service)
- [ ] Update load balancer configuration
- [ ] Delete a load balancer
- [ ] Attach server groups to load balancers
- [ ] Monitor load balancer health status
- [ ] Configure health checks
- [ ] View load balancer endpoints
- [ ] Troubleshoot load balancer issues

---

## 🎯 Next Steps

Congratulations! You've completed all 5 core Spinnaker features:

1. ✅ Applications Management
2. ✅ Pipelines
3. ✅ Tasks & Executions
4. ✅ Clusters & Server Groups
5. ✅ Load Balancers

**Continue Learning:**
- Explore advanced pipeline stages (canary, blue/green)
- Set up automated triggers (Git, Docker, webhook)
- Configure notifications (Slack, email)
- Implement deployment strategies
- Review security and RBAC configuration

---

## 📎 Postman Collection

**Collection:** Spinnaker API  
**Folder:** 05 - Load Balancers

**Requests:**
1. List application load balancers - `GET /applications/{app}/loadBalancers`
2. Get load balancer details - `GET /applications/{app}/loadBalancers/{account}/{region}/{name}`
3. Create load balancer - `POST /tasks` (upsertLoadBalancer)
4. Update load balancer - `POST /tasks` (upsertLoadBalancer)
5. Delete load balancer - `POST /tasks` (deleteLoadBalancer)
6. Get load balancer health - `GET /applications/{app}/loadBalancers` (with health data)

**Note:** Load balancer operations return task IDs. Use the Tasks endpoints to monitor operation status.
