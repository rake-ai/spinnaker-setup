# Feature 2: Pipelines

## 📋 Overview

**What is a Pipeline in Spinnaker?**
A Pipeline is an automated workflow that orchestrates deployment tasks. Pipelines can:
- Deploy applications to different environments
- Run tests and validations
- Trigger manual approvals
- Execute complex multi-stage deployments
- Chain together multiple actions

**Key Concepts:**
- **Stages:** Individual steps in a pipeline (deploy, wait, manual judgment, etc.)
- **Triggers:** What initiates a pipeline (manual, webhook, schedule, another pipeline)
- **Parameters:** Dynamic inputs that can be passed to a pipeline
- **Artifacts:** Files, images, or resources used/produced by pipelines

---

## 🎯 Prerequisites

- ✅ Spinnaker running
- ✅ At least one application created (see [01-applications.md](01-applications.md))
- ✅ Port forwards active
- ✅ Authentication working

---

## 📖 Step-by-Step Guide

### Option 1: Using the Web UI

**Step 1: Navigate to Pipelines**
```bash
# Access Spinnaker UI
http://localhost:9000

# 1. Select your application from the list
# 2. Click on "PIPELINES" tab
```

**Step 2: Create New Pipeline**
1. Click **"Configure a new pipeline"** or **"Create"** button
2. Fill in pipeline details:
   - **Pipeline Name:** `deploy-demo`
   - **Type:** Pipeline
3. Click **"Create"**

**Step 3: Add Stages**
1. Click **"Add stage"**
2. Select stage type (e.g., "Wait", "Manual Judgment", "Deploy")
3. Configure stage parameters
4. Click **"Save Changes"**

**Step 4: Configure Triggers (Optional)**
1. Go to **"Configuration"** tab
2. Click **"Add Trigger"**
3. Select trigger type (Manual, Webhook, etc.)
4. Configure trigger settings
5. Click **"Save Changes"**

**Step 5: Execute Pipeline**
1. Click **"Start Manual Execution"**
2. Provide any required parameters
3. Click **"Run"**

---

### Option 2: Using the REST API

**Step 1: Create a Simple Pipeline**

```bash
# Create a basic pipeline with Wait stage
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "application": "myapp",
    "name": "deploy-demo",
    "keepWaitingPipelines": false,
    "limitConcurrent": true,
    "stages": [
      {
        "name": "Wait",
        "refId": "1",
        "requisiteStageRefIds": [],
        "type": "wait",
        "waitTime": 30
      }
    ],
    "triggers": [],
    "parameterConfig": []
  }' \
  http://localhost:8084/pipelines

# Empty respose with 200 status code.
```

**Step 2: Verify Pipeline Created**

```bash
# Get all pipelines for application
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelineConfigs

# Get specific pipeline
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelineConfigs/deploy-demo
```

---

## 🔧 Common Operations

### 1. List All Pipeline Configurations

**API:**
```bash
# Get all pipeline configs for an application
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelineConfigs
```

**Expected Response:**
```json
[
  {
    "application": "myapp",
    "name": "deploy-demo",
    "id": "pipeline-id-123",
    "stages": [...],
    "triggers": [...],
    "lastModifiedBy": "admin",
    "updateTs": "1234567890000"
  }
]
```

---

### 2. Get Specific Pipeline Configuration

**API:**
```bash
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelineConfigs/deploy-demo
```

---

### 3. Update Pipeline Configuration

**Important:** To update a pipeline, you must first get its ID, then use POST (not PUT) with the ID in the request body.

**Step 1: Get Pipeline ID**
```bash
# Get the pipeline configuration to find its ID
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelineConfigs/deploy-demo | jq '.id'

# Example response: "fe817eb0-cba7-40a7-ac6d-701d013e7c8d"
```

**Step 2: Update Pipeline**
```bash
# Use POST (not PUT) with the actual pipeline ID
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "id": "fe817eb0-cba7-40a7-ac6d-701d013e7c8d",
    "application": "myapp",
    "name": "deploy-demo",
    "keepWaitingPipelines": false,
    "limitConcurrent": true,
    "stages": [
      {
        "name": "Wait 60 seconds",
        "refId": "1",
        "requisiteStageRefIds": [],
        "type": "wait",
        "waitTime": 60
      }
    ]
  }' \
  http://localhost:8084/pipelines
```

