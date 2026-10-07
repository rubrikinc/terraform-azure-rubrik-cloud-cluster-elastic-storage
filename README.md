# Terraform Module - Azure Cloud Cluster Elastic Storage Deployment
This module deploys a new Rubrik Cloud Cluster Elastic Storage (CCES) in Azure.

## Usage
```hcl
module "rubrik_azure_cloud_cluster_elastic_storage" {
  source  = "rubrikinc/rubrik-cloud-cluster-elastic-storage/azure"
  version = "2.0.0"

  admin_email           = "build@rubrik.com"
  admin_password        = "RubrikGoForward"
  azure_cces_plan_name  = "rubrik-cdm-90"
  azure_cces_sku        = "rubrik-cdm-90"
  azure_location        = "West US2"
  azure_resource_group  = "Rubrik-CCES"
  azure_sa_name         = "rubrikcces"
  azure_subnet_name     = "private-subnet"
  azure_vnet_name       = "private-vnet"
  azure_vnet_rg_name    = "Company_VNets"
  cluster_name          = "rubrik-cloud-cluster"
  dns_name_servers      = ["8.8.8.8", "8.8.4.4"]
  dns_search_domain     = ["rubrikdemo.com"]
  number_of_nodes       = 3
  ntp_server1_name      = "0.north-america.pool.ntp.org"
  ntp_server2_name      = "1.north-america.pool.ntp.org"
}
```

## Changelog

### v2.0.0
* Address the findings that Azure security scanners raise against the module. Settings that can disrupt a running
  cluster are opt-in input variables that default to the current behavior, so upgrading the module doesn't change how
  an existing cluster runs unless the variables are set. See the upgrade instructions in the README before upgrading.
* Add the `azure_sa_restrict_network_access` input variable, which sets the default action of the Storage Account
  network rules to `Deny` and only allows the CCES subnet and trusted Azure services. Hosts outside the CCES subnet
  can be allowed with the new `azure_sa_allowed_ip_ranges` input variable.
* Add support for encrypting the Storage Account and the disks, including the OS disks, with customer-managed keys.
  Set `azure_sa_cmk_key_vault_key_id` and `azure_disk_cmk_key_vault_key_id` to the IDs of Key Vault keys, together
  with `azure_cmk_user_assigned_identity_id`. The module creates a disk encryption set which double encrypts the disks
  with both a platform-managed key and the customer-managed key. The Key Vault and the keys are not created by the
  module.
* Add the `azure_enable_encryption_at_host`, `azure_enable_boot_diagnostics` and `azure_allow_extension_operations`
  input variables for the nodes. Encryption at host requires the `Microsoft.Compute/EncryptionAtHost` feature to be
  registered on the Azure subscription.
* Add the `azure_sa_logs_log_analytics_workspace_id`, `azure_sa_logs_storage_account_id`,
  `azure_sa_logs_eventhub_authorization_rule_id` and `azure_sa_logs_eventhub_name` input variables, which send the
  read, write and delete logs of the Storage Account to a destination provided by the user. Do not send the logs to
  the CCES Storage Account.
* Add the `azure_sa_container_soft_delete_days` and `azure_sa_sas_expiration_period` input variables.
* Apply these settings to all deployments. They are updated in place and don't affect CCES:
  * Storage Account: disallow public access to containers, make Entra ID the default authentication in the Azure
    portal, disable local users, enable container soft delete for 7 days, set a SAS expiration policy that only logs,
    require SMB 3.1.1 and explicitly allow trusted Azure services. This disables soft delete for file shares, which is
    enabled by default for new Storage Accounts, and which Rubrik requires to be disabled.
  * Managed disks: set the network access policy to `DenyAll` and disable public network access. This only affects
    exporting a disk through a SAS URL.
* The network rules of the Storage Account are now managed by the new `azurerm_storage_account_network_rules`
  resource. It is added to the plan of an existing deployment, and changes nothing unless
  `azure_sa_restrict_network_access` is set.
* The following findings are not addressed, since CCES doesn't support the setting:
  * Blob soft delete, infrastructure encryption and disabling Storage Account shared key access. Rubrik requires blob
    soft delete and infrastructure encryption to be disabled and the shared key access to be enabled, since the
    bootstrap of the cluster authenticates with the Storage Account connection string. Infrastructure encryption can
    also only be set when the Storage Account is created.
  * vTPM, Secure Boot, Trusted Launch and Confidential VM. They are not supported by CCES.
  * Periodic assessment of missing system updates. Azure rejects it for the CCES image. CDM is updated through CDM
    upgrades.
  * A locked immutability policy on the Storage Account. Rubrik requires the container to have no attached retention
    policies, since CDM manages the immutability locks of the backups itself.
  * Azure Disk Encryption. Rubrik doesn't document it as supported on CCES nodes. Use the customer-managed keys and
    encryption at host instead.

This is released as a major version since the upgrade changes the Storage Account and all the managed disks of an
existing deployment, and since the optional settings are disruptive when they are enabled on a running cluster.

### v1.1.0
* Change the host caching mode of the Rubrik Cloud Cluster metadata disk from `ReadWrite` to `None`. CDM 9.3.3 and later
  require this. With `ReadWrite` the bootstrap of a new cluster fails, and on a running cluster the daily configuration
  health check fails.
