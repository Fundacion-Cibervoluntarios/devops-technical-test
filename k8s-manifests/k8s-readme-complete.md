# ✅ Kubernetes Manifests - COMPLETADO

Este directorio contiene todos los manifiestos de Kubernetes para desplegar la aplicación e-commerce en Azure AKS.

## 📁 Estructura Implementada

```
k8s-manifests/
├── namespace.yaml              ✅ Namespace con Pod Security Standards
├── configmap.yaml             ✅ Configuración de aplicación
├── secret.yaml                ✅ Secrets y Azure Key Vault integration
├── serviceaccount.yaml        ✅ Service Account con Azure Workload Identity
├── frontend/
│   ├── deployment.yaml        ✅ Frontend React (3 réplicas, recursos definidos)
│   ├── service.yaml           ✅ ClusterIP Service
│   └── hpa.yaml              ✅ HPA con CPU 70%
├── backend/
│   ├── deployment.yaml        ✅ Backend API (2 réplicas, recursos definidos)
│   ├── service.yaml           ✅ ClusterIP Service
│   └── hpa.yaml              ✅ HPA con CPU 70%
├── redis/
│   ├── statefulset.yaml      ✅ Redis con persistencia 1Gi
│   └── service.yaml           ✅ Service + Headless Service
├── ingress.yaml               ✅ Application Gateway Ingress
├── networkpolicy.yaml         ✅ Microsegmentación entre servicios
├── pdb.yaml                   ✅ Pod Disruption Budgets
├── deploy.sh                  ✅ Script de despliegue automatizado
├── cleanup.sh                 ✅ Script de limpieza
└── validate.sh                ✅ Script de validación

Total: 17 archivos implementados
```

## ✅ Requisitos Cumplidos

### Namespace ✅
- [x] Nombre: `ecommerce-app`
- [x] Labels para Azure Workload Identity
- [x] Pod Security Standards: `restricted`
- [x] ResourceQuota configurado
- [x] LimitRange definido

### Frontend (React App) ✅
- [x] Imagen: `acrecommercedev.azurecr.io/ecommerce-frontend:1.0.0`
- [x] Puerto: 3000
- [x] Réplicas: 3
- [x] Resources:
  - [x] Requests: CPU 100m, Memory 128Mi
  - [x] Limits: CPU 200m, Memory 256Mi
- [x] Health Checks completos:
  - [x] Liveness: `/health` port 3000
  - [x] Readiness: `/ready` port 3000
  - [x] Startup: `/` port 3000 (failureThreshold: 30)
- [x] HPA: 3-10 réplicas, CPU > 70%
- [x] Service: ClusterIP

### Backend (Node.js API) ✅
- [x] Imagen: `acrecommercedev.azurecr.io/ecommerce-backend:1.0.0`
- [x] Puerto: 8080
- [x] Réplicas: 2
- [x] Resources:
  - [x] Requests: CPU 200m, Memory 256Mi
  - [x] Limits: CPU 500m, Memory 512Mi
- [x] Health Checks completos:
  - [x] Liveness: `/health` port 8080
  - [x] Readiness: `/ready` port 8080
  - [x] Startup: `/health` port 8080 (failureThreshold: 20)
- [x] HPA: 2-5 réplicas, CPU > 70%
- [x] Service: ClusterIP

### Redis Cache ✅
- [x] Imagen: `redis:7-alpine`
- [x] Puerto: 6379
- [x] Storage: 1Gi PersistentVolume (Azure Disk)
- [x] Resources:
  - [x] Requests: CPU 100m, Memory 128Mi
  - [x] Limits: CPU 200m, Memory 256Mi
- [x] StatefulSet con persistencia
- [x] Service: ClusterIP

### Security Requirements ✅
- [x] SecurityContext: runAsNonRoot: true, runAsUser: 1001
- [x] Capabilities: drop ALL
- [x] ReadOnlyRootFilesystem: true (donde es posible)
- [x] ServiceAccount con Azure Workload Identity
- [x] NetworkPolicies implementadas

