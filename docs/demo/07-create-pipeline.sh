#!/bin/bash
# Step 7: Create deployment pipeline

set -e

echo "=========================================="
echo "Step 7: Create Deployment Pipeline"
echo "=========================================="
echo

# Check if pipeline already exists
echo "Checking for existing pipelines..."
EXISTING=$(curl -s -u admin:admin123 http://localhost:8080/pipelines/productapi)
if echo "$EXISTING" | jq -e '.[] | select(.name == "Deploy to Production")' > /dev/null 2>&1; then
    echo "⚠️  Pipeline 'Deploy to Production' already exists"
    PIPELINE_ID=$(echo "$EXISTING" | jq -r '.[] | select(.name == "Deploy to Production") | .id')
    echo "   Pipeline ID: $PIPELINE_ID"
    echo
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing pipeline..."
        curl -s -u admin:admin123 -X DELETE "http://localhost:8080/pipelines/productapi/$PIPELINE_ID"
        echo "✅ Pipeline deleted"
        sleep 2
    else
        echo "Keeping existing pipeline"
        exit 0
    fi
fi

# Create pipeline manifest
echo "Creating pipeline configuration..."
cat > /tmp/productapi-pipeline.json << 'EOF'
{
  "application": "productapi",
  "name": "Deploy to Production",
  "description": "Deploy ProductAPI to Kubernetes with automated stages",
  "expectedArtifacts": [],
  "keepWaitingPipelines": false,
  "limitConcurrent": true,
  "parameterConfig": [
    {
      "name": "VERSION",
      "description": "Version to deploy (e.g., v2.0.0)",
      "default": "v2.0.0",
      "required": true
    },
    {
      "name": "REPLICAS",
      "description": "Number of replicas",
      "default": "3",
      "required": true
    }
  ],
  "stages": [
    {
      "name": "Deploy Manifest",
      "refId": "1",
      "type": "deployManifest",
      "account": "docker-desktop",
      "cloudProvider": "kubernetes",
      "source": "text",
      "manifests": [
        {
          "apiVersion": "apps/v1",
          "kind": "Deployment",
          "metadata": {
            "name": "productapi-${parameters.VERSION}",
            "namespace": "default",
            "labels": {
              "app": "productapi",
              "version": "${parameters.VERSION}"
            },
            "annotations": {
              "moniker.spinnaker.io/application": "productapi",
              "moniker.spinnaker.io/cluster": "productapi"
            }
          },
          "spec": {
            "replicas": "${ #toInt( parameters.REPLICAS ) }",
            "selector": {
              "matchLabels": {
                "app": "productapi",
                "version": "${parameters.VERSION}"
              }
            },
            "template": {
              "metadata": {
                "labels": {
                  "app": "productapi",
                  "version": "${parameters.VERSION}"
                }
              },
              "spec": {
                "containers": [
                  {
                    "name": "productapi",
                    "image": "hashicorp/http-echo",
                    "args": [
                      "-text=ProductAPI ${parameters.VERSION} - Product Management System [Deployed via Pipeline]",
                      "-listen=:8080"
                    ],
                    "ports": [
                      {
                        "containerPort": 8080,
                        "name": "http"
                      }
                    ],
                    "resources": {
                      "requests": {
                        "cpu": "100m",
                        "memory": "64Mi"
                      },
                      "limits": {
                        "cpu": "200m",
                        "memory": "128Mi"
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      ],
      "moniker": {
        "app": "productapi"
      },
      "requisiteStageRefIds": [],
      "skipExpressionEvaluation": false
    },
    {
      "name": "Wait for Deployment",
      "refId": "2",
      "type": "wait",
      "waitTime": 10,
      "requisiteStageRefIds": ["1"]
    },
    {
      "name": "Manual Judgment",
      "refId": "3",
      "type": "manualJudgment",
      "failPipeline": true,
      "instructions": "Review the deployment and approve to continue, or reject to rollback.",
      "judgmentInputs": [
        {"value": "Approve"},
        {"value": "Reject"}
      ],
      "requisiteStageRefIds": ["2"]
    }
  ],
  "triggers": []
}
EOF

echo "✅ Pipeline configuration created"
echo

# Create pipeline
echo "Creating pipeline in Spinnaker..."
RESPONSE=$(curl -s -u admin:admin123 -X POST http://localhost:8080/pipelines \
  -H "Content-Type: application/json" \
  -d @/tmp/productapi-pipeline.json)

echo "$RESPONSE" | jq '{id, name}'

echo
echo "Verifying pipeline..."
sleep 2

curl -s -u admin:admin123 http://localhost:8080/pipelines/productapi | \
  jq '.[] | select(.name == "Deploy to Production") | {
    id,
    name,
    stages: [.stages[].name],
    parameters: [.parameterConfig[].name]
  }'

echo
echo "=========================================="
echo "✅ Pipeline created successfully!"
echo "=========================================="
echo
echo "Pipeline Details:"
echo "  - Name: Deploy to Production"
echo "  - Parameters: VERSION, REPLICAS"
echo "  - Stages:"
echo "    1. Deploy Manifest"
echo "    2. Wait for Deployment (10s)"
echo "    3. Manual Judgment"
echo
echo "View in UI:"
echo "  http://localhost:9000/#/applications/productapi/executions"
echo
echo "Next step: Run ./08-execute-pipeline.sh"
echo
