# Feature 1: Applications Management

## 📋 Overview

**What is an Application in Spinnaker?**
An Application is the fundamental organizational unit in Spinnaker. It groups together:
- Pipelines
- Clusters and Server Groups
- Load Balancers
- Security Groups
- Infrastructure resources

Think of it as a project or microservice that you want to deploy and manage.

---

## 🎯 Prerequisites

- ✅ Spinnaker running (verify with `./verify-setup.sh`)
- ✅ Port forwards active (Gate: 8084, Deck: 9000)
- ✅ Authentication working (admin/admin123)

---

## 📖 Step-by-Step Guide

### Option 1: Using the Web UI

**Step 1: Access Spinnaker UI**
```bash
# Open in browser
http://localhost:9000

# Login with: admin / admin123
```

**Step 2: Create New Application**
1. Click **"Actions"** → **"Create Application"** (top right)
2. Fill in application details:
   - **Name:** `myapp` (lowercase, no spaces)
   - **Owner Email:** `admin@example.com`
   - **Description:** `My first Spinnaker application`
   - **Consider only cloud provider health:** Unchecked (for now)
3. Click **"Create"**

**Step 3: Verify Application**
- You should see your application in the applications list
- Click on the application name to view details

---

### Option 2: Using the REST API

**Step 1: Create Application via API**

```bash
# Create application using task endpoint
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "createApplication",
      "application": {
        "name": "myapp",
        "email": "admin@example.com",
        "cloudProviders": "kubernetes",
        "description": "My first Spinnaker application",
        "instancePort": 80,
        "platformHealthOnly": false,
        "platformHealthOnlyShowOverride": false
      },
      "user": "admin"
    }],
    "application": "myapp",
    "description": "Create Application: myapp"
  }' \
  http://localhost:8084/tasks

# Response will include a task ID
# Example: {"ref":"/tasks/01JGXXX"}
```

**Step 2: Check Task Status**

```bash
# Get the task ID from the response above
# Example: {"ref":"/tasks/01JGXXX"}

# Check task status
curl -u admin:admin123 http://localhost:8084/tasks/01JGXXX

# Wait for task to complete (status: "SUCCEEDED")
```

**Step 3: Verify Application Created**

```bash
# List all applications
curl -u admin:admin123 http://localhost:8084/applications

# Get specific application details
curl -u admin:admin123 http://localhost:8084/applications/myapp
```

---

## 🔧 Common Operations

### 1. List All Applications

**API:**
```bash
curl -u admin:admin123 http://localhost:8084/applications
```

**Expected Response:**
```json
[
  {
    "name": "myapp",
    "email": "admin@example.com",
    "description": "My first Spinnaker application",
    "createTs": "1234567890000",
    "updateTs": "1234567890000"
  }
]
```

---

### 2. Get Application Details

**API:**
```bash
curl -u admin:admin123 http://localhost:8084/applications/myapp
```

**With expanded details:**
```bash
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp?expand=true"
```

**Expected Response:**
```json
{
  "name": "myapp",
  "attributes": {
    "email": "admin@example.com",
    "description": "My first Spinnaker application",
    "cloudProviders": "kubernetes"
  },
  "clusters": [],
  "clusterNames": {},
  "pipelineConfigs": [],
  "strategyConfigs": []
}
```

---

### 3. Update Application

**API:**
```bash
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "updateApplication",
      "application": {
        "name": "myapp",
        "email": "newemail@example.com",
        "description": "Updated description"
      },
      "user": "admin"
    }],
    "application": "myapp",
    "description": "Update Application: myapp"
  }' \
  http://localhost:8084/tasks
```

---

### 4. Get Application History

**API:**
```bash
# Get revision history (last 20 by default)
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/history

# Get more revisions
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/history?limit=50"
```

---

### 5. Get Application's Pipelines

**API:**
```bash
# Get all pipeline configurations
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelineConfigs

# Get pipeline executions
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelines
```

---

### 6. Get Application's Tasks

