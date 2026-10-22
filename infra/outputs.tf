output "resource_group_name" {
  description = "Resource group containing the Fleet Manager and AKS clusters."
  value       = azurerm_resource_group.main.name
}

output "fleet_id" {
  description = "Resource ID of the Fleet Manager with a public hub."
  value       = azapi_resource.fleet.id
}

output "fleet_name" {
  description = "Fleet Manager name for Azure CLI commands."
  value       = azapi_resource.fleet.name
}

output "aks_clusters" {
  description = "Member cluster names, regions, resource IDs, and Flux extension IDs."
  value = {
    for key, cluster in azurerm_kubernetes_cluster.member : key => {
      name              = cluster.name
      location          = cluster.location
      id                = cluster.id
      fleet_member_id   = azurerm_kubernetes_fleet_member.member[key].id
      flux_extension_id = try(azurerm_kubernetes_cluster_extension.flux[key].id, null)
    }
  }
}