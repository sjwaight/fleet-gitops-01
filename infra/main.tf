resource "azurerm_resource_group" "main" {
  name     = var.resource_group.name
  location = var.resource_group.location
  tags     = var.tags
}

resource "azapi_resource" "fleet" {
  type      = "Microsoft.ContainerService/fleets@2025-03-01"
  name      = var.fleet.name
  location  = var.fleet.location
  parent_id = azurerm_resource_group.main.id
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      hubProfile = {
        dnsPrefix = var.fleet.dns_prefix
        agentProfile = {
            vmSize = var.fleet.vm_size
        }
        apiServerAccessProfile = {
          enablePrivateCluster = false
        }
      }
    }
  }
}

resource "azurerm_kubernetes_cluster" "member" {
  for_each = var.aks_clusters

  name                = each.value.name
  location            = each.value.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = each.value.name
  sku_tier            = "Free"
  tags                = var.tags

  default_node_pool {
    name       = "system"
    node_count = 2
    vm_size    = each.value.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
  }

  role_based_access_control_enabled = true
}

resource "azurerm_kubernetes_cluster_extension" "flux" {
  for_each = {
    for key, cluster in var.aks_clusters : key => cluster
    if cluster.flux_enabled
  }

  name           = each.value.flux_extension_name
  cluster_id     = azurerm_kubernetes_cluster.member[each.key].id
  extension_type = "microsoft.flux"
  release_train  = "Stable"
}

resource "azurerm_kubernetes_fleet_member" "member" {
  for_each = var.aks_clusters

  name                  = each.value.member_name
  kubernetes_fleet_id   = azapi_resource.fleet.id
  kubernetes_cluster_id = azurerm_kubernetes_cluster.member[each.key].id
}