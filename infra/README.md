# Fleet Infrastructure

This Terraform configuration provisions one resource group, one Azure Kubernetes
Fleet Manager with a public hub cluster, and exactly two AKS member clusters with
two nodes each. Both AKS clusters have the Microsoft Flux extension enabled by
default and are joined to the Fleet Manager.

## Parameters

Edit [terraform.tfvars](terraform.tfvars), the main parameters file. Set the name
and Azure region independently for the resource group, Fleet Manager, and each
AKS cluster. The Fleet hub uses the Fleet Manager's region; membership and Flux
extension resources inherit their parent cluster's region and have no independent
region setting. Azure manages the underlying hub cluster's name.

Each AKS entry also configures its Fleet member name, VM size, Flux extension name,
and whether Flux is enabled. Omitting `flux_enabled` enables Flux. Map keys such as
`member_01` are Terraform resource identities; keep them stable after deployment.
Choose regions supporting AKS and Fleet, and VM sizes available with sufficient
quota in your subscription. The defaults provision four AKS worker VMs in total.

## Deploy

Install Terraform 1.7 or later (before 2.0) and Azure CLI. Sign in with an identity
that can create resource groups, AKS clusters, Fleet resources, and Kubernetes
extensions. The `Microsoft.ContainerService` and
`Microsoft.KubernetesConfiguration` resource providers must be registered; the
AzureRM provider normally handles registration, which requires subscription-level
registration permissions.

From this directory:

```bash
az login
az account set --subscription "<subscription-id>"
export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
terraform init
terraform fmt -check
terraform validate
terraform test
terraform plan -out=deployment.tfplan
terraform apply deployment.tfplan
```

AzureRM manages AKS, extensions, and Fleet memberships. AzAPI manages the Fleet
resource because AzureRM does not expose the hub configuration. The hub is
explicitly public (`enablePrivateCluster = false`); this is a demo configuration,
not a hardened production baseline.

`terraform test` uses mocked providers to check the public hub, two-node clusters,
Flux defaults, and Fleet memberships without creating resources or signing in.

Terraform defaults to local state. Keep state secure because it can contain AKS
credentials, and use a secured remote backend for shared deployments. Commit the
generated provider lock file to keep provider selections reproducible.

This configuration installs Flux on the AKS members but does not create Flux Git
sources, Flux configurations, or Kubernetes RBAC resources. Continue with the
[repository walkthrough](../README.md) to enable Flux on the Fleet hub and apply
the GitOps manifests and `flux-applier` authorization.

## Remove

```bash
terraform destroy
```

This removes all resources created by this configuration, including the resource
group and both clusters.
