# Output values for Azure E-commerce Infrastructure

# TODO: Define outputs that will be consumed by other components

# 🎓 NOTA: Los outputs son valores que otros componentes necesitarán
# Por ejemplo, el pipeline CI/CD necesitará el nombre del ACR y AKS

# Resource Group
# output "resource_group_name" {
#   description = "Name of the main resource group"
#   value       = azurerm_resource_group.main.name
# }

# 🎓 SOLUCIÓN: Implementamos todos los outputs sugeridos
output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

# output "resource_group_location" {
#   description = "Location of the main resource group"
#   value       = azurerm_resource_group.main.location
# }

output "resource_group_location" {
  description = "Location of the main resource group"
  value       = azurerm_resource_group.main.location
}

# AKS Cluster
# output "aks_cluster_name" {
#   description = "Name of the AKS cluster"
#   value       = azurerm_kubernetes_cluster.main.name
# }

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

# output "aks_cluster_id" {
#   description = "ID of the AKS cluster"
#   value       = azurerm_kubernetes_cluster.main.id
# }

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

# output "aks_kubeconfig" {
#   description = "Kubeconfig for the AKS cluster"
#   value       = azurerm_kubernetes_cluster.main.kube_config_raw
#   sensitive   = true
# }

output "aks_kubeconfig" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true # Importante: marcar como sensible
}

# output "aks_cluster_identity" {
#   description = "Managed identity of the AKS cluster"
#   value = {
#     type         = azurerm_kubernetes_cluster.main.identity[0].type
#     principal_id = azurerm_kubernetes_cluster.main.identity[0].principal_id
#     tenant_id    = azurerm_kubernetes_cluster.main.identity[0].tenant_id
#   }
# }

output "aks_cluster_identity" {
  description = "Managed identity of the AKS cluster"
  value = {
    type         = azurerm_kubernetes_cluster.main.identity[0].type
    principal_id = azurerm_kubernetes_cluster.main.identity[0].principal_id
    tenant_id    = azurerm_kubernetes_cluster.main.identity[0].tenant_id
  }
}

# 🎓 EXTRA: Output adicional útil para ACR integration
output "aks_kubelet_identity" {
  description = "Kubelet identity for ACR integration"
  value = {
    client_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
    object_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  }
}

# Azure Container Registry
# output "acr_name" {
#   description = "Name of the Azure Container Registry"
#   value       = azurerm_container_registry.main.name
# }

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

# output "acr_login_server" {
#   description = "Login server URL for ACR"
#   value       = azurerm_container_registry.main.login_server
# }

output "acr_login_server" {
  description = "Login server URL for ACR"
  value       = azurerm_container_registry.main.login_server
}

# output "acr_id" {
#   description = "ID of the Azure Container Registry"  
#   value       = azurerm_container_registry.main.id
# }

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

# Azure Key Vault
# output "key_vault_name" {
#   description = "Name of the Azure Key Vault"
#   value       = azurerm_key_vault.main.name
# }

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.main.name
}

# output "key_vault_uri" {
#   description = "URI of the Azure Key Vault"
#   value       = azurerm_key_vault.main.vault_uri
#   sensitive   = true
# }

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.main.vault_uri
  sensitive   = true
}

# output "key_vault_id" {
#   description = "ID of the Azure Key Vault"
#   value       = azurerm_key_vault.main.id
# }

output "key_vault_id" {
  description = "ID of the Azure Key Vault"
  value       = azurerm_key_vault.main.id
}

# PostgreSQL Database
# output "postgres_server_name" {
#   description = "Name of the PostgreSQL server"
#   value       = azurerm_postgresql_flexible_server.main.name
# }

output "postgres_server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

# output "postgres_fqdn" {
#   description = "FQDN of the PostgreSQL server"
#   value       = azurerm_postgresql_flexible_server.main.fqdn
#   sensitive   = true
# }

output "postgres_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
  sensitive   = true
}

# output "postgres_database_name" {
#   description = "Name of the PostgreSQL database"
#   value       = azurerm_postgresql_flexible_server_database.main.name
# }

output "postgres_database_name" {
  description = "Name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

# 🎓 EXTRA: Connection string útil para las aplicaciones
output "postgres_connection_string" {
  description = "PostgreSQL connection string for applications"
  value       = "postgresql://${var.postgres_admin_username}@${azurerm_postgresql_flexible_server.main.name}:${random_password.postgres.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
  sensitive   = true
}

# Networking
# output "vnet_name" {
#   description = "Name of the virtual network"
#   value       = azurerm_virtual_network.main.name
# }

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

# output "vnet_id" {
#   description = "ID of the virtual network"
#   value       = azurerm_virtual_network.main.id
# }

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

# output "aks_subnet_id" {
#   description = "ID of the AKS subnet"
#   value       = azurerm_subnet.aks.id
# }

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

# 🎓 EXTRAS: Outputs adicionales útiles
output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.database.id
}

output "agw_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = azurerm_subnet.agw.id
}

# Application Gateway
# output "application_gateway_name" {
#   description = "Name of the Application Gateway"
#   value       = azurerm_application_gateway.main.name
# }

output "application_gateway_name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.main.name
}

# output "application_gateway_public_ip" {
#   description = "Public IP of the Application Gateway"
#   value       = azurerm_public_ip.agw.ip_address
# }

output "application_gateway_public_ip" {
  description = "Public IP of the Application Gateway"
  value       = azurerm_public_ip.agw.ip_address
}

output "application_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

# Monitoring
# output "log_analytics_workspace_id" {
#   description = "ID of the Log Analytics workspace"
#   value       = azurerm_log_analytics_workspace.main.id
# }

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

# output "application_insights_connection_string" {
#   description = "Connection string for Application Insights"
#   value       = azurerm_application_insights.main.connection_string
#   sensitive   = true
# }

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# output "application_insights_instrumentation_key" {
#   description = "Instrumentation key for Application Insights"
#   value       = azurerm_application_insights.main.instrumentation_key
#   sensitive   = true
# }

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_name" {
  description = "Name of Application Insights"
  value       = azurerm_application_insights.main.name
}

# 🎓 EXTRAS: Storage outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "storage_share_name" {
  description = "Name of the file share for uploads"
  value       = azurerm_storage_share.uploads.name
}

# 🎓 OUTPUT FINAL: Resumen útil para referencia rápida
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment            = var.environment
    resource_group         = azurerm_resource_group.main.name
    aks_cluster            = azurerm_kubernetes_cluster.main.name
    acr_registry           = azurerm_container_registry.main.login_server
    key_vault              = azurerm_key_vault.main.name
    postgres_server        = azurerm_postgresql_flexible_server.main.name
    application_gateway_ip = azurerm_public_ip.agw.ip_address
    app_insights           = azurerm_application_insights.main.name
  }
}

# 🎓 BONUS: Next steps instructions
output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value       = <<-EOT
    
    ✅ Infrastructure deployed successfully!
    
    Next steps:
    1. Get AKS credentials:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}
    
    2. Verify cluster access:
       kubectl get nodes
    
    3. Build and push Docker images to ACR:
       az acr build --registry ${azurerm_container_registry.main.name} --image ecommerce-frontend:v1 ./src/frontend
       az acr build --registry ${azurerm_container_registry.main.name} --image ecommerce-backend:v1 ./src/backend
    
    4. Deploy the application using Helm:
       helm install ecommerce ./helm-chart --namespace ecommerce-app --create-namespace
    
    5. Access the application:
       http://${azurerm_public_ip.agw.ip_address}
    
    EOT
}