* Change the host caching mode of the Rubrik Cloud Cluster OS disk from `ReadWrite` to `None` on CDM 9.2.2 and later,
  following the Rubrik host caching recommendation. Deployments of earlier CDM versions keep `ReadWrite` and are left
  unchanged.
* The data disk and the cache disk are unchanged and keep `ReadWrite`. CDM before 9.3.3 requires `ReadWrite` on
  the data disk.
* Attach the data, metadata and cache disks to a cluster node one at a time, and wait for the nodes to be created before
  attaching the first disk. Attaching a disk updates the virtual machine, and two updates that overlap fail with a
  conflicting concurrent write error from Azure.
* Add the `azure_os_disk_caching` and `azure_metadata_disk_caching` module input variables, which override the host
  caching mode of the OS disk and the metadata disk.

This is released as a minor version, and not as a patch version, so that existing deployments using a `~> 1.0.0` version
constraint are not upgraded automatically. Applying the new host caching mode to an existing cluster is disruptive. See
the upgrade instructions below before upgrading.

### v1.0.3
* Constrain the Azure RM Terraform provider to `>=4.14.0` and `<5.0.0`. The module is not yet compatible with
  version 5 of the Azure RM provider.

### v1.0.2
* Make the Storage service endpoint of the VPC optional. The Storage endpoint is enabled by default, but it's possible
  to not enable it by setting `azure_enable_subnet_storage_endpoint` module input variable to `false`.
* Add support for automatically registering the Rubrik Cloud Cluster with Rubrik Security Cloud. To register the cluster
  set the `register_cluster_with_rsc` module input variable to `true`.
* NTP servers can now be specified using a FQDN. Previously they were required to be IP addresses, now both IP addresses
  and FQDN are allowed.
* Relax the version constraint for the Azure RM Terraform provider to `>=4.14.0`.
* Bump the RSC (polaris) Terraform provider from version `~>1.1.1` to `>=1.1.3`.
* Run `terraform fmt` on the module.

### v1.0.1
* Deprecate the `azure_subscription_id` module input variable in favor of provider configuration provided by the root
  module.

### v1.0.0
* Remove hard-coded provider setup from the module.
* Add `gen_docs.sh` script and update the Terraform documentation.
* Fix SKU regular expression.
* Bump RSC (polaris) Terraform provider to `1.1.1`.

### v0.2.0
* Initial stable release of the Terraform module for deploying Rubrik Cloud Cluster Elastic Storage (CCES) in Azure.
* Support for deploying multi-node CCES clusters with configurable node count.
* Automated Azure Storage Account and container creation with optional immutability features.
* SSH key pair generation and secure storage in Azure Key Vault.
* Network interface and VM provisioning with marketplace image support.
* Automatic disk attachment for data, metadata, and cache storage (split disk support for CDM 9.2.2+).
* Bootstrap integration using Polaris provider for automated cluster configuration.
* Comprehensive variable validation and resource locking capabilities.
* Support for custom Azure tags and resource group management.
* Initial module development and testing.
* Basic CCES deployment functionality.
* Core Azure resource provisioning.

## Upgrading
Before upgrading the module, be sure to read through the changelog to understand the changes in the new version and any
upgrade instruction for the version you are upgrading to. 

To upgrade the module to a new version, use the following steps:
1. Update the `version` field in the `module` block to the version you want to upgrade to, e.g. `version = "2.0.0"`.
2. Run `terraform init --upgrade` to update the modules in your configuration.
3. Run `terraform plan` and check the output carefully to ensure that there are no unexpected changes caused by the
   upgrade.
4. Run `terraform apply` if there are expected changes that you want to apply.

Note, as variables in the module are deprecated, you may see warnings in the output of `terraform plan`. These warnings
can be ignored, but it's recommended that you follow the instructions in the deprecation message. Eventually deprecated
variables will be removed.

### v1.1.0 to v2.0.0
Version `v2.0.0` hardens the Storage Account and the managed disks of every deployment, and adds optional settings that
are disabled by default. Upgrading doesn't restart the cluster nodes and doesn't change how CCES reaches its storage.

The plan of an existing deployment contains these changes, and no resources are destroyed or recreated:
```text
# module.<module-name>.azurerm_storage_account.cc_storage_account will be updated in-place
# module.<module-name>.azurerm_storage_account_network_rules.cc_storage_account will be created
# module.<module-name>.azurerm_managed_disk.cces_data_disk["<node-name>"] will be updated in-place
# module.<module-name>.azurerm_managed_disk.cces_metadata_disk["<node-name>"] will be updated in-place
# module.<module-name>.azurerm_managed_disk.cces_cache_disk["<node-name>"] will be updated in-place
```
The Storage Account is updated to disallow public access to containers, make Entra ID the default authentication in the
Azure portal, disable local users, enable container soft delete, add a SAS expiration policy that only logs, require
SMB 3.1.1 and disable soft delete for file shares. The managed disks have their network access policy changed to
`DenyAll` and public network access disabled, which only affects exporting a disk through a SAS URL. The new network
rules resource keeps the default action of the Storage Account at `Allow`, until `azure_sa_restrict_network_access`
is set. None of these changes affect the CCES data path, and no `azurerm_linux_virtual_machine` is changed.

The optional settings are not applied until their input variables are set. Enabling them on a running cluster has this
impact:

