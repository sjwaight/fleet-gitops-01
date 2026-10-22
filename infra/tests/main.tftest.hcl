mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
    }
  }

  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-test"
    }
  }
}

mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/fleets/fleet-test"
    }
  }
}

variables {
  resource_group = {
    name     = "rg-test"
    location = "eastus"
  }

  fleet = {
    name       = "fleet-test"
    location   = "westus2"
    dns_prefix = "fleet-test-hub"
  }

  aks_clusters = {
    first = {
      name        = "aks-first"
      location    = "eastus"
      member_name = "fleet-first"
    }
    second = {
      name        = "aks-second"
      location    = "westus2"
      member_name = "fleet-second"
    }
  }
}

run "public_hub_and_two_flux_members" {
  command = apply

  assert {
    condition = (
      azapi_resource.fleet.name == var.fleet.name &&
      azapi_resource.fleet.location == var.fleet.location &&
      azapi_resource.fleet.body.properties.hubProfile.dnsPrefix == var.fleet.dns_prefix &&
      azapi_resource.fleet.body.properties.hubProfile.apiServerAccessProfile.enablePrivateCluster == false
    )
    error_message = "Fleet must have the configured name, region, DNS prefix, and a public hub."
  }

  assert {
    condition = length(azurerm_kubernetes_cluster.member) == 2 && alltrue([
      for key, cluster in azurerm_kubernetes_cluster.member :
      cluster.default_node_pool[0].node_count == 2 &&
      cluster.name == var.aks_clusters[key].name &&
      cluster.location == var.aks_clusters[key].location
    ])
    error_message = "Exactly two AKS clusters must each have two nodes and use their configured name and region."
  }

  assert {
    condition = length(azurerm_kubernetes_cluster_extension.flux) == 2 && alltrue([
      for key, extension in azurerm_kubernetes_cluster_extension.flux :
      extension.extension_type == "microsoft.flux" &&
      extension.cluster_id == azurerm_kubernetes_cluster.member[key].id
    ])
    error_message = "Flux must be installed on both clusters when flux_enabled is omitted."
  }

  assert {
    condition = length(azurerm_kubernetes_fleet_member.member) == 2 && alltrue([
      for key, member in azurerm_kubernetes_fleet_member.member :
      member.name == var.aks_clusters[key].member_name &&
      member.kubernetes_fleet_id == azapi_resource.fleet.id &&
      member.kubernetes_cluster_id == azurerm_kubernetes_cluster.member[key].id
    ])
    error_message = "Both AKS clusters must join the configured Fleet with the configured member names."
  }
}

run "flux_can_be_disabled_per_cluster" {
  command = plan

  variables {
    aks_clusters = {
      first = {
        name         = "aks-first"
        location     = "eastus"
        member_name  = "fleet-first"
        flux_enabled = false
      }
      second = {
        name        = "aks-second"
        location    = "westus2"
        member_name = "fleet-second"
      }
    }
  }

  assert {
    condition = (
      length(azurerm_kubernetes_cluster_extension.flux) == 1 &&
      contains(keys(azurerm_kubernetes_cluster_extension.flux), "second") &&
      length(azurerm_kubernetes_fleet_member.member) == 2
    )
    error_message = "Disabling Flux on one cluster must not affect the other extension or either membership."
  }
}

run "reject_single_cluster" {
  command = plan

  variables {
    aks_clusters = {
      first = {
        name        = "aks-first"
        location    = "eastus"
        member_name = "fleet-first"
      }
    }
  }

  expect_failures = [var.aks_clusters]
}