**Note:** 
- Method: **POST** (PUT returns 405 Method Not Allowed)
- Must include the actual pipeline `id` from Step 1
- Endpoint: `/pipelines` (same as create)

---

### 4. Delete Pipeline

**API:**
```bash
curl -u admin:admin123 \
  -X DELETE \
  http://localhost:8084/pipelines/myapp/deploy-demo
```

---

### 5. Trigger Pipeline Execution (Manual)

**API:**
```bash
# Start pipeline execution
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "type": "manual",
    "user": "admin"
  }' \
  http://localhost:8084/pipelines/myapp/deploy-demo

# Alternative endpoint
curl -u admin:admin123 \
  -X POST \
  http://localhost:8084/applications/myapp/pipelineConfigs/deploy-demo?user=admin
```

**Expected Response:**
```json
{
  "ref": "/pipelines/execution-id-456"
}
```

---

### 6. Get Pipeline Executions

**API:**
```bash
# Get all pipeline executions for application
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelines

# With filters
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/pipelines?limit=10&statuses=RUNNING,SUCCEEDED"
```

---

### 7. Get Specific Pipeline Execution

**API:**
```bash
# Get execution details
curl -u admin:admin123 \
  http://localhost:8084/pipelines/execution-id-456
```

---

### 8. Cancel Pipeline Execution

**API:**
```bash
# Cancel running pipeline
curl -u admin:admin123 \
  -X PUT \
  "http://localhost:8084/pipelines/execution-id-456/cancel?reason=Manual+cancellation"

# Or via application endpoint
curl -u admin:admin123 \
  -X PUT \
  "http://localhost:8084/applications/myapp/pipelines/execution-id-456/cancel?reason=Manual+cancellation"
```

---

### 9. Pause/Resume Pipeline Execution

**Pause:**
```bash
curl -u admin:admin123 \
  -X PUT \
  http://localhost:8084/pipelines/execution-id-456/pause
```

**Resume:**
```bash
curl -u admin:admin123 \
  -X PUT \
  http://localhost:8084/pipelines/execution-id-456/resume
```

---

### 10. Get Pipeline Execution Details (Including Logs)

**Note:** The `/logs` endpoint returns 405 Method Not Allowed. To get execution details and stage information, use the execution details endpoint instead.

**API:**
```bash
# Get full execution details including all stage information
curl -u admin:admin123 \
  http://localhost:8084/pipelines/execution-id-456

# Get specific stage details
curl -u admin:admin123 \
  http://localhost:8084/pipelines/execution-id-456 | jq '.stages[] | select(.name == "Stage Name")'

# For stages with logs (Jenkins, Script, etc.), check the stage context
curl -u admin:admin123 \
  http://localhost:8084/pipelines/execution-id-456 | jq '.stages[] | {name, type, status, context, outputs}'
```

**Note:** 
- Dedicated `/logs` endpoint is not supported (returns 405)
- Stage execution details are embedded in the execution response
- Only certain stage types (Jenkins, Script, etc.) produce logs in their context

---

### 11. Restart Failed Stage

**API:**
```bash
curl -u admin:admin123 \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{}' \
  http://localhost:8084/pipelines/execution-id-456/stages/stage-id-789/restart
```

---

## 📝 Pipeline Examples

### Example 1: Simple Wait Pipeline

```bash
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "application": "myapp",
    "name": "simple-wait",
    "keepWaitingPipelines": false,
    "limitConcurrent": true,
    "stages": [
      {
        "name": "Wait 30 seconds",
        "refId": "1",
        "requisiteStageRefIds": [],
        "type": "wait",
        "waitTime": 30
      }
    ]
  }' \
  http://localhost:8084/pipelines
```

---

### Example 2: Pipeline with Manual Judgment

