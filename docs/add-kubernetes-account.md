# How to Add Kubernetes/Minikube Account to Spinnaker

This guide explains how to add additional Kubernetes clusters (like Minikube) to your Spinnaker instance.

---

## Current Status

**Active Accounts:**
- ✅ `docker-desktop` - Currently configured and working (if clouddriver starts properly)

**Available but Not Configured:**
- ⏳ `minikube` - Kubeconfig in secrets, ready to be enabled when cluster is running

---

## Prerequisites

### 1. Start Your Target Cluster

**For Minikube:**
```bash
# Start minikube
minikube start

# Verify it's running
kubectl config get-contexts
# Should show minikube context

# Test connectivity
kubectl --context=minikube get nodes
```

**For Any Kubernetes Cluster:**
```bash
# Verify you can access the cluster
kubectl --context=<your-context> get nodes

# Make sure the context is in your kubeconfig
kubectl config view --flatten
```

---

## Step-by-Step: Add Minikube Account

### Step 1: Extract Kubeconfig

The kubeconfig is already in `spin-secrets` but you can update it:

```bash
# Extract flattened kubeconfig for minikube
kubectl config view --context=minikube --flatten --minify > /tmp/kubeconfig-minikube

# Update the secret
kubectl get secret spin-secrets -n spinnaker -o json | \
  jq --arg kubeconfig "$(base64 -w0 < /tmp/kubeconfig-minikube)" \
  '.data["kubeconfig-minikube"] = $kubeconfig' | \
  kubectl apply -f -

# Verify the secret was updated
kubectl get secret spin-secrets -n spinnaker -o jsonpath='{.data.kubeconfig-minikube}' | \
  base64 -d | head -5
```

### Step 2: Enable Minikube Account in SpinnakerService

Edit `k8s/spinnaker/spinnakerservice.yaml`:

```yaml
providers:
  kubernetes:
    enabled: true
    accounts:
    # Docker Desktop (existing)
    - name: docker-desktop
      providerVersion: V2
      onlySpinnakerManaged: false
      kubeconfigFile: encryptedFile:k8s!n:spin-secrets!k:kubeconfig-docker-desktop
    
    # Minikube (NEW - uncomment these lines)
    - name: minikube
      providerVersion: V2
      onlySpinnakerManaged: false
      kubeconfigFile: encryptedFile:k8s!n:spin-secrets!k:kubeconfig-minikube
    
    primaryAccount: docker-desktop  # Keep docker-desktop as primary
```

**Already prepared in the file - just uncomment!**

### Step 3: Apply Configuration

```bash
# Apply the updated SpinnakerService
kubectl apply -f k8s/spinnaker/spinnakerservice.yaml

# Wait for clouddriver to restart (2-3 minutes)
kubectl rollout status deployment/spin-clouddriver -n spinnaker --timeout=5m
```

### Step 4: Verify Account is Active

```bash
# Check credentials via API
curl -s http://localhost:8084/credentials | jq '.[] | {name, type, cloudProvider}'

# Expected output:
# {
#   "name": "docker-desktop",
#   "type": "kubernetes",
#   "cloudProvider": "kubernetes"
# }
# {
#   "name": "minikube",
#   "type": "kubernetes",
#   "cloudProvider": "kubernetes"
# }

# Or check in Spinnaker UI
# Navigate to: Applications → Create Application
# Under "Account" dropdown, you should see both accounts
```

---

## Adding Any Kubernetes Cluster

### Method 1: Using Kubeconfig File (Recommended)

**Step 1: Get the kubeconfig**

```bash
# For a cluster in your local kubeconfig
CONTEXT_NAME="my-cluster"
kubectl config view --context=$CONTEXT_NAME --flatten --minify > /tmp/kubeconfig-${CONTEXT_NAME}

# For a remote cluster (e.g., AWS EKS, GKE, AKS)
# Follow your cloud provider's instructions to get kubeconfig
# Example for EKS:
# aws eks update-kubeconfig --name my-cluster --region us-west-2 --kubeconfig /tmp/kubeconfig-eks
```

**Step 2: Add to Spinnaker secrets**

