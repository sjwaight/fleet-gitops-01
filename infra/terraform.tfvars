resource_group = {
  name     = "rg-fleet-gitops-01"
  location = "eastus"
}

fleet = {
  name       = "fleet-gitops-01"
  location   = "eastus"
  dns_prefix = "fleet-gitops-01"
}

aks_clusters = {
  member_01 = {
    name                = "aks-fleet-gitops-01"
    location            = "eastus"
    member_name         = "member-01"
    vm_size             = "Standard_D2s_v5"
    flux_enabled        = true
    flux_extension_name = "flux"
  }
  member_02 = {
    name                = "aks-fleet-gitops-02"
    location            = "westus2"
    member_name         = "member-02"
    vm_size             = "Standard_D2s_v5"
    flux_enabled        = true
    flux_extension_name = "flux"
  }
}

tags = {
  project = "fleet-gitops-01"
}