| Input variable                                                                 | Impact when enabled on a running cluster                               |
|--------------------------------------------------------------------------------|------------------------------------------------------------------------|
| `azure_sa_restrict_network_access`                                             | In-place. Hosts outside the CCES subnet are denied access to the data. |
| `azure_sa_cmk_key_vault_key_id`                                                | In-place. The Storage Account depends on the Key Vault key.            |
| `azure_disk_cmk_key_vault_key_id`                                              | **Deallocates and restarts the nodes.**                                |
| `azure_enable_encryption_at_host`                                              | **Deallocates and restarts the nodes.**                                |
| `azure_enable_boot_diagnostics`, `azure_allow_extension_operations`            | In-place.                                                              |
| `azure_sa_logs_*`                                                              | Adds diagnostic settings to the Storage Account.                       |

See [Security Settings](#security-settings) for how to use them. Apply the settings that restart the nodes during a
maintenance window.

This change is released as a major version so that existing deployments are not upgraded automatically. Deployments
using a version constraint such as `version = "~> 1.1"` will not pick up `v2.0.0`.

### v1.0.2 to v1.1.0
In version `v1.1.0` the host caching mode of the Rubrik Cloud Cluster metadata disk changed from `ReadWrite` to
`None`, because CDM 9.3.3 and later require it. With `ReadWrite` the bootstrap of a new cluster fails and the daily
configuration health check fails on a running cluster. The host caching mode of the OS disk also changed to `None`,
but only on CDM 9.2.2 and later, following the Rubrik host caching recommendation. The data disk and the cache disk
are unchanged and keep `ReadWrite`, which is what CDM before 9.3.3 requires of the data disk.

The metadata disk only exists on CDM 9.2.2 and later, and the OS disk keeps `ReadWrite` on earlier versions, so the
disks of a deployment of a CDM version before 9.2.2 are left untouched.

Every upgrade adds one resource to the plan, whichever CDM version is deployed:
```text
# module.<module-name>.time_sleep.wait_for_nodes_to_provision will be created
```
It delays the first disk attachment while the cluster nodes are being created, to avoid a race in Azure that fails
the attachment with a conflicting concurrent write. It has no effect on nodes that already exist, so applying it
changes nothing about a running cluster.

No resources are destroyed or recreated by this change, the virtual machines and the disk attachments are updated in
place. A deployment of CDM 9.2.2 or later sees two in-place updates per cluster node, one for the OS disk and one for
the metadata disk. Applying it to a running cluster is still disruptive. The
[Azure documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/premium-storage-performance#disk-caching)
states:

> Changing the cache setting of an Azure disk detaches and reattaches the target disk. If it's the operating system
> disk, the VM is restarted. Stop all applications and services that might be affected by this disruption before you
> change the disk cache setting. Not following those recommendations could lead to data corruption.

In other words, the OS disk change restarts the node and the metadata disk change detaches and reattaches that disk.
Apply the change during a maintenance window and upgrade one node at a time. A deployment of a CDM version before
9.2.2 has neither change and can be upgraded without disruption.

If you are not ready for the disruption, either change can be deferred by setting its input variable back to
`ReadWrite`. Use `azure_os_disk_caching` to defer the node restart and `azure_metadata_disk_caching` to defer
detaching and reattaching the metadata disk.

This change is released as a minor version so that existing deployments are not upgraded automatically. Deployments
using `version = "1.0.2"` or `version = "~> 1.0.0"` will not pick up `v1.1.0`. Deployments using a wider version
constraint, such as `version = "~> 1.0"` or `version = ">= 1.0"`, will pick it up on the next
`terraform init --upgrade`. Pin the version before upgrading if you are not ready for the change.

### v1.0.0 to v1.0.1
In version `v1.0.1` the `azure_subscription_id` input variable has been deprecated. If you are using the input variable,
you will see a warning message similar to this:
```text
The 'azure_subscription_id' variable is deprecated and should not be used as it will be removed in a future release. Configure the subscription ID in the azurerm provider configuration instead.
```
Remove the variable from your module block and instead pass it to the Azure RM provider configuration block in the root
module. Similar to this:
```hcl
provider "azurerm" {
  subscription_id = "<subscription-id>"
}
```
Where `<subscription-id>` is your Azure subscription ID.

### v0.2.0 to v1.0.0
In version `v1.0.0` the provider configuration blocks has been removed from the module to support the `for_each`
meta-argument. Instead, the configuration blocks needs to be specified in the root module of the Terraform
configuration. If your root module doesn't already contain a provider configuration block for the Azure RM provider,
you can use this provider configuration block: 
```hcl
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = "<subscription-id>"
}
```
Where `<subscription-id>` is your Azure subscription ID.

## Authenticating with Azure
You can authenticate Terraform with Azure by either using the Azure CLI or by using environment variables.

### Authenticating with Azure CLI
[Terraform Module for AzureRM CLI Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)
provides a complete guide on how to authenticate Terraform with Azure. The following commands can be used from a command
line interface with the [Microsoft Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) to manually
run Terraform:
```shell
az login --tenant <tenant-id>
```
Where `<tenant-id>` is the ID of the tenant to log in to. If you only have one tenant you can remove the `--tenant`
option.

Next before running this module, the subscription must be selected. Do this by running the command:
```shell
az account set --subscription <subscription-id>
```
Where `<subscription-id>` is the ID of the subscription where CCES will be deployed.

### Authenticating with Environment Variables
For environments that require a non-interactive authentication method such as Terraform Cloud, the Azure CLI can be
authenticated using environment variables. The following environment variables must be set:
* `ARM_CLIENT_ID`
* `ARM_CLIENT_SECRET`
* `ARM_TENANT_ID`
Additionally, you can set `ARM_SUBSCRIPTION_ID`. But if you specify the subscription ID in the root module of your
configuration, this is not mandatory.

The environment variables can be set as follows in your terminal:
```shell
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_TENANT_ID="<tenant-id>"
```
Where `<client-id>` is the application ID of your application in Entra ID, `<client-secret>` is the secret of your
application in Entra ID and `<tenant-id>` is the ID of your tenant in Azure. Alternatively, they can be added to the
workspace variables in Terraform Cloud.

If you unsure how to get these, you can use the Azure CLI to create a service principal and get the values. See the
[Azure CLI documentation](https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli) for
more information.

### Accept the Azure Marketplace Agreement for CCES
In order to deploy Cloud Cluster ES from the Azure marketplace two things must happen. First, the marketplace agreement
for the specific plan must be accepted in the subscription where Cloud Cluster ES will be deployed. Second, valid values
for the `azure_cces_plan_name` and `azure_cces_sku` input variables must be collected. 

One method for accepting the Marketplace Agreement is to use the Azure CLI. To do this the SKU of the Azure Marketplace
Plan for CCES to use must first be identified. To do this run the command:
```shell
az vm image list-skus --location <location> -p rubrik-inc -f rubrik-data-protection --output table
```
Where `<location>` is the Azure Location code for the region where CCES will be deployed. E.g:
```shell
az vm image list-skus --location westus2 -p rubrik-inc -f rubrik-data-protection --output table
```
Depending on the current set of SKUs available, the result should look something similar to:
```
Location    Name
----------  --------------
westus2     rubrik-cdm-60
westus2     rubrik-cdm-70
westus2     rubrik-cdm-80
westus2     rubrik-cdm-81
westus2     rubrik-cdm-90
```

Tke SKUs in the output will represent the major and minor version numbers of the various Rubrik CCES releases. For
example `rubrik-cdm-90` represents Rubrik CDM `v9.0.x`. The specific maintenance release will be selected later on.
Select the SKU name for the version of CCES that you plan to use.

Next the plan name for the SKU that has been selected must be obtained. Generally with CCES the plan name and the SKU
name are the same, however, it is best to check in case they do differ. To do this run the command:
```shell
az vm image show --location <location> --urn rubrik-inc:rubrik-data-protection:<SKU>:latest --query plan.name --output tsv
```
Where `<location>` is the Azure Location code for the region where CCES will be deployed and `<SKU>` is the SKU that was
selected in the previous step. E.g:
```shell
az vm image show --location westus2 --urn rubrik-inc:rubrik-data-protection:rubrik-cdm-90:latest --query plan.name --output tsv    
```

Next the Azure Marketplace Agreement must be accepted. To do this run the command:
```shell
az vm image terms accept --offer rubrik-data-protection --publisher rubrik-inc --plan <plan-name> --output jsonc
```
Where `<plan-name>` is the name of the plan that was collected in the previous step. E.g:
```shell
az vm image terms accept --offer rubrik-data-protection --publisher rubrik-inc --plan rubrik-cdm-90 --output jsonc  
```
Depending on the plan accepted, the result should look something similar to:
```
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

The values for the `azure_cces_sku` and the `azure_cces_plan_name` input variables are the SKU name and plan name that
were collected in the previous steps.

### Select the version of CCES to deploy (optional)
By default, this module will deploy the latest version of CCES that is available in the SKU that the `azure_cces_sku`
input variable is set to. If a specific version of CCES is desired for a given SKU, run the following command to get the
available version numbers:
```shell
az vm image list --location <location> --publisher rubrik-inc --offer rubrik-data-protection --sku <SKU> --all --query sku --query "[].version" --output tsv
```
Where `<location>` is the Azure Location code for the region where CCES will be deployed and `<SKU>` is the SKU that was
selected in the previous step.

With CDM `v8.0` and earlier the versions numbers represent the `major.minor.maintenance` number of the release. For
example `8.0.3` represents `CDM 8.0.3-p9-22986`. There is an assumption that every maintenance release is the latest
patch release as well. As patches are released to a maintenance release, the older patch release is removed. 

With CDM `v8.1` and later the version numbers represent the `minor.maintenance.build` number of the release. The SKU
number represents the `major.minor` number of the release. For example the plan `rubrik-cdm-81` with a version number of
`3.1.24838` represents `8.1.3-p1-24838`. This notation allows the user to understand what patch release is represented
in the marketplace. The build numbers correspond to the various patch releases. 

Set the input variable `azure_cces_version` to the version number from the list that is desired. Setting the
`azure_cces_version` input variable to `latest` will deploy the latest version of CCES from the list.

### Subnet Network Storage Endpoint
This module will attempt to enable the Storage Endpoint in the subnet where CCES is deployed by default. A Storage
Endpoint is required by CCES. If a VNet Storage Endpoint or private Storage Endpoint will be used, the default behaviour
of the module can be disabled by setting the `azure_enable_subnet_storage_endpoint` to `false`.

### Accelerated Networking and the Azure Network Adapter
CCES requires Azure Accelerated Networking, which this module enables on the network interface of each cluster
node. CDM releases before `9.5.1` detect it by looking for a Mellanox device inside the guest. Azure has started
replacing Mellanox with the Microsoft Azure Network Adapter (MANA), which those releases don't recognise, so the
bootstrap of a new cluster fails with the message:
```text
Azure Accelerated Networking is not enabled on this node.
```
This happens even though Accelerated Networking is enabled on the network interface. Azure started placing the VM
sizes used by this module on MANA capable hardware on 2026-05-26, and which hardware a node lands on can't be
requested.

Deploying CDM `9.5.1` or later avoids the problem. To deploy an earlier release, the `LegacyVMNVA` tag keeps the
nodes off MANA capable hardware:
```hcl
azure_tags = {
  LegacyVMNVA = "true"
}
```
The tag has to be set when the cluster nodes are created, and Azure honours it until 2027-05-31. It also restricts
the nodes to a smaller pool of hardware, which makes allocation failures more likely. Note that the module applies
the `azure_tags` input variable to all the resources it creates, not only to the cluster nodes. See
[MANA support for Network Virtual Appliances](https://learn.microsoft.com/en-us/azure/virtual-network/accelerated-networking-mana-network-virtual-appliance-opt-out)
for details.

## Security Settings
The module applies a set of security settings to the Storage Account and the managed disks of every deployment. They
are updated in place and don't affect CCES. The settings in this section are optional, since enabling them can
disrupt a running cluster. They are all disabled by default.

### Restricting Network Access to the Storage Account
Set the `azure_sa_restrict_network_access` input variable to `true` to set the default action of the Storage Account
network rules to `Deny`. Only the CCES subnet, trusted Azure services and the IP addresses in the
`azure_sa_allowed_ip_ranges` input variable are allowed access. The CCES nodes reach the Storage Account through the
Storage service endpoint of the CCES subnet, so the endpoint must exist before the rules are applied. The module
enables it by default, see [Subnet Network Storage Endpoint](#subnet-network-storage-endpoint). If
`azure_enable_subnet_storage_endpoint` is `false`, the subnet must already have the endpoint.

Clients outside the CCES subnet, for example hosts used to browse the data in the Storage Account, are denied access
unless their public IP address is in `azure_sa_allowed_ip_ranges`. Terraform only uses the Azure management API for
the Storage Account and the container, so a Terraform runner outside the CCES subnet is not affected.

### Customer-Managed Keys
By default the Storage Account and the disks are encrypted with Microsoft-managed keys. Both can instead be
encrypted with a customer-managed key (CMK), and they are configured independently of each other. CDM doesn't need
any configuration for either. The Key Vault, the keys and the managed identity are owned by you, the module doesn't
create them. Before applying the module:
1. Create an Azure Key Vault with soft delete and purge protection enabled, and an RSA key in it. For the disks, the
   Key Vault must be in the same region and tenant as the deployment.
2. Create a user-assigned managed identity, and give it the `Get`, `Wrap Key` and `Unwrap Key` key permissions, or the
   `Key Vault Crypto Service Encryption User` role, on the key.

Then set `azure_cmk_user_assigned_identity_id` to the ID of the identity, and set `azure_sa_cmk_key_vault_key_id` for
the Storage Account and `azure_disk_cmk_key_vault_key_id` for the disks to the IDs of the keys. Use a key ID without a
version to have Azure automatically use the latest version of the key. For the disks the module creates a disk
encryption set, which double encrypts the OS disks and the data, metadata and cache disks with both a platform-managed
key and the customer-managed key.
```hcl
azure_cmk_user_assigned_identity_id = "/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<name>"
azure_sa_cmk_key_vault_key_id       = "https://<key-vault-name>.vault.azure.net/keys/<key-name>"
azure_disk_cmk_key_vault_key_id     = "https://<key-vault-name>.vault.azure.net/keys/<key-name>"
```
Azure Key Vault becomes a hard dependency of the cluster. If the key is deleted or disabled, or if the identity loses
access to the key, the data in the Storage Account becomes inaccessible and the nodes fail to start. Enabling the keys
on the disks of a running cluster deallocates and restarts the nodes, which took about six minutes for a single node.
Apply it during a maintenance window. Enabling the key on the Storage Account is done in place.

### Encryption at Host
Set `azure_enable_encryption_at_host` to `true` to also encrypt the host cache of the disks and the data flowing to
Azure Storage. The `Microsoft.Compute/EncryptionAtHost` feature must be registered on the Azure subscription, and the
VM size in `azure_cces_vm_size` must support it:
```text
az feature register --namespace Microsoft.Compute --name EncryptionAtHost
az provider register --namespace Microsoft.Compute
```
Enabling it on a running cluster deallocates and restarts the nodes. Apply it during a maintenance window.

### Boot Diagnostics and VM Extensions
Set `azure_enable_boot_diagnostics` to `true` to enable boot diagnostics using a Microsoft managed storage account.
CDM manages its own operating system, so the module installs no VM extensions. Set `azure_allow_extension_operations`
to `false` to also block the installation of extensions on the nodes. Only do this if no extensions, such as
monitoring or security agents, are required on the nodes. Both settings are applied in place without restarting the
nodes.

### Storage Account Logs
Set one or more of `azure_sa_logs_log_analytics_workspace_id`, `azure_sa_logs_storage_account_id` and
`azure_sa_logs_eventhub_authorization_rule_id` to send the read, write and delete logs of the blob, queue, table and
file services of the Storage Account to that destination. Use `azure_sa_logs_eventhub_name` to select the Event Hub.
Do not send the logs to the CCES Storage Account itself, since the log volume of a backup workload is high.

### Settings That CCES Doesn't Support
Some findings of Azure security scanners can't be addressed, since the setting isn't supported by CCES. Rubrik documents
the Storage Account requirements in
[Storage settings required by Rubrik Cloud Cluster ES on Azure](https://docs.rubrik.com/en-us/saas/common/azure_storage_settings.html)
and [Prerequisites for Rubrik Cloud Cluster ES on Azure](https://docs.rubrik.com/en-us/saas/common/azr_cc_es_prereq.html).
* **Storage Account shared key access** must stay enabled. The required storage settings list "Enable storage account
  key access" as "Enabled", and the bootstrap of the cluster authenticates with the Storage Account connection string.
* **Blob soft delete** must stay disabled. The prerequisites list "Blob soft delete disabled", since immutable storage
  manages retention at the version level and soft delete might interfere with immutability.
* **Infrastructure encryption** must stay disabled. The required storage settings list "Enable infrastructure
  encryption" as "Not enabled". It can also only be set when the Storage Account is created.
* **A locked immutability policy** on the Storage Account or the container isn't used. The prerequisites state that the
  container must not have any attached retention policies, and the required storage settings state that no access
  policies may be associated with the container. CDM manages the immutability locks of the backups itself, see
  [Immutable storage in Cloud Cluster ES](https://docs.rubrik.com/en-us/saas/common/cces_immutable_storage.html).
* **vTPM, Secure Boot, Trusted Launch and Confidential VM** are not supported by CCES.
* **Periodic assessment of missing system updates** isn't supported by Azure for the CCES image, Azure rejects it with
  the message "The selected VM image is not supported for VM Guest patch operations". CDM is updated through CDM
  upgrades.
* **Azure Disk Encryption** is not used, Rubrik doesn't document it as supported on Cloud Cluster ES nodes. Use
  customer-managed keys and encryption at host instead.

## Additional Documentation
* [Microsoft Azure CLI Installation](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Microsoft Azure CLI Authentication](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
* [Terraform Module Registry](https://registry.terraform.io/modules/rubrikinc/rubrik-azure-cloud-cluster-elastic-storage)
* [Terraform Module for AzureRM CLI Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >=2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=4.14.0, <5.0.0 |
| <a name="requirement_polaris"></a> [polaris](#requirement\_polaris) | >=1.1.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | >=2.0.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=4.14.0, <5.0.0 |
| <a name="provider_polaris"></a> [polaris](#provider\_polaris) | >=1.1.3 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.cc_container](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_update_resource.cces_subnet_storage_endpoint](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) | resource |
| [azurerm_disk_encryption_set.cces](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/disk_encryption_set) | resource |
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
| [azurerm_monitor_diagnostic_setting.cc_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_network_interface.cces_nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_resource_group.cc_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_ssh_public_key.cc_public_ssh_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ssh_public_key) | resource |
| [azurerm_storage_account.cc_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account_network_rules.cc_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_network_rules) | resource |
| [azurerm_virtual_machine_data_disk_attachment.cces_cache_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_data_disk_attachment.cces_data_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_data_disk_attachment.cces_metadata_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [polaris_cdm_bootstrap_cces_azure.bootstrap_cces_azure](https://registry.terraform.io/providers/rubrikinc/polaris/latest/docs/resources/cdm_bootstrap_cces_azure) | resource |
| [polaris_cdm_registration.cces_azure_registration](https://registry.terraform.io/providers/rubrikinc/polaris/latest/docs/resources/cdm_registration) | resource |
| [time_sleep.wait_for_nodes_to_boot](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_nodes_to_provision](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_private_key.cc-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_subnet.cces_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_email"></a> [admin\_email](#input\_admin\_email) | The Rubrik Cloud Cluster sends messages for the admin account to this email address. | `string` | n/a | yes |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Password for the Rubrik Cloud Cluster admin account. | `string` | `"ChangeMe"` | no |
| <a name="input_azure_allow_extension_operations"></a> [azure\_allow\_extension\_operations](#input\_azure\_allow\_extension\_operations) | Whether virtual machine extensions can be installed on the Rubrik Cloud Cluster nodes. CDM manages its own operating system, so the module installs no extensions. Set to `false` to block extension operations on the nodes. Do this only if no extensions, such as monitoring or security agents, are required on the nodes. Defaults to `true` to not change the behavior of existing deployments. | `bool` | `true` | no |
| <a name="input_azure_cces_plan_name"></a> [azure\_cces\_plan\_name](#input\_azure\_cces\_plan\_name) | The Azure Marketplace Plan Name/ID of the CCES image to deploy. See the README.MD file of this module for information on finding the plan name. | `any` | n/a | yes |
| <a name="input_azure_cces_sku"></a> [azure\_cces\_sku](#input\_azure\_cces\_sku) | The SKU for the Azure Marketplace Image of CCES to deploy. See the README.MD file of this module for information on finding the SKU. | `string` | n/a | yes |
| <a name="input_azure_cces_version"></a> [azure\_cces\_version](#input\_azure\_cces\_version) | The version of CCES to deploy. Use 'latest' to deploy the latest available version. Note: This only applies to the version within a SKU (major/minor version). | `string` | `"latest"` | no |
| <a name="input_azure_cces_vm_size"></a> [azure\_cces\_vm\_size](#input\_azure\_cces\_vm\_size) | The Azure VM Machine Type to use for the Cloud Cluster nodes. | `string` | `"Standard_D16s_v5"` | no |
| <a name="input_azure_cmk_user_assigned_identity_id"></a> [azure\_cmk\_user\_assigned\_identity\_id](#input\_azure\_cmk\_user\_assigned\_identity\_id) | The ID of a user-assigned managed identity that Azure uses to access the Key Vault keys in `azure_sa_cmk_key_vault_key_id` and `azure_disk_cmk_key_vault_key_id`. The identity must be granted the `Get`, `Wrap Key` and `Unwrap Key` key permissions, or the `Key Vault Crypto Service Encryption User` role, on the keys before applying the module. The module doesn't create the identity, the key vault or the keys, as the key ownership is a customer decision. | `string` | `null` | no |
| <a name="input_azure_disk_cmk_key_vault_key_id"></a> [azure\_disk\_cmk\_key\_vault\_key\_id](#input\_azure\_disk\_cmk\_key\_vault\_key\_id) | The ID of the Azure Key Vault key used to encrypt the Rubrik Cloud Cluster disks, including the OS disks, with a customer-managed key. The module creates a disk encryption set for the key, which double encrypts the disks with both a platform-managed key and the customer-managed key. Use a key ID without a version to have Azure automatically use the latest key version. Requires `azure_cmk_user_assigned_identity_id`. The key vault must have soft delete and purge protection enabled. Azure Key Vault becomes a hard dependency of the nodes, if the key is deleted or disabled, or if the identity loses access to the key, the nodes fail to start and the disks become inaccessible. Changing this on a running cluster deallocates and restarts the nodes, so apply it during a maintenance window. When not set, the disks are encrypted with a platform-managed key. | `string` | `null` | no |
| <a name="input_azure_enable_boot_diagnostics"></a> [azure\_enable\_boot\_diagnostics](#input\_azure\_enable\_boot\_diagnostics) | Enable boot diagnostics, using a Microsoft managed storage account, on the Rubrik Cloud Cluster nodes. Defaults to `false` to not change the behavior of existing deployments. | `bool` | `false` | no |
| <a name="input_azure_enable_encryption_at_host"></a> [azure\_enable\_encryption\_at\_host](#input\_azure\_enable\_encryption\_at\_host) | Enable encryption at host on the Rubrik Cloud Cluster nodes, which encrypts the host cache of the disks and the data flowing to Azure Storage. The `Microsoft.Compute/EncryptionAtHost` feature must be registered on the Azure subscription, and `azure_cces_vm_size` must support encryption at host. Changing this on a running cluster deallocates and restarts the nodes, so apply it during a maintenance window. Defaults to `false` to not change the behavior of existing deployments. | `bool` | `false` | no |
| <a name="input_azure_enable_subnet_storage_endpoint"></a> [azure\_enable\_subnet\_storage\_endpoint](#input\_azure\_enable\_subnet\_storage\_endpoint) | Whether to enable the Storage service endpoint on the VPC subnet. Defaults to `true`. | `bool` | `true` | no |
| <a name="input_azure_key_vault_name"></a> [azure\_key\_vault\_name](#input\_azure\_key\_vault\_name) | The name of the Azure Key Vault to create, into which the CCES private ssh key will be stored. | `string` | `""` | no |
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | The region to deploy Rubrik Cloud Cluster resources. | `any` | n/a | yes |
| <a name="input_azure_metadata_disk_caching"></a> [azure\_metadata\_disk\_caching](#input\_azure\_metadata\_disk\_caching) | Host caching mode for the Rubrik Cloud Cluster metadata disk. CDM 9.3.3 and later require 'None'. The metadata disk exists on CDM 9.2.2 and later. Changing this on a running cluster detaches and reattaches the disk, so apply it during a maintenance window. | `string` | `"None"` | no |
| <a name="input_azure_os_disk_caching"></a> [azure\_os\_disk\_caching](#input\_azure\_os\_disk\_caching) | Host caching mode for the Rubrik Cloud Cluster OS disk. Can be 'None', 'ReadOnly' or 'ReadWrite'. When not set, it defaults to 'None' on CDM 9.2.2 and later, following the Rubrik host caching recommendation, and to 'ReadWrite' on earlier versions, which leaves those deployments unchanged. Changing this on a running cluster restarts the nodes, so on an upgrade either apply it during a maintenance window or set it to 'ReadWrite' to keep the current behaviour. | `string` | `null` | no |
| <a name="input_azure_resource_group"></a> [azure\_resource\_group](#input\_azure\_resource\_group) | The Azure Resource Group into which deploy Rubrik Cloud Cluster resources. | `string` | `"RubrikCloudCluster"` | no |
| <a name="input_azure_resource_lock"></a> [azure\_resource\_lock](#input\_azure\_resource\_lock) | Enable the Azure Resource Lock on critical components that are created by this module. | `bool` | `true` | no |
| <a name="input_azure_sa_allowed_ip_ranges"></a> [azure\_sa\_allowed\_ip\_ranges](#input\_azure\_sa\_allowed\_ip\_ranges) | Public IP addresses or CIDR ranges that are allowed to access the Azure Storage Account when `azure_sa_restrict_network_access` is `true`. Use it to allow the hosts that manage the Storage Account, for example the Terraform runner, when they are outside of the CCES subnet. Private IP ranges and `/31` and `/32` ranges are not supported by Azure, use single IP addresses instead of `/31` and `/32` ranges. | `list(string)` | `[]` | no |
| <a name="input_azure_sa_cmk_key_vault_key_id"></a> [azure\_sa\_cmk\_key\_vault\_key\_id](#input\_azure\_sa\_cmk\_key\_vault\_key\_id) | The ID of the Azure Key Vault key used to encrypt the Azure Storage Account with a customer-managed key. Use a key ID without a version to have Azure automatically use the latest key version. Requires `azure_cmk_user_assigned_identity_id`. The key vault must have soft delete and purge protection enabled. Azure Key Vault becomes a hard dependency of the Storage Account, if the key is deleted or disabled, or if the identity loses access to the key, the cluster data becomes inaccessible. When not set, the Storage Account is encrypted with a Microsoft-managed key. | `string` | `null` | no |
| <a name="input_azure_sa_container_soft_delete_days"></a> [azure\_sa\_container\_soft\_delete\_days](#input\_azure\_sa\_container\_soft\_delete\_days) | The number of days a deleted container is retained in the Azure Storage Account before it is permanently deleted. | `number` | `7` | no |
| <a name="input_azure_sa_logs_eventhub_authorization_rule_id"></a> [azure\_sa\_logs\_eventhub\_authorization\_rule\_id](#input\_azure\_sa\_logs\_eventhub\_authorization\_rule\_id) | The ID of an Event Hub authorization rule to send the read, write and delete logs of the Azure Storage Account blob, queue, table and file services to. | `string` | `null` | no |
| <a name="input_azure_sa_logs_eventhub_name"></a> [azure\_sa\_logs\_eventhub\_name](#input\_azure\_sa\_logs\_eventhub\_name) | The name of the Event Hub to send the logs to, requires `azure_sa_logs_eventhub_authorization_rule_id`. When not set, the default Event Hub of the namespace is used. | `string` | `null` | no |
| <a name="input_azure_sa_logs_log_analytics_workspace_id"></a> [azure\_sa\_logs\_log\_analytics\_workspace\_id](#input\_azure\_sa\_logs\_log\_analytics\_workspace\_id) | The ID of a Log Analytics workspace to send the read, write and delete logs of the Azure Storage Account blob, queue, table and file services to. Do not send the logs to the CCES Storage Account itself, the log volume of a backup workload is high. | `string` | `null` | no |
| <a name="input_azure_sa_logs_storage_account_id"></a> [azure\_sa\_logs\_storage\_account\_id](#input\_azure\_sa\_logs\_storage\_account\_id) | The ID of a Storage Account to send the read, write and delete logs of the Azure Storage Account blob, queue, table and file services to. Do not use the CCES Storage Account, the log volume of a backup workload is high. | `string` | `null` | no |
| <a name="input_azure_sa_name"></a> [azure\_sa\_name](#input\_azure\_sa\_name) | The name of the Azure Storage Account to create for Rubrik Cloud Cluster resources. | `string` | n/a | yes |
| <a name="input_azure_sa_replication_type"></a> [azure\_sa\_replication\_type](#input\_azure\_sa\_replication\_type) | The type of replication to use with the the Azure Storage Account for Rubrik Cloud Cluster. Defaults to `LRS` to avoid doubling the storage cost. Use `GRS` or `GZRS` to enable geo-redundant storage. | `string` | `"LRS"` | no |
| <a name="input_azure_sa_restrict_network_access"></a> [azure\_sa\_restrict\_network\_access](#input\_azure\_sa\_restrict\_network\_access) | Restrict network access to the Azure Storage Account. When `true`, the default action of the network rules is `Deny` and only the CCES subnet, the IP ranges in `azure_sa_allowed_ip_ranges` and trusted Azure services are allowed access. Clients outside of the CCES subnet are denied access unless their IP address is allowed. The CCES subnet must have the `Microsoft.Storage` service endpoint, see `azure_enable_subnet_storage_endpoint`. Defaults to `false` to not change the behavior of existing deployments. | `bool` | `false` | no |
| <a name="input_azure_sa_sas_expiration_period"></a> [azure\_sa\_sas\_expiration\_period](#input\_azure\_sa\_sas\_expiration\_period) | The maximum validity of a shared access signature (SAS) for the Azure Storage Account, in the format `DD.HH:MM:SS`. The module doesn't create any SAS tokens, and the policy only logs SAS tokens that are valid for longer than this. | `string` | `"7.00:00:00"` | no |
| <a name="input_azure_subnet_name"></a> [azure\_subnet\_name](#input\_azure\_subnet\_name) | Name of the Azure subnet to deploy Rubrik Cloud Cluster into. This subnet must be in the VNet that is defined in the 'azure\_vnet\_name' variable. | `string` | n/a | yes |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | Subscription ID of the Azure account to deploy Rubrik Cloud Cluster resources. Deprecated: This variable is no longer required as the subscription ID is now determined by the provider configuration. | `string` | `null` | no |
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
| <a name="input_register_cluster_with_rsc"></a> [register\_cluster\_with\_rsc](#input\_register\_cluster\_with\_rsc) | Register the Rubrik Cloud Cluster with Rubrik Security Cloud. | `bool` | `false` | no |
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