```bash
# Add the kubeconfig to spin-secrets
ACCOUNT_NAME="my-cluster"
kubectl get secret spin-secrets -n spinnaker -o json | \
  jq --arg kubeconfig "$(base64 -w0 < /tmp/kubeconfig-${ACCOUNT_NAME})" \
  --arg key "kubeconfig-${ACCOUNT_NAME}" \
  '.data[$key] = $kubeconfig' | \
  kubectl apply -f -
```

**Step 3: Add account to spinnakerservice.yaml**

```yaml
providers:
  kubernetes:
    accounts:
    - name: my-cluster
      providerVersion: V2
      onlySpinnakerManaged: false
      kubeconfigFile: encryptedFile:k8s!n:spin-secrets!k:kubeconfig-my-cluster
```

**Step 4: Apply and verify**

```bash
kubectl apply -f k8s/spinnaker/spinnakerservice.yaml
kubectl rollout status deployment/spin-clouddriver -n spinnaker --timeout=5m
```

---

### Method 2: Using Service Account (For In-Cluster Access)

If Spinnaker is running **inside** the target cluster:

```yaml
providers:
  kubernetes:
    accounts:
    - name: my-cluster
      providerVersion: V2
      onlySpinnakerManaged: false
      serviceAccount: true  # Use the pod's service account
```

**Note:** Requires proper RBAC permissions for the `spinnaker-service-account`.

---

## Advanced Configuration Options

### Limit Namespaces

```yaml
- name: minikube
  providerVersion: V2
  kubeconfigFile: encryptedFile:k8s!n:spin-secrets!k:kubeconfig-minikube
  namespaces:
    - default
    - production
    - staging
  # Only manage resources in these namespaces
```

### Exclude Namespaces

```yaml
- name: minikube
  providerVersion: V2
  kubeconfigFile: encryptedFile:k8s!n:spin-secrets!k:kubeconfig-minikube
  omitNamespaces:
    - kube-system
    - kube-public
  # Don't show these namespaces in Spinnaker
```

### Only Manage Spinnaker-Created Resources

```yaml
- name: minikube
  providerVersion: V2
  kubeconfigFile: encryptedFile:k8s!n:spin-secrets!k:kubeconfig-minikube
  onlySpinnakerManaged: true
  # Only show resources created by Spinnaker (ignore existing resources)
```

### Add Permissions & RBAC

```yaml
- name: production-cluster
  providerVersion: V2
  kubeconfigFile: encryptedFile:k8s!n:spin-secrets!k:kubeconfig-prod
  permissions:
    READ:
      - developers
      - operators
    WRITE:
      - operators
  requiredGroupMembership:
    - operators
```

### Configure Docker Registries

```yaml
- name: minikube
  providerVersion: V2
  kubeconfigFile: encryptedFile:k8s!n:spin-secrets!k:kubeconfig-minikube
  dockerRegistries:
    - accountName: dockerhub
    - accountName: gcr
  configureImagePullSecrets: true
```

---

## Troubleshooting

### Issue: "connection refused" Error

**Error:**
```
error listing namespaces in account "minikube":
Get "https://127.0.0.1:53196/api/v1/namespaces": dial tcp 127.0.0.1:53196: connect: connection refused
```

**Cause:** Target cluster is not running or not accessible.

**Solution:**
```bash
# Start the cluster
minikube start

# Verify connectivity
kubectl --context=minikube get nodes

# Re-apply SpinnakerService
kubectl apply -f k8s/spinnaker/spinnakerservice.yaml
```

---

### Issue: "no configuration has been provided"

**Error:**
```
invalid configuration: no configuration has been provided
```

**Cause:** Kubeconfig in secret is empty or invalid.

**Solution:**
```bash
# Check what's in the secret
kubectl get secret spin-secrets -n spinnaker -o jsonpath='{.data.kubeconfig-minikube}' | base64 -d

# If it's a placeholder or empty, update it
kubectl config view --context=minikube --flatten --minify > /tmp/kubeconfig-minikube
kubectl get secret spin-secrets -n spinnaker -o json | \
  jq --arg kubeconfig "$(base64 -w0 < /tmp/kubeconfig-minikube)" \
  '.data["kubeconfig-minikube"] = $kubeconfig' | \
  kubectl apply -f -
```

---

### Issue: Clouddriver Won't Start

**Symptoms:**
- New clouddriver pod keeps restarting
- Old clouddriver pod still running
- Credentials endpoint returns empty

