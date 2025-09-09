# E-commerce Application Helm Chart

## 🎯 Overview

Production-ready Helm chart for deploying the e-commerce application on Azure AKS with:
- High availability configuration
- Auto-scaling capabilities
- Security hardening
- Azure services integration
- Multi-environment support

## 📋 Prerequisites

- Kubernetes 1.23+
- Helm 3.12+
- Azure AKS cluster with:
  - Application Gateway Ingress Controller (AGIC)
  - Azure Key Vault Provider for Secrets Store CSI Driver
  - Azure Monitor/Application Insights configured

## 🚀 Quick Start

### Add Helm repository (if published)
```bash
helm repo add ecommerce https://charts.example.com
helm repo update
```

### Install the chart
```bash
# Development environment
helm install ecommerce ./helm-chart \
  --namespace ecommerce-app \
  --create-namespace \
  -f helm-chart/environments/values-dev.yaml

# Staging environment
helm install ecommerce ./helm-chart \
  --namespace ecommerce-staging \
  --create-namespace \
  -f helm-chart/environments/values-staging.yaml

# Production environment
helm install ecommerce ./helm-chart \
  --namespace ecommerce-prod \
  --create-namespace \
  -f helm-chart/environments/values-prod.yaml
```

## 📁 Chart Structure

```
helm-chart/
├── Chart.yaml                 # Chart metadata
├── values.yaml                # Default values
├── values.schema.json         # JSON schema for validation
├── environments/              # Environment-specific values
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   └── values-prod.yaml
├── templates/
│   ├── _helpers.tpl          # Template helpers
│   ├── NOTES.txt             # Post-install notes
│   ├── configmap.yaml        # Application configuration
│   ├── secret.yaml           # Secrets (if not using Key Vault)
│   ├── serviceaccount.yaml   # Service account with RBAC
│   ├── frontend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── backend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── redis/
│   │   ├── statefulset.yaml
│   │   └── service.yaml
│   ├── ingress.yaml
│   ├── networkpolicy.yaml
│   └── poddisruptionbudget.yaml
└── tests/
    └── test-connection.yaml   # Helm test
```

## ⚙️ Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.environment` | Environment (dev/staging/prod) | `dev` |
| `global.imageRegistry` | ACR registry URL | `""` |
| `global.domain` | Application domain | `ecommerce.example.com` |
| `frontend.replicaCount` | Number of frontend replicas | `3` |
| `backend.replicaCount` | Number of backend replicas | `2` |
| `redis.enabled` | Enable Redis cache | `true` |
| `ingress.enabled` | Enable ingress | `true` |
| `monitoring.enabled` | Enable monitoring | `true` |
| `networkPolicies.enabled` | Enable network policies | `true` |

### Azure Integration

```yaml
# Configure Azure services
global:
  azure:
    tenantId: "your-tenant-id"
    subscriptionId: "your-subscription-id"
    resourceGroup: "rg-ecommerce-prod"
    keyVaultName: "kv-ecommerce-prod"

# Azure Key Vault secrets
azureKeyVault:
  enabled: true
  secretProviderClassName: "azure-keyvault-secrets"
  secrets:
    - secretName: "database-password"
      keyVaultKey: "postgres-admin-password"
```

### Resource Configuration

```yaml
# Frontend resources
frontend:
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"
```

### Auto-scaling

```yaml
# HPA configuration
frontend:
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

## 🔒 Security Features

1. **Pod Security Context**
   - Non-root user (1001)
   - Read-only root filesystem
   - No privilege escalation

2. **Network Policies**
   - Ingress/egress restrictions
   - Microsegmentation between services

3. **Azure Key Vault Integration**
   - Secrets stored in Azure Key Vault
   - Workload identity for authentication

4. **Security Scanning**
   - Container image scanning
   - Vulnerability assessment

## 📊 Monitoring

### Application Insights
```yaml
monitoring:
  applicationInsights:
    enabled: true
    connectionString: "InstrumentationKey=xxx"
```

### Prometheus Metrics
```yaml
monitoring:
  serviceMonitor:
    enabled: true
    interval: 30s
```

## 🚀 Deployment Scenarios

### Development
```bash
helm upgrade --install ecommerce ./helm-chart \
  -f environments/values-dev.yaml \
  --set global.imageRegistry=acrecommercedev.azurecr.io \
  --set images.frontend.tag=latest \
  --set images.backend.tag=latest
```

### Blue-Green Deployment
```bash
# Deploy green version
helm upgrade --install ecommerce-green ./helm-chart \
  -f environments/values-prod.yaml \
  --set images.frontend.tag=v2.0.0 \
  --set images.backend.tag=v2.0.0

# Switch traffic (update ingress)
kubectl patch ingress ecommerce-ingress -p '{"spec":{"rules":[{"host":"ecommerce.com","http":{"paths":[{"backend":{"service":{"name":"ecommerce-green-frontend"}}}]}}]}}'
```

### Canary Deployment
```bash
# Use Flagger or similar for progressive delivery
helm upgrade --install ecommerce ./helm-chart \
  -f environments/values-prod.yaml \
  --set canary.enabled=true \
  --set canary.weight=20
```

## 🧪 Testing

### Run Helm tests
```bash
helm test ecommerce -n ecommerce-app
```

### Validate chart
```bash
helm lint ./helm-chart
helm template ecommerce ./helm-chart --debug
```

### Dry run installation
```bash
helm install ecommerce ./helm-chart \
  --dry-run \
  --debug \
  -f environments/values-dev.yaml
```

## 📈 Upgrading

### Upgrade release
```bash
helm upgrade ecommerce ./helm-chart \
  --namespace ecommerce-app \
  -f environments/values-prod.yaml \
  --set images.frontend.tag=v1.1.0
```

### Rollback
```bash
# View history
helm history ecommerce -n ecommerce-app

# Rollback to previous version
helm rollback ecommerce -n ecommerce-app

# Rollback to specific revision
helm rollback ecommerce 3 -n ecommerce-app
```

## 🔧 Troubleshooting

### Common Issues

1. **Image Pull Errors**
```bash
# Check ACR integration
kubectl get secret -n ecommerce-app
kubectl describe pod <pod-name> -n ecommerce-app
```

2. **Pod Not Starting**
```bash
# Check events
kubectl get events -n ecommerce-app --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n ecommerce-app <pod-name> --previous
```

3. **Ingress Not Working**
```bash
# Check AGIC logs
kubectl logs -n kube-system deployment/ingress-appgw-deployment

# Check ingress status
kubectl describe ingress -n ecommerce-app
```

## 🏷️ Labels and Annotations

The chart uses standard Kubernetes labels:
- `app.kubernetes.io/name`: Application name
- `app.kubernetes.io/instance`: Release name
- `app.kubernetes.io/version`: Application version
- `app.kubernetes.io/component`: Component name
- `app.kubernetes.io/managed-by`: Helm

## 📝 Values Validation

The chart includes a JSON schema for validating values:
```bash
# Validate values against schema
helm lint ./helm-chart --strict
```

## 🤝 Contributing

1. Update `values.yaml` with new parameters
2. Update `values.schema.json` with validation rules
3. Add/modify templates as needed
4. Update this README
5. Bump version in `Chart.yaml`

## 📜 License

MIT License - See LICENSE file

## 🆘 Support

- GitHub Issues: https://github.com/[your-repo]/issues
- Documentation: https://github.com/[your-repo]/wiki
- Email: devops@company.com