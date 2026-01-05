# Feature 3: Tasks & Executions

## 📋 Overview

**What are Tasks and Executions in Spinnaker?**

Tasks and executions are the core operational units in Spinnaker:

- **Tasks:** Atomic operations that Spinnaker performs (create application, deploy, resize, etc.)
- **Executions:** Pipeline runs that consist of multiple stages and tasks
- Both provide detailed information about what Spinnaker is doing and the results

**Key Concepts:**
- **Task Status:** NOT_STARTED, RUNNING, SUCCEEDED, TERMINAL, CANCELED
- **Execution Status:** Same as task status, plus PAUSED, SUSPENDED
- **Task Context:** Details about what the task is doing
- **Execution History:** Complete audit trail of all operations
- **Correlation IDs:** Link related tasks and executions

---

## 🎯 Prerequisites

- ✅ Spinnaker running
- ✅ At least one application created
- ✅ At least one pipeline created
- ✅ Port forwards active
- ✅ Authentication working

---

## 📖 Understanding Tasks vs Executions

### Tasks
- **What:** Individual operations (create app, deploy instance, etc.)
- **Created by:** Both manual actions and pipeline stages
- **Visibility:** Application-level task list
- **Duration:** Usually seconds to minutes
- **Use case:** Track infrastructure changes

### Executions
- **What:** Pipeline runs with multiple stages
- **Created by:** Pipeline triggers (manual, webhook, schedule, etc.)
- **Visibility:** Pipeline execution history
- **Duration:** Minutes to hours
- **Use case:** Track deployment workflows

---

## 🔧 Common Operations

### 1. List All Tasks for an Application

**API:**
```bash
# Get recent tasks for an application
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/tasks

# With limit
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/tasks?limit=20"

# Filter by status
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/tasks?statuses=RUNNING,TERMINAL"
```

**Expected Response:**
```json
[
  {
    "id": "01KDYFV80J5DZEBWXAJ4GXKMB5",
    "application": "myapp",
    "name": "Create Application",
    "startTime": 1735789200000,
    "endTime": 1735789205000,
    "status": "SUCCEEDED",
    "execution": {
      "type": "orchestration",
      "stages": [...]
    }
  }
]
```

---

### 2. Get Specific Task Details

**API:**
```bash
# Get task by ID
curl -u admin:admin123 \
  http://localhost:8084/tasks/01KDYFV80J5DZEBWXAJ4GXKMB5
```

**Response includes:**
- Task status and timing
- All stages and their status
- Context (parameters, outputs)
- Error messages (if failed)

---

### 3. Get Task by Correlation ID

**API:**
```bash
# Find task by correlation ID
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/tasks?correlationId=my-deploy-123"
```

**Use case:** Track related operations across multiple tasks

---

### 4. List Pipeline Executions

**API:**
```bash
# Get all pipeline executions for an application
curl -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelines

# With limit
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/pipelines?limit=10"

# Filter by status
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/pipelines?statuses=RUNNING"

# Filter by pipeline name
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/pipelines?pipelineConfigIds=deploy-pipeline"
```

---

### 5. Get Pipeline Execution Details

**API:**
```bash
# Get full execution details
curl -u admin:admin123 \
  http://localhost:8084/pipelines/01KDYFV80J5DZEBWXAJ4GXKMB5

# Get execution summary (less data)
curl -u admin:admin123 \
  http://localhost:8084/pipelines/01KDYFV80J5DZEBWXAJ4GXKMB5 \
  | jq '{id, status, startTime, endTime, name, application}'

# Get stage details
curl -u admin:admin123 \
  http://localhost:8084/pipelines/01KDYFV80J5DZEBWXAJ4GXKMB5 \
  | jq '.stages[] | {name, type, status, startTime, endTime}'
```

---

### 6. Get Execution by Correlation ID

**API:**
```bash
# Find execution by correlation ID
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/pipelines/search?q=correlationId:my-deploy-123"
```

---

### 7. Monitor Running Executions

**API:**
```bash
# Get all running executions
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/pipelines?statuses=RUNNING" \
  | jq '.[] | {id, name, startTime, status}'

# Poll execution status
while true; do
  STATUS=$(curl -s -u admin:admin123 \
    http://localhost:8084/pipelines/01KDYFV80J5DZEBWXAJ4GXKMB5 \
    | jq -r '.status')
  echo "Status: $STATUS"
  [[ "$STATUS" != "RUNNING" ]] && break
  sleep 5
done
```

