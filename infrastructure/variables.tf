# Variables for Azure E-commerce Infrastructure

# Environment configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"

  validation {
    condition     = can(regex("^[A-Za-z ]+$", var.location))
    error_message = "Location must be a valid Azure region name."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ecommerce"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

# TODO: Add variables for AKS configuration
# - aks_node_count (number, default 2, min 1, max 5)
# - aks_vm_size (string, default "Standard_DS2_v2")
# - aks_auto_scaling (bool, default true)
# - aks_min_count (number, default 2)  
# - aks_max_count (number, default 5)

# 🎓 SOLUCIÓN: Variables para AKS según los requisitos
variable "aks_node_count" {
  description = "Initial node count for AKS system pool"
  type        = number
  default     = 2 # Valor por defecto pedido

  validation {
    condition     = var.aks_node_count >= 1 && var.aks_node_count <= 5
    error_message = "Node count must be between 1 and 5 as specified."
  }
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_DS2_v2" # VM size pedida por defecto
}

variable "aks_auto_scaling" {
  description = "Enable auto-scaling for user node pool"
  type        = bool
  default     = true # Habilitado por defecto como se pide
}

variable "aks_min_count" {
  description = "Minimum nodes for auto-scaling"
  type        = number
  default     = 2 # Mínimo pedido
}

variable "aks_max_count" {
  description = "Maximum nodes for auto-scaling"
  type        = number
  default     = 5 # Máximo pedido
}

# TODO: Add variables for database configuration
# - postgres_sku_name (string, default "B_Standard_B1ms")
# - postgres_storage_mb (number, default 32768)
# - postgres_backup_retention_days (number, default 7)
# - postgres_admin_username (string, default "pgadmin")

# 🎓 SOLUCIÓN: Variables para PostgreSQL según especificaciones
variable "postgres_sku_name" {
  description = "SKU for PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms" # SKU Burstable como se pide
}

variable "postgres_storage_mb" {
  description = "Storage in MB for PostgreSQL"
  type        = number
  default     = 32768 # 32GB como se especifica
}

variable "postgres_backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 7 # 7 días como se pide
}

variable "postgres_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "pgadmin" # Usuario por defecto pedido
  sensitive   = true
}

# TODO: Add variables for Application Gateway
# - app_gateway_sku_name (string, default "Standard_v2")
# - app_gateway_sku_tier (string, default "Standard_v2")
# - app_gateway_capacity (number, default 2)

# 🎓 SOLUCIÓN: Variables para Application Gateway
variable "app_gateway_sku_name" {
  description = "SKU name for Application Gateway"
  type        = string
  default     = "Standard_v2" # SKU pedido
}

variable "app_gateway_sku_tier" {
  description = "SKU tier for Application Gateway"
  type        = string
  default     = "Standard_v2" # Tier pedido
}

variable "app_gateway_capacity" {
  description = "Capacity for Application Gateway"
  type        = number
  default     = 2 # Capacidad inicial pedida
}

# TODO: Add variables for monitoring
# - log_analytics_retention_days (number, default 30)
# - enable_application_insights (bool, default true)

# 🎓 SOLUCIÓN: Variables para monitoreo
variable "log_analytics_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30 # 30 días como se especifica
}

variable "enable_application_insights" {
  description = "Enable Application Insights"
  type        = bool
  default     = true # Habilitado por defecto
}

# TODO: Add variables for networking
# - vnet_address_space (list(string), default ["10.0.0.0/16"])
# - aks_subnet_address_prefix (string, default "10.0.1.0/24")
# - db_subnet_address_prefix (string, default "10.0.2.0/24")  
# - agw_subnet_address_prefix (string, default "10.0.3.0/24")

# 🎓 SOLUCIÓN: Variables de red con los rangos especificados
variable "vnet_address_space" {
  description = "Address space for Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"] # Rango pedido para la VNet
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.0.1.0/24" # Subnet AKS como se especifica
}

variable "db_subnet_address_prefix" {
  description = "Address prefix for database subnet"
  type        = string
  default     = "10.0.2.0/24" # Subnet DB como se especifica
}

variable "agw_subnet_address_prefix" {
  description = "Address prefix for Application Gateway subnet"
  type        = string
  default     = "10.0.3.0/24" # Subnet AGW como se especifica
}

# Locals for resource naming and tagging
locals {
  # TODO: Define naming convention
  # name_prefix = "${var.project_name}-${var.environment}"

  # 🎓 SOLUCIÓN: Implementamos el naming convention sugerido
  name_prefix = "${var.project_name}-${var.environment}"

  # TODO: Define common tags
  # common_tags = {
  #   Environment = var.environment
  #   Project     = var.project_name
  #   ManagedBy   = "Terraform"
  #   Owner       = "DevOps-Team"
  #   CostCenter  = "Engineering"
  # }

  # 🎓 SOLUCIÓN: Tags exactamente como se sugieren + algunos extras útiles
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "Terraform"
    Owner         = "DevOps-Team"
    CostCenter    = "Engineering"
    CreatedDate   = timestamp()
    TechnicalTest = "true" # Para identificar recursos de la prueba
  }

  # 🎓 EXTRA: Helpers para nombres de recursos (Azure tiene límites de caracteres)
  resource_group_name = "rg-${local.name_prefix}"
  aks_cluster_name    = "aks-${local.name_prefix}"
  acr_name            = replace("acr${local.name_prefix}", "-", "") # ACR no permite guiones
  keyvault_name       = "kv-${substr(local.name_prefix, 0, 20)}"    # Max 24 chars
}