```bash
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "application": "myapp",
    "name": "approval-pipeline",
    "stages": [
      {
        "name": "Wait for Approval",
        "refId": "1",
        "requisiteStageRefIds": [],
        "type": "manualJudgment",
        "instructions": "Please review and approve deployment",
        "judgmentInputs": [
          {"value": "continue"},
          {"value": "stop"}
        ],
        "notifications": []
      },
      {
        "name": "Proceed after approval",
        "refId": "2",
        "requisiteStageRefIds": ["1"],
        "type": "wait",
        "waitTime": 10
      }
    ]
  }' \
  http://localhost:8084/pipelines
```

---

### Example 3: Pipeline with Parameters

```bash
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "application": "myapp",
    "name": "parameterized-pipeline",
    "parameterConfig": [
      {
        "name": "environment",
        "label": "Environment",
        "description": "Target environment",
        "default": "dev",
        "hasOptions": true,
        "options": [
          {"value": "dev"},
          {"value": "staging"},
          {"value": "production"}
        ],
        "required": true
      },
      {
        "name": "version",
        "label": "Version",
        "description": "Application version",
        "default": "latest",
        "required": true
      }
    ],
    "stages": [
      {
        "name": "Display Parameters",
        "refId": "1",
        "requisiteStageRefIds": [],
        "type": "wait",
        "waitTime": 5,
        "comments": "Deploying ${parameters.version} to ${parameters.environment}"
      }
    ]
  }' \
  http://localhost:8084/pipelines
```

**Trigger with parameters:**
```bash
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "type": "manual",
    "user": "admin",
    "parameters": {
      "environment": "staging",
      "version": "v1.2.3"
    }
  }' \
  http://localhost:8084/pipelines/myapp/parameterized-pipeline
```

---

### Example 4: Multi-Stage Pipeline

```bash
curl -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "application": "myapp",
    "name": "multi-stage-pipeline",
    "stages": [
      {
        "name": "Stage 1: Preparation",
        "refId": "1",
        "requisiteStageRefIds": [],
        "type": "wait",
        "waitTime": 10
      },
      {
        "name": "Stage 2: Validation",
        "refId": "2",
        "requisiteStageRefIds": ["1"],
        "type": "wait",
        "waitTime": 10
      },
      {
        "name": "Stage 3: Deployment",
        "refId": "3",
        "requisiteStageRefIds": ["2"],
        "type": "wait",
        "waitTime": 10
      },
      {
        "name": "Stage 4: Verification",
        "refId": "4",
        "requisiteStageRefIds": ["3"],
        "type": "wait",
        "waitTime": 10
      }
    ]
  }' \
  http://localhost:8084/pipelines
```

---

## 📝 Hands-On Exercise

**Complete pipeline workflow:**

```bash
# 1. Create pipeline
PIPELINE_RESPONSE=$(curl -s -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "application": "myapp",
    "name": "test-pipeline",
    "stages": [{
      "name": "Wait",
      "refId": "1",
      "type": "wait",
      "waitTime": 15
    }]
  }' \
  http://localhost:8084/pipelines)

echo "Pipeline created"

# 2. Verify pipeline exists
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelineConfigs/test-pipeline

# 3. Execute pipeline
EXEC_RESPONSE=$(curl -s -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"type":"manual","user":"admin"}' \
  http://localhost:8084/pipelines/myapp/test-pipeline)

echo "Pipeline triggered: $EXEC_RESPONSE"

# 4. Get execution ID
EXEC_ID=$(echo $EXEC_RESPONSE | grep -o 'pipelines/[^"]*' | cut -d'/' -f2)
echo "Execution ID: $EXEC_ID"

# 5. Check execution status
curl -u admin:admin123 \
  http://localhost:8084/pipelines/$EXEC_ID | jq '.status'

# 6. Wait and check again
sleep 20
curl -u admin:admin123 \
  http://localhost:8084/pipelines/$EXEC_ID | jq '.status'
```

---

## 🐛 Troubleshooting

### Issue 1: "Pipeline not found"
**Cause:** Pipeline doesn't exist or incorrect name
**Solution:** 
```bash
# List all pipelines
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelineConfigs | jq '.[].name'
```