---

### 8. Get Execution History for a Pipeline

**API:**
```bash
# Get executions for specific pipeline configuration (using filter)
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/pipelines?pipelineConfigIds=deploy-demo&limit=20"

# Note: The /pipelineConfigs/{name}/history endpoint returns 404
# Use the pipelines endpoint with pipelineConfigIds filter instead
```

---

### 9. Cancel a Running Task or Execution

**Task:**
```bash
# Cancel a task
curl -u admin:admin123 \
  -X PUT \
  http://localhost:8084/tasks/01KDYFV80J5DZEBWXAJ4GXKMB5/cancel
```

**Execution:**
```bash
# Cancel pipeline execution
curl -u admin:admin123 \
  -X PUT \
  "http://localhost:8084/pipelines/01KDYFV80J5DZEBWXAJ4GXKMB5/cancel?reason=User+requested"
```

---

### 10. Get Failed Tasks/Executions

**API:**
```bash
# Get failed tasks
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/tasks?statuses=TERMINAL&limit=10" \
  | jq '.[] | {id, name, status, endTime}'

# Get failed pipeline executions
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/pipelines?statuses=TERMINAL&limit=10" \
  | jq '.[] | {id, name, status, endTime, buildTime}'
```

---

### 11. Get Task Metrics

**API:**
```bash
# Get task timing information
curl -u admin:admin123 \
  http://localhost:8084/tasks/01KDYFV80J5DZEBWXAJ4GXKMB5 \
  | jq '{
    id,
    status,
    startTime,
    endTime,
    duration: (.endTime - .startTime),
    stages: [.execution.stages[] | {
      name,
      status,
      duration: (.endTime - .startTime)
    }]
  }'
```

---

### 12. Retry Failed Stage

**API:**
```bash
# Restart a failed stage in an execution
curl -u admin:admin123 \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{}' \
  http://localhost:8084/pipelines/01KDYFV80J5DZEBWXAJ4GXKMB5/stages/stage-id/restart
```

---

## 📝 Practical Examples

### Example 1: Monitor Application Activity

```bash
#!/bin/bash
# Monitor all activity for an application

APP="myapp"
LIMIT=20

echo "=== Recent Tasks for $APP ==="
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/tasks?limit=$LIMIT" \
  | jq -r '.[] | "\(.startTime | strftime("%Y-%m-%d %H:%M:%S")) - \(.name) - \(.status)"'

echo -e "\n=== Recent Pipeline Executions for $APP ==="
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/pipelines?limit=$LIMIT" \
  | jq -r '.[] | "\(.startTime | strftime("%Y-%m-%d %H:%M:%S")) - \(.name) - \(.status)"'
```

---

### Example 2: Track Pipeline Execution to Completion

```bash
#!/bin/bash
# Track a pipeline execution until it completes

EXEC_ID="$1"

if [ -z "$EXEC_ID" ]; then
  echo "Usage: $0 <execution-id>"
  exit 1
fi

echo "Tracking execution: $EXEC_ID"
echo "---"

while true; do
  RESPONSE=$(curl -s -u admin:admin123 \
    http://localhost:8084/pipelines/$EXEC_ID)
  
  STATUS=$(echo "$RESPONSE" | jq -r '.status')
  NAME=$(echo "$RESPONSE" | jq -r '.name')
  
  echo "[$(date '+%H:%M:%S')] $NAME - $STATUS"
  
  # Show stage progress
  echo "$RESPONSE" | jq -r '.stages[] | "  - \(.name): \(.status)"'
  
  # Check if complete
  if [[ "$STATUS" != "RUNNING" && "$STATUS" != "PAUSED" ]]; then
    echo "---"
    echo "Execution completed with status: $STATUS"
    
    # Show summary
    echo "$RESPONSE" | jq '{
      id,
      name,
      status,
      startTime,
      endTime,
      duration: (.endTime - .startTime) / 1000,
      stages: [.stages[] | {name, status}]
    }'
    
    break
  fi
  
  echo "---"
  sleep 5
done
```

