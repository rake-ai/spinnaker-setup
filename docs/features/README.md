# Spinnaker Features Guide

This directory contains step-by-step guides for essential Spinnaker features with corresponding API examples.

## 📚 Features Overview

### 1. **Applications Management** ✅
Core feature for organizing your deployments.
- [01-applications.md](01-applications.md)

### 2. **Pipelines** 🔄
Automate deployment workflows with pipelines.
- [02-pipelines.md](02-pipelines.md)

### 3. **Tasks & Executions** ✅
Monitor and manage tasks and pipeline executions.
- [03-tasks-executions.md](03-tasks-executions.md)

### 4. **Clusters & Server Groups** ✅
Manage infrastructure deployments.
- [04-clusters-servergroups.md](04-clusters-servergroups.md)

### 5. **Load Balancers** ✅
Configure load balancing for your applications.
- [05-loadbalancers.md](05-loadbalancers.md)

---

## 🎯 Learning Path

**Recommended Order:**

1. **Start with Applications** - Create and manage applications
2. **Create Pipelines** - Build deployment workflows
3. **Monitor Executions** - Track pipeline runs and tasks
4. **Manage Infrastructure** - Work with clusters and server groups
5. **Configure Load Balancers** - Set up traffic management

---

## 📖 How to Use This Guide

Each feature guide includes:

1. **Overview** - What the feature does
2. **Prerequisites** - What you need before starting
3. **Step-by-Step Instructions** - UI and CLI methods
4. **API Examples** - REST API calls with curl
5. **Common Operations** - Frequently used tasks
6. **Troubleshooting** - Common issues and solutions

---

## 🔗 API Reference

All examples use the Spinnaker Gate API at: `http://localhost:8084`

**Authentication:** HTTP Basic Auth (admin/admin123)

**Format:**
```bash
curl -u admin:admin123 \
  -H "Content-Type: application/json" \
  http://localhost:8084/endpoint
```

---

## 📦 Postman Collection

All API calls have been added to the Postman collection:
- **Collection Name:** `Spinnaker API`
- **Location:** `Spinnaker-API.postman_collection.json`
- **Total Requests:** 48 (9 Applications + 12 Pipelines + 7 Tasks + 11 Clusters + 7 Load Balancers + 2 System)

**Import to Postman:**
1. Open Postman
2. File → Import → Select `Spinnaker-API.postman_collection.json`
3. Collection will be ready to use with pre-configured authentication

---

## ✅ Progress Tracker

- [x] 01. Applications Management
- [x] 02. Pipelines
- [x] 03. Tasks & Executions
- [x] 04. Clusters & Server Groups
- [x] 05. Load Balancers

---

## 🚀 Quick Start

1. **Prerequisites:**
   - Spinnaker running (see main README.md)
   - Port forwards active (Gate: 8084, Deck: 9000)
   - Authentication configured (admin/admin123)

2. **Verify Setup:**
   ```bash
   curl -u admin:admin123 http://localhost:8084/health
   ```

3. **Start Learning:**
   Begin with [01-applications.md](01-applications.md)
