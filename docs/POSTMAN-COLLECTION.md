# Spinnaker API - Postman Collection

This document provides information about the Spinnaker API Postman collection for testing and integration.

## Collection Overview

The collection includes **22 API requests** organized into 3 folders:

### 📁 01 - Applications (9 requests)
- List All Applications
- Create Application ✅ Tested
- Get Task Status
- Get Application Details ✅ Tested
- Get Application History
- List Application Pipelines
- List Application Tasks
- Update Application
- Search Applications

### 📁 02 - Pipelines (11 requests)
- List Pipeline Configurations
- Create Simple Pipeline
- Create Manual Judgment Pipeline
- Create Parameterized Pipeline
- Update Pipeline Configuration
- Delete Pipeline
- Trigger Pipeline Execution
- List Pipeline Executions
- Get Pipeline Execution Details
- Cancel Pipeline Execution
- Pause Pipeline Execution
- Resume Pipeline Execution

### 📁 System (2 requests)
- Health Check
- Version Info

## Import Instructions

### Method 1: Import JSON File
1. Open Postman
2. Click **Import** button (top left)
3. Select the file: `Spinnaker-API.postman_collection.json`
4. Click **Import**
5. Collection will appear in your workspace

### Method 2: Direct API Import (if available in Postman)
The collection is already created in your Postman workspace:
- Collection ID: `4d797f28-0345-4170-b94d-3feb25d3f538`
- Workspace: `Xl-Integrations`

## Configuration

### 1. Variables
The collection includes one variable:

| Variable | Value | Description |
|----------|-------|-------------|
| `{{baseUrl}}` | `http://localhost:8084` | Spinnaker Gate API base URL |

**To modify:**
1. Click on the collection name
2. Go to **Variables** tab
3. Update `baseUrl` value if your Spinnaker is running on a different port

### 2. Authentication
Pre-configured with **Basic Auth**:
- Username: `admin`
- Password: `admin123`

**Authentication is set at the collection level**, so all requests inherit it automatically.

**To modify:**
1. Click on the collection name
2. Go to **Authorization** tab
3. Update credentials

## Getting Started

### Prerequisites
Ensure Spinnaker is running:
```bash
# Check services
kubectl get pods -n spinnaker

# Verify port forwards are active
# Gate API should be on localhost:8084
# Deck UI should be on localhost:9000

# Test connection
curl -u admin:admin123 http://localhost:8084/health
```

### Quick Test Workflow

#### 1. **Verify Connection**
- Run: `System` → `Health Check`
- Expected: `{"status":"UP"}`

#### 2. **Create Your First Application**
- Open: `01 - Applications` → `Create Application`
- Edit the body to change the application name:
  ```json
  {
    "job": [{
      "type": "createApplication",
      "application": {
        "name": "demo-app",  // Change this
        "email": "your@email.com",  // Change this
        "cloudProviders": "kubernetes",
        "description": "Demo application"
      },
      "user": "admin"
    }],
    "application": "demo-app",  // Change this
    "description": "Create Application: demo-app"
  }
  ```
- Click **Send**
- Response will include a task reference: `{"ref":"/tasks/01234567-89ab-cdef"}`
- Copy the task ID (the part after `/tasks/`)

#### 3. **Check Task Status**
- Open: `01 - Applications` → `Get Task Status`
- Replace `:taskId` in URL with your task ID
- Click **Send**
- Wait until `status` shows `SUCCEEDED`

#### 4. **List Applications**
- Run: `01 - Applications` → `List All Applications`
- Your new application should appear in the list

#### 5. **Create a Simple Pipeline**
- Open: `02 - Pipelines` → `Create Simple Pipeline`
- Update the `application` field to match your app name
- Click **Send**

#### 6. **Trigger Pipeline**
- Open: `02 - Pipelines` → `Trigger Pipeline Execution`
- Update URL to use your app and pipeline name
- Click **Send**

## API Request Details

### Applications

#### Create Application
**Important:** Applications must be created using the Spinnaker task format:
```json
{
  "job": [{
    "type": "createApplication",
    "application": {
      "name": "myapp",
      "email": "admin@example.com",
      "cloudProviders": "kubernetes",
      "description": "My application"
    },
    "user": "admin"
  }],
  "application": "myapp",
  "description": "Create Application: myapp"
}
```

**Returns:** `{"ref": "/tasks/{taskId}"}`

**Next Step:** Use the task ID with "Get Task Status" to verify creation.

#### Naming Conventions
- Application names: lowercase, alphanumeric, hyphens allowed
- Pipeline names: any characters, but avoid special characters
- Stage refIds: unique within a pipeline, typically sequential numbers

### Pipelines

#### Pipeline Structure
Every pipeline requires:
1. **application** - Parent application name
2. **name** - Pipeline name (must be unique within the application)
3. **stages** - Array of stage objects

#### Stage Dependencies
Use `requisiteStageRefIds` to create dependencies:
```json
{
  "stages": [
    {
      "refId": "1",
      "type": "wait"
    },
    {
      "refId": "2",
      "type": "manualJudgment",
      "requisiteStageRefIds": ["1"]  // Stage 2 waits for stage 1
    }
  ]
}
```