---

### Example 3: Find and Analyze Failed Executions

```bash
#!/bin/bash
# Find failed executions and extract error information

APP="myapp"

echo "=== Failed Pipeline Executions for $APP ==="
echo ""

curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/pipelines?statuses=TERMINAL&limit=10" \
  | jq -r '.[] | 
    {
      id,
      name,
      status,
      startTime: (.startTime | strftime("%Y-%m-%d %H:%M:%S")),
      failedStages: [.stages[] | select(.status == "TERMINAL" or .status == "FAILED") | .name]
    } | 
    "ID: \(.id)\nPipeline: \(.name)\nTime: \(.startTime)\nFailed Stages: \(.failedStages | join(", "))\n---"'

# Get detailed error for a specific execution
read -p "Enter execution ID for details (or press Enter to skip): " EXEC_ID

if [ ! -z "$EXEC_ID" ]; then
  echo ""
  echo "=== Detailed Error Information ==="
  curl -s -u admin:admin123 \
    http://localhost:8084/pipelines/$EXEC_ID \
    | jq '.stages[] | select(.status == "TERMINAL" or .status == "FAILED") | {
      stage: .name,
      type: .type,
      status: .status,
      context: .context,
      tasks: [.tasks[]? | select(.status == "FAILED") | {
        name,
        status,
        exception: .exception?
      }]
    }'
fi
```

---

### Example 4: Compare Execution Performance

```bash
#!/bin/bash
# Compare performance of recent pipeline executions

APP="myapp"
PIPELINE="deploy-demo"
LIMIT=5

echo "=== Performance Comparison for $PIPELINE ==="
echo ""

curl -s -u admin:admin123 \
  "http://localhost:8084/applications/$APP/pipelines?limit=$LIMIT" \
  | jq --arg pipeline "$PIPELINE" '.[] | select(.name == $pipeline) | {
    id,
    status,
    startTime: (.startTime | strftime("%Y-%m-%d %H:%M:%S")),
    duration_seconds: ((.endTime - .startTime) / 1000),
    stages: [.stages[] | {
      name,
      duration_seconds: ((.endTime - .startTime) / 1000)
    }]
  }'
```

---

## 📝 Hands-On Exercise

**Complete monitoring workflow:**

```bash
# 1. List recent activity
echo "Step 1: List recent tasks"
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/myapp/tasks?limit=5" \
  | jq '.[] | {id, name, status, startTime}'

# 2. Trigger a pipeline
echo -e "\nStep 2: Trigger pipeline"
TRIGGER_RESPONSE=$(curl -s -u admin:admin123 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"type":"manual","user":"admin"}' \
  http://localhost:8084/pipelines/myapp/deploy-demo)

echo "$TRIGGER_RESPONSE"

# 3. Extract execution ID
EXEC_ID=$(echo "$TRIGGER_RESPONSE" | grep -o 'pipelines/[^"]*' | cut -d'/' -f2)
echo "Execution ID: $EXEC_ID"

# 4. Monitor execution
echo -e "\nStep 3: Monitor execution"
for i in {1..10}; do
  STATUS=$(curl -s -u admin:admin123 \
    http://localhost:8084/pipelines/$EXEC_ID \
    | jq -r '.status')
  echo "[$i] Status: $STATUS"
  [[ "$STATUS" != "RUNNING" ]] && break
  sleep 5
done

# 5. Get final results
echo -e "\nStep 4: Get execution details"
curl -s -u admin:admin123 \
  http://localhost:8084/pipelines/$EXEC_ID \
  | jq '{
    id,
    name,
    status,
    duration: ((.endTime - .startTime) / 1000),
    stages: [.stages[] | {name, status, duration: ((.endTime - .startTime) / 1000)}]
  }'

# 6. Check application task history
echo -e "\nStep 5: Check task history"
curl -s -u admin:admin123 \
  "http://localhost:8084/applications/myapp/tasks?limit=3" \
  | jq '.[] | {id, name, status, startTime}'
```

---

## 🐛 Troubleshooting

