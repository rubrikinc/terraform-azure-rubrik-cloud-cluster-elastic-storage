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
- [Rubrik Provider for Terraform](https://github.com/rubrikinc/terraform-provider-rubrik) - provides Terraform functions for Rubrik
  - Only required to use the `rubrik_bootstrap_cces_azure` resource.
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

### Inputs

The following are the variables accepted by the module.

#### General Settings

| Name                      | Description                                                                                                                                    |  Type  |          Default           | Required |
| --------------------------| ---------------------------------------------------------------------------------------------------------------------------------------------- | :----: | :------------------------: | :------: |
| azure_location            | The region to deploy Rubrik Cloud Cluster nodes.                                                                                               | string |                            |   yes    |
| azure_resource_group      | The Azure Resource Group into which deploy Rubrik Cloud Cluster resources.                                                                     | string |                            |   yes    |
| azure_resource_lock       | If true, enables Azure's Resource Lock on the Rubrik Cloud Cluster nodes.                                                                      |  bool  |            true            |    no    |
| azure_tags                | Tags to add to the resources that this Terraform script creates, including the Rubrik cluster nodes.                                           |  map   |                            |    no    |


#### Instance/Node Settings

| Name                      | Description                                                                                                                                    |  Type  |          Default           | Required |
| --------------------------| -----------------------------------------------------------------------------------------------------------------------------------------------| :----: | :------------------------: | :------: |
| azure_cces_vm_size        | The virtual machine size of the Rubrik Cloud Cluster nodes. CC-ES requires Standard_D8s_v5 or Standard_D16s_v5.                                | string |      Standard_D16s_v5      |   yes    |
| azure_cces_plan_name      | The Azure Marketplace Plan Name/ID of the CCES image to deploy. See the README.MD file of this module for information on finding the plan name.| string |                            |   yes    |
| azure_cces_sku            | The SKU for the Azure Marketplace Image of CCES to deploy. See the README.MD file of this module for information on finding the SKU.           | string |                            |   yes    |
| azure_cces_version        | The version of CCES to deploy. Use 'latest' to deploy the latest available version. Note: This only applies to the version within a SKU.       | string |          latest            |   yes    |
| azure_key_vault_name      | The name of the Azure Key Vault to create, into which the CCES private ssh key will be stored.                                                 | string |       [cluster_name]       |   yes    |
| number_of_nodes           | The total number of nodes in Rubrik Cloud Cluster.                                                                                             |  int   |             3              |   yes    |


#### Network Settings

| Name                      | Description                                                                                                                                    |  Type  |          Default           | Required |
| --------------------------| ---------------------------------------------------------------------------------------------------------------------------------------------- | :----: | :------------------------: | :------: |
| azure_subnet_name         | Name of the Azure subnet to deploy Rubrik Cloud Cluster into. This subnet must be in the VNet that is defined in the 'azure_vnet_name' variable| string |                            |   yes    |
| azure_vnet_name           | Name of the Azure Virtual Network (VNet) to deploy Rubrik Cloud Cluster ES into.                                                               | string |                            |   yes    |
| azure_vnet_rg_name        | Name of the Resource Group of the Azure VNet that is defined in the 'azure_vnet_name' variable.                                                | string |                            |   yes    |

#### Storage Settings

| Name                      | Description                                                                                                                                    |  Type  |          Default           | Required |
| --------------------------| ---------------------------------------------------------------------------------------------------------------------------------------------- | :----: | :------------------------: | :------: |
| azure_sa_name             | The name of the Azure Storage Account to create for Rubrik Cloud Cluster resources.                                                            | string |                            |   yes    |
| azure_sa_replication_type | The type of replication to use with the the Azure Storage Account for Rubrik Cloud Cluster.                                                    | string |            LRS             |   yes    |
| enable_immutability       | Enable immutability on the S3 objects that CCES uses. Default value is false.                                                                  |  bool  |            true            |    no    |

#### Bootstrap Settings

| Name                      | Description                                                                                                                                    |  Type  |          Default           | Required |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | :----: | :------------------------: | :------: |
| cluster_name              | Unique name to assign to Rubrik Cloud Cluster. Also used for EC2 instance name tag. For example, rubrik-1, rubrik-2 etc.                       | string |                            |   yes    |
| admin_email               | The Rubrik Cloud Cluster sends messages for the admin account to this email address.                                                           | string |                            |   yes    |
| admin_password            | Password for the Rubrik Cloud Cluster admin account.                                                                                           | string |      RubrikGoForward       |    no    |
| dns_search_domain         | List of search domains that the DNS Service will use to resolve host names that are not fully qualified.                                       |  list  |                            |   yes    |
| dns_name_servers          | List of the IPv4 addresses of the DNS servers.                                                                                                 |  list  |    ["169.254.169.253"]     |    no    |
| ntp_server1_name          | The FQDN or IPv4 addresses of network time protocol (NTP) server #1.                                                                           | string |          8.8.8.8           |   yes    |
| ntp_server1_key_id        | The ID # of the key for NTP server #1. Typically is set to 0. (Required with `ntp_server1_key` & `ntp_server1_key_type`)                       |  int   |             0              |    no    |
| ntp_server1_key           | Symmetric key material for NTP server #1. (Required with `ntp_server1_key_id` and `ntp_server1_key_type`)                                      | string |                            |    no    |
| ntp_server1_key_type      | Symmetric key type for NTP server #1. (Required with `ntp_server1_key` and `ntp_server1_key_id`)                                               | string |                            |    no    |
| ntp_server2_name          | The FQDN or IPv4 addresses of network time protocol (NTP) server #2.                                                                           | string |          8.8.4.4           |   yes    |
| ntp_server2_key_id        | The ID # of the key for NTP server #2. Typically is set to 1. (Required with `ntp_server1_key` & `ntp_server1_key_type`)                       |  int   |             1              |    no    |
| ntp_server2_key           | Symmetric key material for NTP server #2. (Required with `ntp_server1_key_id` and `ntp_server1_key_type`)                                      | string |                            |    no    |
| ntp_server2_key_type      | Symmetric key type for NTP server #2. (Required with `ntp_server1_key` and `ntp_server1_key_id`)                                               | string |                            |    no    |
| timeout                   | The number of seconds to wait to establish a connection the Rubrik cluster before returning a timeout error.                                   |  int   |             15             |    no    |

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

Next the plan name for the SKU that has been selected must obtained. Generally with CCES the plan name and the SKU name are the same, however, it is best to check in case they do differ.
To do this run the command:

`az vm image show --location <location> --urn rubrik-inc:rubrik-data-protection:<SKU>:latest --query plan.name --output tsv`

Where <location> is the Azure Location code for the region where CCES will be deployed.
Where <SKU> is the SKU that was selected from the previous step.

Example:

```
-> az vm image show --location westus2 --urn rubrik-inc:rubrik-data-protection:rubrik-cdm-90:latest --query plan.name --output tsv    
rubrik-cdm-90
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

  body = jsonencode({
    properties = {
      serviceEndpoints = [{
        service = "Microsoft.Storage"
      }]
    }
  })
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

## How You Can Help

We glady welcome contributions from the community. From updating the documentation to adding more functionality, all ideas are welcome. Thank you in advance for all of your issues, pull requests, and comments!

- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)

## License

- [MIT License](LICENSE)

## About Rubrik Build

We encourage all contributors to become members. We aim to grow an active, healthy community of contributors, reviewers, and code owners. Learn more in our [Welcome to the Rubrik Build Community](https://github.com/rubrikinc/welcome-to-rubrik-build) page.

We'd love to hear from you! Email us: build@rubrik.com