#### Pipeline Parameters
For dynamic pipelines, add `parameterConfig`:
```json
{
  "parameterConfig": [
    {
      "name": "environment",
      "label": "Environment",
      "required": true,
      "default": "dev",
      "options": [
        {"value": "dev"},
        {"value": "staging"},
        {"value": "prod"}
      ]
    }
  ]
}
```

Use parameters in stages: `${parameters.environment}`

## Testing Tips

### 1. Use Postman Tests
Add test scripts to validate responses automatically:

```javascript
// Test for successful response
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

// Test application creation returned a task
pm.test("Task reference returned", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.ref).to.include("/tasks/");
});
```

### 2. Use Environment Variables
Store dynamic values for reuse:

```javascript
// After creating application, save task ID
var response = pm.response.json();
var taskId = response.ref.split('/tasks/')[1];
pm.environment.set("taskId", taskId);
```

Then use `{{taskId}}` in subsequent requests.

### 3. Chain Requests
Use Postman's **Collection Runner** to execute requests in sequence:
1. Create Application
2. Get Task Status (with saved taskId)
3. Get Application Details
4. Create Pipeline
5. Trigger Pipeline

### 4. Save Example Responses
After running a request:
1. Click **Save Response**
2. Add as example
3. Helps with documentation and testing

## Common Issues

### 1. Connection Refused
**Problem:** Cannot connect to `http://localhost:8084`

**Solution:**
```bash
# Check if port forward is running
ps aux | grep "kubectl port-forward"

# Restart port forward if needed
kubectl port-forward svc/spin-gate -n spinnaker 8084:8084 &
```

### 2. Authentication Failed (401)
**Problem:** `401 Unauthorized` response

**Solution:**
- Verify credentials in collection settings
- Check Spinnaker authentication is enabled:
  ```bash
  kubectl get spinnakerservice -n spinnaker -o yaml | grep -A 10 "basicform"
  ```

### 3. Application Creation Returns 500 Error
**Problem:** `500 Internal Server Error` when creating application

**Solution:**
- Ensure you're using the correct task format (see "Create Application" above)
- Must wrap application properties in "job" array with "type": "createApplication"
- Old format (direct properties) is **not supported**

### 4. Task Status Shows TERMINAL
**Problem:** Task failed during execution

**Solution:**
```bash
# Check Orca logs (task execution service)
kubectl logs -n spinnaker deployment/spin-orca --tail=100
```

### 5. Pipeline Update Returns 405 Method Not Allowed
**Problem:** `405 Method Not Allowed` when updating pipeline

**Solution:**
- Use **POST** method (not PUT) for pipeline updates
- Must include the actual pipeline `id` in request body
- Get the ID first: `GET /applications/{app}/pipelineConfigs/{name}`
- Endpoint: `/pipelines` (same as create)

Example:
```bash
# 1. Get pipeline ID
ID=$(curl -s -u admin:admin123 \
  http://localhost:8084/applications/myapp/pipelineConfigs/my-pipeline | jq -r '.id')

# 2. Update with POST
curl -u admin:admin123 -X POST -H "Content-Type: application/json" \
  -d "{\"id\":\"$ID\",\"application\":\"myapp\",\"name\":\"my-pipeline\",...}" \
  http://localhost:8084/pipelines
```

### 6. Pipeline Not Found
**Problem:** Cannot find pipeline after creation

**Solution:**
- Wait a few seconds for cache to refresh
- Verify application name matches exactly
- Check pipeline list: `GET /applications/{app}/pipelineConfigs`

## API Reference

### Base URL
```
http://localhost:8084
```

### Authentication
```
Type: Basic Auth
Username: admin
Password: admin123
```

### Common Response Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Request completed successfully |
| 201 | Created | Resource created successfully |
| 202 | Accepted | Task submitted (async operation) |
| 400 | Bad Request | Check request body format |
| 401 | Unauthorized | Verify credentials |
| 404 | Not Found | Check resource name/ID |
| 405 | Method Not Allowed | Check HTTP method (e.g., use POST not PUT for pipeline updates) |
| 500 | Server Error | Check Spinnaker logs |

### Task States

| State | Meaning |
|-------|---------|
| NOT_STARTED | Task queued |
| RUNNING | Task in progress |
| SUCCEEDED | Task completed successfully |
| TERMINAL | Task failed |
| CANCELED | Task was canceled |

## Next Steps

1. **Complete Feature 1:** Work through [docs/features/01-applications.md](../features/01-applications.md)
2. **Complete Feature 2:** Work through [docs/features/02-pipelines.md](../features/02-pipelines.md)
3. **Test all requests:** Run through the collection and save responses
4. **Customize:** Add your own requests for specific workflows
5. **Automate:** Use Collection Runner for regression testing

## Additional Resources

- **Spinnaker API Documentation:** https://spinnaker.io/docs/reference/api/
- **Feature Guides:** See `docs/features/` directory
- **Setup Guide:** See [README.md](../README.md)

## Collection Maintenance

This collection covers the core Spinnaker APIs documented in:
- `docs/features/01-applications.md` - Applications management (9 endpoints)
- `docs/features/02-pipelines.md` - Pipelines management (11 endpoints)

**To add more endpoints:**
1. Refer to feature documentation in `docs/features/`
2. Follow the existing request format
3. Include descriptions and examples
4. Test before adding to collection

**Collection Version:** 1.0.0  
**Last Updated:** January 2, 2026  
**Tested with:** Spinnaker 1.33.0
