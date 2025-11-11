output "resource_group_name" {
  description = "The name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "The ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

output "vm_id" {
  description = "The ID of the created Virtual Machine"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "The name of the created Virtual Machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "public_ip_id" {
  description = "The ID of the public IP"
  value       = azurerm_public_ip.main.id
}

output "private_ip_address" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "vm_admin_username" {
  description = "The admin username for SSH access"
  value       = var.admin_username
}

output "ssh_connection_string" {
  description = "SSH connection string to access the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "redis_cache_hostname" {
  description = "The hostname of the Redis cache"
  value       = azurerm_redis_cache.main.hostname
}

output "redis_cache_port" {
  description = "The port of the Redis cache"
  value       = azurerm_redis_cache.main.port
}

output "redis_cache_ssl_port" {
  description = "The SSL port of the Redis cache"
  value       = azurerm_redis_cache.main.ssl_port
}

output "redis_primary_access_key" {
  description = "The primary access key for Redis cache"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "redis_connection_string" {
  description = "The Redis connection string (SSL)"
  value       = "${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port},password=${azurerm_redis_cache.main.primary_access_key},ssl=True"
  sensitive   = true
}

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "virtual_network_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "The ID of the Subnet"
  value       = azurerm_subnet.main.id
}

output "nsg_id" {
  description = "The ID of the Network Security Group"
  value       = azurerm_network_security_group.main.id
}

output "dns_nameservers" {
  description = "The nameservers for the DNS zone (if created)"
  value       = var.create_dns_zone ? azurerm_dns_zone.main[0].name_servers : null
}

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    public_ip        = azurerm_public_ip.main.ip_address
    domain_endpoint  = "https://${var.dns_record_name}.${var.domain_name}"
    redis_endpoint   = "${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}"
    ssh_access       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
  }
}
