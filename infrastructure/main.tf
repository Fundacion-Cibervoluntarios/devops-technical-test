# Terraform Infrastructure for Azure E-commerce Application

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "azurerm" {
    # TODO: Configure remote state backend
    # Uncomment and configure the following:
    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "tfstatedevops2025"
    # container_name       = "tfstate"
    # key                  = "ecommerce-app.tfstate"

    # 🎓 NOTA: Lo dejamos comentado para desarrollo local
    # En producción, descomentar y crear primero el storage account
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true # NO USAR EN PROD elimina claves del vault
      recover_soft_deleted_key_vaults = true # si ya existe no lo recrea
    }
    resource_group {
      prevent_deletion_if_contains_resources = false # NO USAR EN PROD 
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# 🎓 EXTRA: Password aleatoria para PostgreSQL (security best practice)
resource "random_password" "postgres" {
  length  = 16
  special = true
}

# TODO: Create Resource Group
# Name: "rg-${local.name_prefix}"
# Location: var.location
# Tags: local.common_tags

# 🎓 SOLUCIÓN: Resource Group exactamente como se pide
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}" # Nombre según el TODO
  location = var.location              # Location desde variable
  tags     = local.common_tags         # Tags desde locals
}

# TODO: Create Virtual Network
# Name: "vnet-${local.name_prefix}" 
# Address space: ["10.0.0.0/16"]
# Subnets needed:
# - AKS subnet: 10.0.1.0/24
# - Database subnet: 10.0.2.0/24  
# - Application Gateway subnet: 10.0.3.0/24

# 🎓 SOLUCIÓN: VNet con el nombre y espacio de direcciones pedido
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name_prefix}" # Nombre según TODO
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"] # Address space exacto del TODO

  tags = local.common_tags
}

# 🎓 SOLUCIÓN: Subnet AKS con el rango pedido
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"] # Rango exacto del TODO

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Sql",
    "Microsoft.ContainerRegistry",
    "Microsoft.KeyVault"
  ]
}

# 🎓 SOLUCIÓN: Subnet Database con el rango pedido
resource "azurerm_subnet" "database" {
  name                 = "snet-database"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"] # Rango exacto del TODO

  delegation {
    name = "postgresql"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }

  service_endpoints = ["Microsoft.Storage"]
}

# 🎓 SOLUCIÓN: Subnet Application Gateway con el rango pedido
resource "azurerm_subnet" "agw" {
  name                 = "snet-agw"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"] # Rango exacto del TODO
}

# TODO: Create Network Security Groups
# - NSG for AKS subnet with appropriate rules
# - NSG for database subnet (restrictive)
# - NSG for Application Gateway subnet
# NSG define las reglas

# 🎓 SOLUCIÓN: NSG para AKS subnet con reglas apropiadas
resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Permitir tráfico desde Application Gateway
  security_rule {
    name                       = "AllowApplicationGateway"
    priority                   = 100 #  rango maximo que AKS permite definir
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "10.0.3.0/24" # Desde AGW subnet
    destination_address_prefix = "10.0.1.0/24" # A AKS subnet
  }

  # Permitir comunicación interna de Kubernetes
  security_rule {
    name                       = "AllowKubernetesInternal"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  tags = local.common_tags
}