**API:**
```bash
# Get all tasks
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/tasks

# Get tasks with limit and status filter
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/tasks?limit=10&statuses=RUNNING,SUCCEEDED"
```

---

### 7. Get Application's Clusters

**API:**
```bash
# Get all clusters
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/clusters

# Get clusters for specific account
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/clusters/my-k8s-account
```

---

### 8. Search Applications

**API:**
```bash
# Search by name
curl -u admin:admin123 \
  "http://localhost:8084/search?q=myapp&type=applications"
```

---

## 📝 Hands-On Exercise

**Create your first application:**

```bash
# 1. Create application
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "job": [{
      "type": "createApplication",
      "application": {
        "name": "demoapp",
        "email": "demo@example.com",
        "cloudProviders": "kubernetes",
        "description": "Demo application for testing"
      },
      "user": "admin"
    }],
    "application": "demoapp",
    "description": "Create Application: demoapp"
  }' \
  http://localhost:8084/tasks

# 2. Verify it was created
curl -u admin:admin123 http://localhost:8084/applications/demoapp

# 3. List all applications
curl -u admin:admin123 http://localhost:8084/applications | jq '.[].name'

# 4. Get application history
curl -u admin:admin123 http://localhost:8084/applications/demoapp/history
```

---

## 🐛 Troubleshooting

### Issue 1: "Application already exists"
**Cause:** Application name is already in use
**Solution:** Choose a different name or delete the existing application first

### Issue 2: "401 Unauthorized"
**Cause:** Missing or incorrect authentication
**Solution:** Verify credentials and authentication setup:
```bash
curl -u admin:admin123 http://localhost:8084/auth/user
```

### Issue 3: "502 Bad Gateway" or connection refused
**Cause:** Port-forward not running or Gate service down
**Solution:** 
```bash
# Check port-forward
ps aux | grep "port-forward.*spin-gate"

# Restart if needed
pkill -f "port-forward.*spin-gate"
kubectl -n spinnaker port-forward svc/spin-gate 8084:80 &

# Verify Gate is running
kubectl -n spinnaker get pod -l app=spin-gate
```

### Issue 4: Application not showing in UI
**Cause:** UI cache or refresh needed
**Solution:** 
- Refresh the browser (Ctrl+F5 or Cmd+Shift+R)
- Clear browser cache
- Check Deck logs: `kubectl -n spinnaker logs deployment/spin-deck`

---

## 📚 API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/applications` | List all applications |
| GET | `/applications/{app}` | Get application details |
| GET | `/applications/{app}/history` | Get application history |
| POST | `/tasks` | Create application (via task) |
| PATCH | `/applications/{app}/tasks` | Update application |
| GET | `/applications/{app}/pipelineConfigs` | Get pipeline configs |
| GET | `/applications/{app}/pipelines` | Get pipeline executions |
| GET | `/applications/{app}/tasks` | Get application tasks |
| GET | `/applications/{app}/clusters` | Get application clusters |
| GET | `/search?q={name}&type=applications` | Search applications |

---

## ✅ Verification Checklist

After completing this section, you should be able to:

- [ ] Create an application via UI
- [ ] Create an application via API
- [ ] List all applications
- [ ] Get application details
- [ ] View application history
- [ ] Search for applications

---

## 🎯 Next Steps

Once you're comfortable with applications, proceed to:
- **[02-pipelines.md](02-pipelines.md)** - Create deployment pipelines

---

## 📎 Postman Collection

**Collection:** Spinnaker API
**Folder:** 01 - Applications

**Requests to add:**
1. List all applications - `GET /applications`
2. Create application - `POST /tasks`
3. Get application details - `GET /applications/{app}`
4. Get application history - `GET /applications/{app}/history`
5. Get pipelines - `GET /applications/{app}/pipelineConfigs`
6. Get tasks - `GET /applications/{app}/tasks`
7. Get clusters - `GET /applications/{app}/clusters`
8. Search applications - `GET /search`
