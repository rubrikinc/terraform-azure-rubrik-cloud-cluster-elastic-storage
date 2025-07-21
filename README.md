# Terraform Module - Azure Cloud Cluster Elastic Storage Deployment

Terraform module which deploys a new Rubrik Cloud Cluster Elastic Storage (CCES) in Azure.

## Documentation

Here are some resources to get you started! If you find any challenges from this project are not properly documented or are unclear, please [raise an issue](../../issues/new/choose) and let us know! This is a fun, safe environment - don't worry if you're a GitHub newbie!

- [Microsoft Azure CLI Overview](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Microsoft Azure CLI Installation](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Microsoft Azure CLI Authentication](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
- [Terraform Module Registry](https://registry.terraform.io/modules/rubrikinc/rubrik-azure-cloud-cluster-elastic-storage)
- [Terraform Module for AzureRM CLI Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)

## Prerequisites

There are a few services you'll need in order to get this project off the ground:

- [Terraform](https://www.terraform.io/downloads.html) v1.5.1 or greater
- [Rubrik RSC Provider for Terraform](https://github.com/rubrikinc/terraform-provider-polaris) - provides Terraform functions for Rubrik
  - Only required to use the `polaris_cdm_bootstrap_cces_azure` resource.
- [Install the Azure CLI tools](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) - Needed for Terraform to authenticate with Azure

### Usage

```hcl
module "rubrik_azure_cloud_cluster_elastic_storage" {
  source  = "rubrikinc/rubrik-cloud-cluster-elastic-storage/azure"

  azure_location        = "West US2"
  azure_resource_group  = "Rubrik-CCES" 
  number_of_nodes       = 3
  azure_cces_plan_name  = "rubrik-cdm-90"
  azure_cces_sku        = "rubrik-cdm-90"
  azure_subnet_name     = "private-subnet"
  azure_vnet_name       = "private-vnet"
  azure_vnet_rg_name    = "Company_VNets"
  azure_sa_name         = "rubrikcces"

  cluster_name          = "rubrik-cloud-cluster"
  admin_email           = "build@rubrik.com"
  admin_password        = "RubrikGoForward"
  dns_search_domain     = ["rubrikdemo.com"]
  dns_name_servers      = ["192.168.100.5","192.168.100.6"]
  ntp_server1_name      = "8.8.8.8"
  ntp_server2_name      = "8.8.4.4"
}
```

## Changelog

### v1.0.0
- Remove hard-coded provider setup
- Add TF-Docs
- Fix SKU Regex
- Bump RSC provider to 1.1.1

### v0.2.0
- Initial stable release of the Terraform module for deploying Rubrik Cloud Cluster Elastic Storage (CCES) in Azure
- Support for deploying multi-node CCES clusters with configurable node count
- Automated Azure Storage Account and container creation with optional immutability features
- SSH key pair generation and secure storage in Azure Key Vault
- Network interface and VM provisioning with marketplace image support
- Automatic disk attachment for data, metadata, and cache storage (split disk support for CDM 9.2.2+)
- Bootstrap integration using Polaris provider for automated cluster configuration
- Comprehensive variable validation and resource locking capabilities
- Support for custom Azure tags and resource group management
- Initial module development and testing
- Basic CCES deployment functionality
- Core Azure resource provisioning

## Upgrading

### v0.2.0 to v1.0.0

1. Update the `source` line in the `module` block to `source  = "rubrikinc/rubrik-cloud-cluster-elastic-storage/azure"`
2. Update the `version` line in the `module` block to `version = "1.0.0"`
3. Configure providers in your `main.tf`:
```hcl
# Configure the Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = "12345678-1234-1234-1234-123456789012"
}

provider "azapi" {}

provider "polaris" {}

module "rubrik_azure_cloud_cluster_elastic_storage" {
  source  = "rubrikinc/rubrik-cloud-cluster-elastic-storage/azure"
  
  <existing variables>
}

```
4. Run `terraform init --upgrade` to update the module
5. Run `terraform plan` to verify the upgrade
6. Run `terraform apply` to apply the upgrade

### Login to Azure

Before running Terraform using the `azurerm_*` or `azapi_*` data sources and resources, an authentication with Azure is required. [Terraform Module for AzureRM CLI Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)
provides a complete guide on how to authenticate Terraform with Azure. The following commands can be used from a command line interface with the [Microsoft Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
to manually run Terraform:

`az login --tenant <tenant_id>`

Where <tenant_id> is the ID of the tenant to login to. If you only have one tenant you can remove the `--tenant` option.

Next before running this module, the subscription must be selected. Do this by running the command:

`az account set --subscription <subscription_id>`

Where <subscription_id> is the ID of the subscription where CCES will be deployed.

### Accept the Azure Marketplace Agreement for CCES

In order to deploy Cloud Cluster ES from the Azure marketplace two things must happen. First the marketplace agreement for the specific plan must be accepted in the subscription where
Cloud Cluster ES will be deployed. Second the `azure_cces_plan_name` and `azure_cces_sku` variables of this module must be updated with the correct information. 

One method for accepting the Marketplace Agreement is to use the Azure CLI. To do this the SKU of the Azure Marketplace Plan for CCES to use must first be identified. To do this run the command:

`az vm image list-skus --location <location> -p rubrik-inc -f rubrik-data-protection --output table`

Where <location> is the Azure Location code for the region where CCES will be deployed. Example:

```
-> az vm image list-skus --location westus2 -p rubrik-inc -f rubrik-data-protection --output table
Location    Name
----------  --------------
westus2     rubrik-cdm-60
westus2     rubrik-cdm-70
westus2     rubrik-cdm-80
westus2     rubrik-cdm-81
westus2     rubrik-cdm-90
```

Tke SKUs in the output will represent the major and minor version numbers of the various Rubrik CCES releases. For example `rubrik-cdm-90` represents Rubrik CDM v9.0.x. The specific
maintenance release will be selected later on. select the SKU name for the version of CCES that you plan to use.

Next the plan name for the SKU that has been selected must be obtained. Generally with CCES the plan name and the SKU name are the same, however, it is best to check in case they do differ.
To do this run the command:

`az vm image show --location <location> --urn rubrik-inc:rubrik-data-protection:<SKU>:latest --query plan.name --output tsv`

Where <location> is the Azure Location code for the region where CCES will be deployed.
Where <SKU> is the SKU that was selected from the previous step.

Example:

```
-> az vm image show --location westus2 --urn rubrik-inc:rubrik-data-protection:rubrik-cdm-90:latest --query plan.name --output tsv    
```

Next the Azure Marketplace Agreement must be accepted. To do this run the command:

```
az vm image terms accept --offer rubrik-data-protection --publisher rubrik-inc --plan <plan_name> --output jsonc
```

Where <plan_name> is the name of the plan that was collected in the previous step.

Example:

```
az vm image terms accept --offer rubrik-data-protection --publisher rubrik-inc --plan rubrik-cdm-90 --output jsonc  

{
  "accepted": true,
  "id": "/subscriptions/<Subscription_ID>/providers/Microsoft.MarketplaceOrdering/offerTypes/Microsoft.MarketplaceOrdering/offertypes/publishers/rubrik-inc/offers/rubrik-data-protection/plans/rubrik-cdm-90/agreements/current",
  "licenseTextLink": "https://storelegalterms.blob.core.windows.net/legalterms/3E5ED_legalterms_RUBRIK%253a2DINC%253a24RUBRIK%253a2DDATA%253a2DPROTECTION%253a24RUBRIK%253a2DCDM%253a2D90%253a24JRAHGUAQ44GVF2TFRYQ5727EY5ZA3HLQ3KU2L76ISIHHQQY2ZJYDCGQTOHXDJ7LU7UO4PPM6UM6DMUQXIIVE763XZJZZNTLHNRCZXBA.txt",
  "marketplaceTermsLink": "https://mpcprodsa.blob.core.windows.net/marketplaceterms/3EDEF_marketplaceterms_VIRTUALMACHINE%253a24AAK2OAIZEAWW5H4MSP5KSTVB6NDKKRTUBAU23BRFTWN4YC2MQLJUB5ZEYUOUJBVF3YK34CIVPZL2HWYASPGDUY5O2FWEGRBYOXWZE5Y.txt",
  "name": "rubrik-cdm-90",
  "plan": "rubrik-cdm-90",
  "privacyPolicyLink": "https://www.rubrik.com/legal/privacy-policy",
  "product": "rubrik-data-protection",
  "publisher": "rubrik-inc",
  "retrieveDatetime": "2023-09-04T05:14:55.6081829Z",
  "signature": "<Unique_Signature>",
  "systemData": {
    "createdAt": "2023-09-04T05:14:57.794366+00:00",
    "createdBy": "<Subscription_ID>",
    "createdByType": "ManagedIdentity",
    "lastModifiedAt": "2023-09-04T05:14:57.794366+00:00",
    "lastModifiedBy": "<Subscription_ID>",
    "lastModifiedByType": "ManagedIdentity"
  },
  "type": "Microsoft.MarketplaceOrdering/offertypes"
}
```

Verify that the `accepted` field is set to `true`.

In the Terraform variables set the `azure_cces_plan_name` and `azure_cces_sku` variables to those that were collected in this section.

### (Optional) Select the version of CCES to deploy.

By default this module will deploy the latest version of CCES that is available in the SKU that the `azure_cces_sku` variable is set to. If a specific version of CCES is desired for a 
given SKU, run the following command to get the available version numbers:

`az vm image list --location <location> --publisher rubrik-inc --offer rubrik-data-protection --sku <SKU> --all --query sku --query "[].version" --output tsv`

Where <location> is the Azure Location code for the region where CCES will be deployed.
Where <SKU> is the SKU that was selected from the previous step.

With CDM v8.0 and earlier the versions numbers represent the `major.minor.maintenance` number of the release. For example `8.0.3` represents `CDM 8.0.3-p9-22986`. There
is an assumption that every maintenance release is the latest patch release as well. As patches are released to a maintenance release, the older patch release is removed. 

With CDM v8.1 and later the version numbers represent the `minor.maintenance.build` number of the release. The SKU number represents the `major.minor` number of the release.
For example the plan `rubrik-cdm-81` with a version number of `3.1.24838` represents `8.1.3-p1-24838`. This notation allows the user to understand what patch release is 
represented in the marketplace. The build numbers correspond to the various patch releases. 

Set the Terraform variable `azure_cces_version` to the version number from the list that is desired. Setting the `azure_cces_version` variable to `latest` will deploy the latest
version of CCES from the list.

### Subnet Network Storage Endpoint

This module will attempt to enable the Storage Endpoint in the subnet where CCES is deployed. A Storage Endpoint is required by CCES. If a VNet Storage Endpoint or private Storage
Endpoint will be used, disable the following lines in the `main.tf` file of this module:

``` hcl
resource "azapi_update_resource" "cces_subnet_storage_endpoint" {

  type        = "Microsoft.Network/virtualNetworks/subnets@2023-02-01"
  resource_id = data.azurerm_subnet.cces_subnet.id

  body = {
    properties = {
      serviceEndpoints = [{
        service = "Microsoft.Storage"
      }]
    }
  }
}
```

### Bootstrapping the Cloud Cluster

The `resource "rubrik_bootstrap_cces_azure" "bootstrap_rubrik_cces_azure"` resource block will attempt to bootstrap the Cloud Cluster. To use this block properly, the system that runs this Terraform module
must have the [Rubrik Provider for Terraform](https://github.com/rubrikinc/terraform-provider-rubrik) installed. The system running this Terraform module must also be able to contact the Cloud Cluster on
its private IP address. If the resource for bootstrapping the Rubrik Cloud Cluster is not used, bootstrap the Rubrik Cloud Cluster as documented in the Rubrik Cloud Cluster guide, after this module has run.
After bootstrapping, the Cloud Cluster can be configured through the Web UI.

### Initialize the Directory

The directory can be initialized for Terraform use by running the `terraform init` command:

```none
-> terraform init

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Reusing previous version of azure/azapi from the dependency lock file
- Reusing previous version of hashicorp/time from the dependency lock file
- Reusing previous version of hashicorp/tls from the dependency lock file
- Reusing previous version of rubrikinc/rubrik/rubrik from the dependency lock file
- Using previously-installed hashicorp/azurerm v3.71.0
- Using previously-installed azure/azapi v1.8.0
- Using previously-installed hashicorp/time v0.9.1
- Using previously-installed hashicorp/tls v4.0.4
- Using previously-installed rubrikinc/rubrik/rubrik v2.2.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### Planning

Run `terraform plan` to get information about what will happen when we apply the configuration; this will test that everything is set up correctly.

### Applying

We can now apply the configuration to create the cluster using the `terraform apply` command.

### Destroying

Once the Cloud Cluster is no longer required, it can be destroyed using the `terraform destroy` command, and entering `yes` when prompted.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >=2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~>4.14.0 |
| <a name="requirement_polaris"></a> [polaris](#requirement\_polaris) | ~>1.1.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 2.5.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.14.0 |
| <a name="provider_polaris"></a> [polaris](#provider\_polaris) | 0.8.0-beta.4 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.cc_container](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_update_resource.cces_subnet_storage_endpoint](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) | resource |
| [azurerm_key_vault.cc_key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_secret.cc_private_ssh_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_linux_virtual_machine.cces_node](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_managed_disk.cces_cache_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_managed_disk.cces_data_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_managed_disk.cces_metadata_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_management_lock.cces_cache_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_management_lock.cces_data_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_management_lock.cces_metadata_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_management_lock.cces_nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_management_lock.cces_node](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_network_interface.cces_nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_resource_group.cc_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_ssh_public_key.cc_public_ssh_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ssh_public_key) | resource |
| [azurerm_storage_account.cc_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_virtual_machine_data_disk_attachment.cces_cache_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_data_disk_attachment.cces_data_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_data_disk_attachment.cces_metadata_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [polaris_cdm_bootstrap_cces_azure.bootstrap_cces_azure](https://registry.terraform.io/providers/rubrikinc/polaris/latest/docs/resources/cdm_bootstrap_cces_azure) | resource |
| [time_sleep.wait_for_nodes_to_boot](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_private_key.cc-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_subnet.cces_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_email"></a> [admin\_email](#input\_admin\_email) | The Rubrik Cloud Cluster sends messages for the admin account to this email address. | `string` | n/a | yes |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Password for the Rubrik Cloud Cluster admin account. | `string` | `"ChangeMe"` | no |
| <a name="input_azure_cces_plan_name"></a> [azure\_cces\_plan\_name](#input\_azure\_cces\_plan\_name) | The Azure Marketplace Plan Name/ID of the CCES image to deploy. See the README.MD file of this module for information on finding the plan name. | `any` | n/a | yes |
| <a name="input_azure_cces_sku"></a> [azure\_cces\_sku](#input\_azure\_cces\_sku) | The SKU for the Azure Marketplace Image of CCES to deploy. See the README.MD file of this module for information on finding the SKU. | `string` | n/a | yes |
| <a name="input_azure_cces_version"></a> [azure\_cces\_version](#input\_azure\_cces\_version) | The version of CCES to deploy. Use 'latest' to deploy the latest available version. Note: This only applies to the version within a SKU (major/minor version). | `string` | `"latest"` | no |
| <a name="input_azure_cces_vm_size"></a> [azure\_cces\_vm\_size](#input\_azure\_cces\_vm\_size) | The Azure VM Machine Type to use for the Cloud Cluster nodes. | `string` | `"Standard_D16s_v5"` | no |
| <a name="input_azure_key_vault_name"></a> [azure\_key\_vault\_name](#input\_azure\_key\_vault\_name) | The name of the Azure Key Vault to create, into which the CCES private ssh key will be stored. | `string` | `""` | no |
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | The region to deploy Rubrik Cloud Cluster resources. | `any` | n/a | yes |
| <a name="input_azure_resource_group"></a> [azure\_resource\_group](#input\_azure\_resource\_group) | The Azure Resource Group into which deploy Rubrik Cloud Cluster resources. | `string` | `"RubrikCloudCluster"` | no |
| <a name="input_azure_resource_lock"></a> [azure\_resource\_lock](#input\_azure\_resource\_lock) | Enable the Azure Resource Lock on critical components that are created by this module. | `bool` | `true` | no |
| <a name="input_azure_sa_name"></a> [azure\_sa\_name](#input\_azure\_sa\_name) | The name of the Azure Storage Account to create for Rubrik Cloud Cluster resources. | `string` | n/a | yes |
| <a name="input_azure_sa_replication_type"></a> [azure\_sa\_replication\_type](#input\_azure\_sa\_replication\_type) | The type of replication to use with the the Azure Storage Account for Rubrik Cloud Cluster. | `string` | `"LRS"` | no |
| <a name="input_azure_subnet_name"></a> [azure\_subnet\_name](#input\_azure\_subnet\_name) | Name of the Azure subnet to deploy Rubrik Cloud Cluster into. This subnet must be in the VNet that is defined in the 'azure\_vnet\_name' variable. | `string` | n/a | yes |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | Subscription ID of the Azure account to deploy Rubrik Cloud Cluster resources. | `string` | n/a | yes |
| <a name="input_azure_tags"></a> [azure\_tags](#input\_azure\_tags) | Tags to add to the Azure resources that this Terraform script creates, including the Rubrik cluster nodes. | `map(string)` | `{}` | no |
| <a name="input_azure_vnet_name"></a> [azure\_vnet\_name](#input\_azure\_vnet\_name) | Name of the Azure Virtual Network (VNet) to deploy Rubrik Cloud Cluster ES into. | `string` | n/a | yes |
| <a name="input_azure_vnet_rg_name"></a> [azure\_vnet\_rg\_name](#input\_azure\_vnet\_rg\_name) | Name of the Resource Group of the Azure VNet that is defined in the 'azure\_vnet\_name' variable. | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Unique name to assign to the Rubrik Cloud Cluster. This will also be used as part of the Storage Account name. For example, rubrik-cloud-cluster-1, rubrik-cloud-cluster-2 etc. | `string` | `"rubrik-cloud-cluster"` | no |
| <a name="input_dns_name_servers"></a> [dns\_name\_servers](#input\_dns\_name\_servers) | List of the IPv4 addresses of the DNS servers. | `list(any)` | <pre>[<br/>  "169.254.169.253"<br/>]</pre> | no |
| <a name="input_dns_search_domain"></a> [dns\_search\_domain](#input\_dns\_search\_domain) | List of search domains that the DNS Service will use to resolve host names that are not fully qualified. | `list(any)` | `[]` | no |
| <a name="input_enableImmutability"></a> [enableImmutability](#input\_enableImmutability) | Enables object lock and versioning on the Storage Account and Container. Sets the object lock flag during bootstrap. Not supported on CDM v8.0.1 and earlier. | `bool` | `true` | no |
| <a name="input_ntp_server1_key"></a> [ntp\_server1\_key](#input\_ntp\_server1\_key) | Symmetric key material for NTP server #1. | `string` | `""` | no |
| <a name="input_ntp_server1_key_id"></a> [ntp\_server1\_key\_id](#input\_ntp\_server1\_key\_id) | The ID number of the symmetric key used with NTP server #1. (Typically this is 0) | `number` | `0` | no |
| <a name="input_ntp_server1_key_type"></a> [ntp\_server1\_key\_type](#input\_ntp\_server1\_key\_type) | Symmetric key type for NTP server #1. | `string` | `""` | no |
| <a name="input_ntp_server1_name"></a> [ntp\_server1\_name](#input\_ntp\_server1\_name) | The FQDN or IPv4 addresses of network time protocol (NTP) server #1. | `string` | `"8.8.8.8"` | no |
| <a name="input_ntp_server2_key"></a> [ntp\_server2\_key](#input\_ntp\_server2\_key) | Symmetric key material for NTP server #2. | `string` | `""` | no |
| <a name="input_ntp_server2_key_id"></a> [ntp\_server2\_key\_id](#input\_ntp\_server2\_key\_id) | The ID number of the symmetric key used with NTP server #2. (Typically this is 0) | `number` | `0` | no |
| <a name="input_ntp_server2_key_type"></a> [ntp\_server2\_key\_type](#input\_ntp\_server2\_key\_type) | Symmetric key type for NTP server #2. | `string` | `""` | no |
| <a name="input_ntp_server2_name"></a> [ntp\_server2\_name](#input\_ntp\_server2\_name) | The FQDN or IPv4 addresses of network time protocol (NTP) server #2. | `string` | `"8.8.4.4"` | no |
| <a name="input_number_of_nodes"></a> [number\_of\_nodes](#input\_number\_of\_nodes) | The total number of nodes in Rubrik Cloud Cluster. | `number` | `3` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The number of seconds to wait to establish a connection the Rubrik cluster before returning a timeout error. | `string` | `"4m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_key_vault_get_ssh_key_command"></a> [key\_vault\_get\_ssh\_key\_command](#output\_key\_vault\_get\_ssh\_key\_command) | n/a |
| <a name="output_rubrik_cloud_cluster_ip_addresses"></a> [rubrik\_cloud\_cluster\_ip\_addresses](#output\_rubrik\_cloud\_cluster\_ip\_addresses) | n/a |
<!-- END_TF_DOCS -->

## How You Can Help

We glady welcome contributions from the community. From updating the documentation to adding more functionality, all ideas are welcome. Thank you in advance for all of your issues, pull requests, and comments!

- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)

## License

- [MIT License](LICENSE)

## About Rubrik Build

We encourage all contributors to become members. We aim to grow an active, healthy community of contributors, reviewers, and code owners. Learn more in our [Welcome to the Rubrik Build Community](https://github.com/rubrikinc/welcome-to-rubrik-build) page.

We'd love to hear from you! Email us: build@rubrik.com
