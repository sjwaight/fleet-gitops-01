variable "resource_group" {
  description = "Name and Azure region for the resource group. Resources can use different regions."
  type = object({
    name     = string
    location = string
  })
}

variable "fleet" {
  description = "Name, Azure region, and hub DNS prefix for the public-hub Fleet Manager."
  type = object({
    name       = string
    location   = string
    dns_prefix = string
  })
}

variable "aks_clusters" {
  description = "Exactly two AKS clusters, each with two nodes. Flux is enabled by default. Fleet memberships and extensions inherit the cluster region."
  type = map(object({
    name                = string
    location            = string
    member_name         = string
    vm_size             = optional(string, "Standard_D2s_v5")
    flux_enabled        = optional(bool, true)
    flux_extension_name = optional(string, "flux")
  }))

  validation {
    condition     = length(var.aks_clusters) == 2
    error_message = "Specify exactly two AKS clusters."
  }

  validation {
    condition     = length(distinct([for cluster in var.aks_clusters : cluster.name])) == length(var.aks_clusters)
    error_message = "AKS cluster names must be unique within the resource group."
  }

  validation {
    condition     = length(distinct([for cluster in var.aks_clusters : cluster.member_name])) == length(var.aks_clusters)
    error_message = "Fleet member names must be unique within the Fleet Manager."
  }
}

variable "tags" {
  description = "Tags applied to the resource group, Fleet Manager, and AKS clusters."
  type        = map(string)
  default     = {}
}