### Issue 2: Pipeline execution stuck
**Cause:** Stage waiting for input or failed
**Solution:**
```bash
# Check execution details
curl -u admin:admin123 \
  http://localhost:8084/pipelines/execution-id | jq '.stages'

# Cancel if needed
curl -u admin:admin123 -X PUT \
  "http://localhost:8084/pipelines/execution-id/cancel?reason=stuck"
```

### Issue 3: Cannot update pipeline
**Cause:** Missing pipeline ID in update request
**Solution:** Always include the pipeline ID when updating

### Issue 4: Stage fails immediately
**Cause:** Invalid stage configuration
**Solution:** Check stage type and required parameters match Spinnaker documentation

---

## 📚 API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/applications/{app}/pipelineConfigs` | List pipeline configs |
| GET | `/applications/{app}/pipelineConfigs/{name}` | Get specific config |
| POST | `/pipelines` | Create pipeline |
| POST | `/pipelines` | Update pipeline (include `id` in body) |
| DELETE | `/pipelines/{app}/{name}` | Delete pipeline |
| POST | `/pipelines/{app}/{name}` | Trigger execution |
| GET | `/applications/{app}/pipelines` | List executions |
| GET | `/pipelines/{id}` | Get execution details (includes stage info) |
| PUT | `/pipelines/{id}/cancel` | Cancel execution |
| PUT | `/pipelines/{id}/pause` | Pause execution |
| PUT | `/pipelines/{id}/resume` | Resume execution |
| PUT | `/pipelines/{id}/stages/{stageId}/restart` | Restart stage |

**Note:** `/pipelines/{id}/logs` endpoint is not supported (returns 405). Use `GET /pipelines/{id}` for execution and stage details.

---

## 📊 Common Stage Types

| Stage Type | Description | Use Case |
|------------|-------------|----------|
| `wait` | Pause for specified time | Delays, cool-downs |
| `manualJudgment` | Wait for human approval | Approval gates |
| `deploy` | Deploy server group | Application deployment |
| `destroyServerGroup` | Terminate server group | Cleanup |
| `pipeline` | Trigger another pipeline | Complex workflows |
| `webhook` | Call external HTTP endpoint | Integrations |
| `script` | Run custom script | Custom logic |
| `jenkins` | Trigger Jenkins job | CI/CD integration |
| `checkPreconditions` | Validate conditions | Safety checks |

---

## ✅ Verification Checklist

After completing this section, you should be able to:

- [ ] Create a pipeline via UI
- [ ] Create a pipeline via API
- [ ] List all pipelines for an application
- [ ] Trigger a pipeline execution
- [ ] Monitor pipeline execution status
- [ ] Cancel a running pipeline
- [ ] Update pipeline configuration
- [ ] Create multi-stage pipelines
- [ ] Use pipeline parameters

---

## 🎯 Next Steps

Once you're comfortable with pipelines, proceed to:
- **[03-tasks-executions.md](03-tasks-executions.md)** - Monitor tasks and executions

---

## 📎 Postman Collection

**Collection:** Spinnaker API
**Folder:** 02 - Pipelines

**Requests to add:**
1. List pipeline configs - `GET /applications/{app}/pipelineConfigs`
2. Get pipeline config - `GET /applications/{app}/pipelineConfigs/{name}`
3. Create pipeline - `POST /pipelines`
4. Update pipeline - `POST /pipelines` (include `id` in body)
5. Delete pipeline - `DELETE /pipelines/{app}/{name}`
6. Trigger pipeline - `POST /pipelines/{app}/{name}`
7. List executions - `GET /applications/{app}/pipelines`
8. Get execution details - `GET /pipelines/{id}` (includes stage info and logs)
9. Cancel execution - `PUT /pipelines/{id}/cancel`
10. Pause execution - `PUT /pipelines/{id}/pause`
11. Resume execution - `PUT /pipelines/{id}/resume`

**Note:** The `/logs` endpoint is not supported. Use request #8 (Get execution details) to access stage information and logs.
