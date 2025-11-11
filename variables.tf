variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-demo-app"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Southeast Asia"
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
  default     = "prod"
}

# Virtual Network Configuration
variable "vnet_address_space" {
  description = "Address space for Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# VM Configuration
variable "vm_name" {
  description = "Name of the Virtual Machine"
  type        = string
  default     = "vm-app-server"
}

variable "vm_size" {
  description = "VM size (8 vCPU, 32 GB RAM)"
  type        = string
  default     = "Standard_D8s_v3"  # 8 vCPU, 32 GB RAM
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 256
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key for VM access"
  type        = string
  # Example: "~/.ssh/id_rsa.pub" - replace with your actual SSH public key path
}

variable "ssh_source_ip" {
  description = "IP address or CIDR for SSH access"
  type        = string
  default     = "*"  # Change to your IP for better security, e.g., "1.2.3.4/32"
}

# Redis Cache Configuration
variable "redis_cache_name" {
  description = "Name of the Azure Cache for Redis"
  type        = string
  default     = "redis-demo-app"
}

variable "redis_capacity" {
  description = "Redis capacity (0 = 250MB, 1 = 1GB, 2 = 2.5GB, etc.)"
  type        = number
  default     = 0  # Minimum plan: 250MB
}

variable "redis_family" {
  description = "Redis family (C = Basic/Standard, P = Premium)"
  type        = string
  default     = "C"  # Basic
}

variable "redis_sku_name" {
  description = "Redis SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

# DNS Configuration
variable "create_dns_zone" {
  description = "Whether to create DNS zone in Azure"
  type        = bool
  default     = false  # Set to true if you want to manage DNS in Azure
}

variable "domain_name" {
  description = "Domain name (e.g., example.com)"
  type        = string
  default     = "example.com"
}

variable "dns_record_name" {
  description = "DNS record name (e.g., demo for demo.example.com)"
  type        = string
  default     = "demo"
}

# Key Vault Configuration
variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
  default     = "kv-demo-app"
}

variable "environment_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    "Environment" = "Production"
    "Project"     = "Demo App"
    "ManagedBy"   = "Terraform"
  }
}