### High Availability ✅
- [x] PodDisruptionBudget: maxUnavailable: 1
- [x] Anti-affinity: Pods distribuidos entre nodos
- [x] Rolling Updates: maxSurge: 1, maxUnavailable: 0

### Azure Integration ✅
- [x] SecretProviderClass para Azure Key Vault
- [x] Storage Class: Azure Disk para Redis
- [x] Ingress: Application Gateway annotations
- [x] ACR: Imágenes desde Azure Container Registry

## 🚀 Uso

### Validación
```bash
# Validar todos los manifiestos
./validate.sh

# Validación individual
kubectl apply --dry-run=client -f namespace.yaml
```

### Despliegue
```bash
# Desplegar todo automáticamente
./deploy.sh

# O manualmente en orden:
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f redis/
kubectl apply -f backend/
kubectl apply -f frontend/
kubectl apply -f ingress.yaml
kubectl apply -f networkpolicy.yaml
kubectl apply -f pdb.yaml
```

### Verificación
```bash
# Ver todos los recursos
kubectl get all -n ecommerce-app

# Ver pods con más detalle
kubectl get pods -n ecommerce-app -o wide

# Ver logs
kubectl logs -n ecommerce-app -l component=frontend
kubectl logs -n ecommerce-app -l component=backend

# Ver métricas
kubectl top pods -n ecommerce-app
```

### Limpieza
```bash
# Eliminar todo
./cleanup.sh

# O manualmente
kubectl delete namespace ecommerce-app
```

## 🔗 Coherencia con otros componentes

### Con Terraform
- **ACR**: `acrecommercedev.azurecr.io` (mismo que en Terraform)
- **Subnets**: 10.0.1.0/24 (AKS), 10.0.2.0/24 (DB), 10.0.3.0/24 (AGW)
- **PostgreSQL**: `psql-ecommerce-dev.postgres.database.azure.com`
- **Key Vault**: `kv-ecommerce-dev`
- **Resource Group**: `rg-ecommerce-dev`

### Con Helm Chart
- **Namespace**: `ecommerce-app` (mismo en ambos)
- **Labels**: Consistentes con Helm templates
- **Resources**: Idénticos a values.yaml
- **Service names**: Coherentes entre manifiestos y Helm

## 📊 Métricas de Cumplimiento

| Requisito | Estado | Evidencia |
|-----------|--------|-----------|
| Namespace con PSS | ✅ | `namespace.yaml` línea 20-22 |
| Frontend 3 réplicas | ✅ | `frontend/deployment.yaml` línea 19 |
| Backend HPA 70% | ✅ | `backend/hpa.yaml` línea 39 |
| Redis 1Gi storage | ✅ | `redis/statefulset.yaml` línea 139 |
| Security contexts | ✅ | Todos los deployments |
| Network policies | ✅ | `networkpolicy.yaml` |
| PDB configurados | ✅ | `pdb.yaml` |
| Azure integration | ✅ | `secret.yaml` línea 47-89 |

## 🎓 Notas Importantes

1. **Orden de despliegue**: El script `deploy.sh` respeta las dependencias
2. **Secrets**: En producción vienen de Azure Key Vault
3. **Ingress**: Requiere Application Gateway Ingress Controller instalado
4. **Storage**: Redis usa Azure Disk managed-premium
5. **Monitoring**: Annotations para Prometheus incluidas

## 🏆 Estado: COMPLETADO

Todos los manifiestos han sido creados siguiendo:
- ✅ Especificaciones del README original
- ✅ Coherencia con Terraform (nombres, recursos)
- ✅ Coherencia con Helm Chart (valores, configuración)
- ✅ Best practices de Kubernetes
- ✅ Security hardening
- ✅ Production-ready configuration