**Check logs:**
```bash
kubectl logs -n spinnaker deployment/spin-clouddriver --tail=100
```

**Common causes:**
1. **Invalid kubeconfig format** - Ensure it's a valid, flattened kubeconfig
2. **Missing cluster context** - Make sure cluster is running and accessible
3. **Permission issues** - Service account needs proper RBAC
4. **Syntax errors in YAML** - Validate spinnakerservice.yaml

**Solution:**
```bash
# Delete the failing pod to force a restart
kubectl delete pod -n spinnaker -l cluster=spin-clouddriver

# Or rollback configuration
kubectl patch spinsvc spinnaker -n spinnaker --type json \
  -p='[{"op": "remove", "path": "/spec/spinnakerConfig/config/providers/kubernetes/accounts/1"}]'
```

---

### Issue: Account Shows in UI but Can't Deploy

**Cause:** Insufficient RBAC permissions on target cluster.

**Solution:** Create proper service account and role bindings on the target cluster:

```bash
# On the target cluster (e.g., minikube)
kubectl --context=minikube create namespace spinnaker
kubectl --context=minikube create serviceaccount spinnaker-service-account -n spinnaker

# Create ClusterRole with required permissions
kubectl --context=minikube apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: spinnaker-role
rules:
- apiGroups: [""]
  resources: ["namespaces", "configmaps", "events", "replicationcontrollers", "serviceaccounts", "pods/log", "services", "pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods", "services", "secrets", "configmaps"]
  verbs: ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
- apiGroups: ["autoscaling"]
  resources: ["horizontalpodautoscalers"]
  verbs: ["list", "get"]
- apiGroups: ["apps"]
  resources: ["controllerrevisions", "statefulsets"]
  verbs: ["list"]
- apiGroups: ["extensions", "apps"]
  resources: ["deployments", "replicasets", "ingresses", "daemonsets"]
  verbs: ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
EOF

# Bind the role
kubectl --context=minikube create clusterrolebinding spinnaker-binding \
  --clusterrole=spinnaker-role \
  --serviceaccount=spinnaker:spinnaker-service-account
```

---

## Testing Your New Account

### Via UI

1. **Login to Spinnaker:** http://localhost:9000
2. **Navigate to Applications** → Click an existing app or create new
3. **Go to CLUSTERS tab**
4. **Click "Create Server Group"**
5. **Check "Account" dropdown** - Should show your new account

### Via API

```bash
# List all accounts
curl -s http://localhost:8084/credentials | jq '.[] | {name, type}'

# Get namespaces for specific account
curl -s http://localhost:8084/credentials/minikube | jq '.namespaces'

# List clusters in account
curl -s http://localhost:8084/applications | jq '.'
```

### Deploy a Test Application

```bash
# Create test app
curl -X POST http://localhost:8084/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "application": "testapp",
    "job": [{
      "type": "createApplication",
      "application": {
        "name": "testapp",
        "email": "test@example.com",
        "cloudProviders": "kubernetes"
      }
    }]
  }'

# Deploy to minikube
curl -X POST http://localhost:8084/applications/testapp/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "job": [{
      "cloudProvider": "kubernetes",
      "type": "createServerGroup",
      "account": "minikube",
      "application": "testapp",
      "stack": "dev",
      "region": "default",
      "namespace": "default",
      "targetSize": 2,
      "containers": [{
        "name": "nginx",
        "imageDescription": {
          "repository": "nginx",
          "tag": "alpine",
          "registry": "index.docker.io"
        }
      }]
    }]
  }'
```

---

## Summary

**Quick Steps to Add Minikube:**
1. ✅ Start minikube: `minikube start`
2. ✅ Secret already has kubeconfig (or update it)
3. ✅ Uncomment minikube account in spinnakerservice.yaml
4. ✅ Apply: `kubectl apply -f k8s/spinnaker/spinnakerservice.yaml`
5. ✅ Wait for clouddriver restart
6. ✅ Verify: `curl http://localhost:8084/credentials`

**For Any Cluster:**
1. Get kubeconfig
2. Add to spin-secrets
3. Add account config to spinnakerservice.yaml
4. Apply configuration
5. Verify in UI/API

**Current Configuration:**
- File: `k8s/spinnaker/spinnakerservice.yaml` (lines 60-80)
- Minikube account is **ready but commented out**
- Just uncomment when minikube is running!