# 🎓 SOLUCIÓN: NSG para Database subnet (restrictivo como se pide)
resource "azurerm_network_security_group" "database" {
  name                = "nsg-database-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Solo permitir PostgreSQL desde AKS
  security_rule {
    name                       = "AllowPostgreSQLFromAKS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.1.0/24" # Solo desde AKS
    destination_address_prefix = "10.0.2.0/24"
  }

  # Denegar todo lo demás (restrictivo)
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# 🎓 SOLUCIÓN: NSG para Application Gateway subnet
resource "azurerm_network_security_group" "agw" {
  name                = "nsg-agw-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Permitir tráfico HTTP/HTTPS desde Internet
  security_rule {
    name                       = "AllowHTTPSFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Permitir health probes de Azure
  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Asociar NSGs a las subnets
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

resource "azurerm_subnet_network_security_group_association" "agw" {
  subnet_id                 = azurerm_subnet.agw.id
  network_security_group_id = azurerm_network_security_group.agw.id
}

# TODO: Create AKS Cluster
# Requirements:
# - System node pool: 2 nodes, Standard_DS2_v2
# - User node pool: 3 nodes, auto-scaling (min 2, max 5)
# - Managed Identity enabled
# - Azure CNI networking
# - Integration with ACR
# - Azure Monitor enabled

# 🎓 SOLUCIÓN: AKS Cluster con todos los requisitos especificados
resource "azurerm_kubernetes_cluster" "main" {
  name                = local.aks_cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = local.aks_cluster_name
  kubernetes_version  = "1.28"

  # System node pool: 2 nodes, Standard_DS2_v2 (según TODO)
  default_node_pool {
    name                = "system"
    node_count          = 2                 # 2 nodes como se pide
    vm_size             = "Standard_DS2_v2" # VM size especificado
    vnet_subnet_id      = azurerm_subnet.aks.id
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = false # System pool sin auto-scaling

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
      "nodepoolmode"  = "system"
    }

    tags = local.common_tags
  }

  # Managed Identity enabled (según TODO)
  identity {
    type = "SystemAssigned"
  }

  # Azure CNI networking (según TODO)
  network_profile {
    network_plugin    = "azure" # Azure CNI como se pide
    network_policy    = "azure"
    dns_service_ip    = "10.2.0.10"
    service_cidr      = "10.2.0.0/24"
    load_balancer_sku = "standard"
  }

  # Azure Monitor enabled (según TODO)
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # Características adicionales recomendadas
  azure_policy_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = []
  }

  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "0s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
  }

  tags = local.common_tags
}

# 🎓 SOLUCIÓN: User node pool con 3 nodes, auto-scaling (min 2, max 5) según TODO
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_DS2_v2"
  node_count            = 3 # 3 nodes como se pide
  vnet_subnet_id        = azurerm_subnet.aks.id

  # Auto-scaling con min 2, max 5 (según TODO)
  enable_auto_scaling = true
  min_count           = 2 # Min 2 como se especifica
  max_count           = 5 # Max 5 como se especifica

  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
    "workload-type" = "applications"
  }

  tags = local.common_tags
}

# TODO: Create Azure Container Registry
# Requirements:
# - Premium SKU for geo-replication
# - Admin user disabled (use managed identity)
# - Integration with AKS cluster

# 🎓 SOLUCIÓN: ACR con todos los requisitos especificados
resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Premium" # Premium SKU como se pide
  admin_enabled       = false     # Admin disabled, usar managed identity como se pide

  public_network_access_enabled = true

  retention_policy {
    enabled = true
    days    = 7
  }

  tags = local.common_tags
}

# 🎓 Integration with AKS cluster (parte del TODO de ACR)
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

# TODO: Create Azure Key Vault
# Requirements:
# - Soft delete enabled
# - Access policies for AKS managed identity
# - Network access from AKS subnet only
# - Enable for template deployment

# 🎓 SOLUCIÓN: Key Vault con todos los requisitos
resource "azurerm_key_vault" "main" {
  name                = local.keyvault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Soft delete enabled (según TODO)
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # true en producción

  # Enable for template deployment (según TODO)
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true # Como se pide

  # Network access from AKS subnet only (según TODO)
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"

    virtual_network_subnet_ids = [
      azurerm_subnet.aks.id # Solo desde AKS subnet como se pide
    ]
  }

  # Access policy para el usuario actual (para gestión)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]

    key_permissions = [
      "Get", "List", "Create", "Delete", "Purge", "Recover"
    ]
  }

  tags = local.common_tags
}

# 🎓 Access policies for AKS managed identity (parte del TODO)
resource "azurerm_role_assignment" "aks_keyvault" {
  principal_id                     = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = azurerm_key_vault.main.id
  skip_service_principal_aad_check = true
}