### Issue 1: Task stuck in RUNNING state
**Cause:** Backend service issue or timeout
**Solution:**
```bash
# Check Orca logs (orchestration service)
kubectl logs -n spinnaker deployment/spin-orca --tail=100

# Cancel the task if needed
curl -u admin:admin123 -X PUT \
  http://localhost:8084/tasks/{task-id}/cancel
```

### Issue 2: Cannot find execution by ID
**Cause:** Execution ID incorrect or execution purged
**Solution:**
```bash
# Search by pipeline name
curl -u admin:admin123 \
  "http://localhost:8084/applications/myapp/pipelines?limit=50" \
  | jq '.[] | select(.name == "deploy-demo") | {id, startTime, status}'

# Check if execution is very old (may be purged)
```

### Issue 3: Execution details too large
**Cause:** Pipeline has many stages or large context
**Solution:**
```bash
# Get summary only
curl -u admin:admin123 \
  http://localhost:8084/pipelines/{execution-id} \
  | jq 'del(.stages[].context, .stages[].outputs)'

# Or get specific fields
curl -u admin:admin123 \
  http://localhost:8084/pipelines/{execution-id} \
  | jq '{id, name, status, stages: [.stages[] | {name, type, status}]}'
```

### Issue 4: Missing task history
**Cause:** Tasks older than retention period
**Solution:** 
- Spinnaker has a default retention period for execution history
- Configure in `orca` service settings for longer retention
- Export important execution data periodically

---

## 📚 API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/applications/{app}/tasks` | List tasks for application |
| GET | `/tasks/{id}` | Get task details |
| PUT | `/tasks/{id}/cancel` | Cancel a task |
| GET | `/applications/{app}/pipelines` | List pipeline executions (filter with `pipelineConfigIds` param) |
| GET | `/pipelines/{id}` | Get execution details |
| PUT | `/pipelines/{id}/cancel` | Cancel execution |
| PUT | `/pipelines/{id}/pause` | Pause execution |
| PUT | `/pipelines/{id}/resume` | Resume execution |
| PUT | `/pipelines/{id}/stages/{stageId}/restart` | Restart stage |

**Note:** The `/applications/{app}/pipelineConfigs/{name}/history` endpoint returns 404. Use `/applications/{app}/pipelines?pipelineConfigIds={name}` instead.

---

## 📊 Task/Execution Status Values

| Status | Meaning | Can Transition To |
|--------|---------|-------------------|
| NOT_STARTED | Queued, waiting | RUNNING |
| RUNNING | Currently executing | SUCCEEDED, TERMINAL, CANCELED, PAUSED |
| SUCCEEDED | Completed successfully | (final) |
| TERMINAL | Failed | (final, can restart) |
| CANCELED | User canceled | (final) |
| PAUSED | Manually paused | RUNNING, CANCELED |
| SUSPENDED | Waiting for condition | RUNNING, CANCELED |

---

## ✅ Verification Checklist

After completing this section, you should be able to:

- [ ] List all tasks for an application
- [ ] Get details of a specific task
- [ ] Monitor running tasks and executions
- [ ] List pipeline executions
- [ ] Track a pipeline execution to completion
- [ ] Get execution history for a pipeline
- [ ] Find failed executions and analyze errors
- [ ] Cancel running tasks/executions
- [ ] Calculate execution duration and performance
- [ ] Use correlation IDs to track related operations

---

## 🎯 Next Steps

Once you're comfortable with tasks and executions, proceed to:
- **[04-clusters-servergroups.md](04-clusters-servergroups.md)** - Manage infrastructure deployments

---

## 📎 Postman Collection

**Collection:** Spinnaker API
**Folder:** 03 - Tasks & Executions

**Requests:**
1. List application tasks - `GET /applications/{app}/tasks`
2. Get task details - `GET /tasks/{id}`
3. Cancel task - `PUT /tasks/{id}/cancel`
4. Get pipeline execution history - `GET /applications/{app}/pipelines?pipelineConfigIds={name}`
5. Search by correlation ID - `GET /applications/{app}/pipelines/search?q=correlationId:{id}`
6. Get failed tasks - `GET /applications/{app}/tasks?statuses=TERMINAL`
7. Restart failed stage - `PUT /pipelines/{id}/stages/{stageId}/restart`

**Note:** Additional execution management requests (list executions, get details, cancel, pause, resume) are available in the "02 - Pipelines" folder.