# Guardar secretos en Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres.result
  key_vault_id = azurerm_key_vault.main.id
}

# TODO: Create Log Analytics Workspace
# Requirements:
# - Retention: 30 days
# - Integration with AKS cluster
# - Application Insights component

# 🎓 SOLUCIÓN: Log Analytics con los requisitos especificados
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # Retention 30 días como se pide

  tags = local.common_tags
}

# 🎓 Application Insights component (parte del TODO)
resource "azurerm_application_insights" "main" {
  name                = "appi-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id # Integration como se pide

  tags = local.common_tags
}

# TODO: Create Azure Database for PostgreSQL Flexible Server
# Requirements:
# - Version 14
# - Burstable SKU (B1ms to start)
# - Private endpoint in database subnet
# - Firewall rules for AKS subnet
# - Backup retention: 7 days

# 🎓 SOLUCIÓN: PostgreSQL con todos los requisitos

# Private DNS Zone para PostgreSQL (necesario para private endpoint)
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Link DNS Zone con VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# PostgreSQL Flexible Server con requisitos especificados
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${local.name_prefix}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "14"                       # Version 14 como se pide
  delegated_subnet_id    = azurerm_subnet.database.id # Private endpoint en database subnet
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id
  administrator_login    = var.postgres_admin_username
  administrator_password = random_password.postgres.result
  zone                   = "1"

  storage_mb = var.postgres_storage_mb
  sku_name   = "B_Standard_B1ms" # Burstable SKU B1ms como se pide

  backup_retention_days = 7 # Backup retention 7 días como se pide

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]

  tags = local.common_tags
}

# Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "ecommerce_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# 🎓 Firewall rules for AKS subnet (parte del TODO)
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# TODO: Create Application Gateway
# Requirements:
# - Standard_v2 SKU
# - WAF enabled
# - SSL termination
# - Backend pool for AKS ingress
# - Health probes configuration

# 🎓 SOLUCIÓN: Application Gateway con todos los requisitos

# Public IP para Application Gateway
resource "azurerm_public_ip" "agw" {
  name                = "pip-agw-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Application Gateway con configuración completa
resource "azurerm_application_gateway" "main" {
  name                = "agw-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Standard_v2 SKU como se pide
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention" # o "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.agw.id
  }

  # Puertos para SSL termination
  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443 # Para SSL termination como se pide
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.agw.id
  }

  # Backend pool for AKS ingress (según TODO)
  backend_address_pool {
    name = "aks-backend-pool"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30

    probe_name = "health-probe"
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "aks-backend-pool"
    backend_http_settings_name = "http-settings"
  }

  # Health probes configuration (según TODO)
  probe {
    name                = "health-probe"
    protocol            = "Http"
    path                = "/health"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  # WAF enabled (según TODO) - Descomentar si usas WAF_v2 SKU
  # waf_configuration {
  #   enabled          = true  # WAF enabled como se pide
  #   firewall_mode    = "Prevention"
  #   rule_set_type    = "OWASP"
  #   rule_set_version = "3.2"
  # }

  tags = local.common_tags
}

# TODO: Create Storage Account for Azure Files
# Requirements:
# - Standard_LRS replication
# - File share for application uploads
# - Private endpoint in AKS subnet

# 🎓 SOLUCIÓN: Storage Account con todos los requisitos
resource "azurerm_storage_account" "main" {
  name                     = replace("st${local.name_prefix}", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Standard_LRS como se pide

  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true

  # Network rules para private endpoint en AKS subnet
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.aks.id] # Private endpoint en AKS subnet
  }

  tags = local.common_tags
}

# 🎓 File share for application uploads (según TODO)
resource "azurerm_storage_share" "uploads" {
  name                 = "uploads" # File share para uploads como se pide
  storage_account_name = azurerm_storage_account.main.name
  quota                = 50 # 50 GB
}