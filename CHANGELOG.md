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
* The data disk and the cache disk are unchanged and keep `ReadWrite`. CDM before 9.3.3 requires `ReadWrite` on the data
  disk.
* Attach the data, metadata and cache disks to a cluster node one at a time, and wait for the nodes to be created before
  attaching the first disk. Attaching a disk updates the virtual machine, and two updates that overlap fail with a
  conflicting concurrent write error from Azure.
* Add the `azure_os_disk_caching` and `azure_metadata_disk_caching` module input variables, which override the host
  caching mode of the OS disk and the metadata disk.

This is released as a minor version, and not as a patch version, so that existing deployments using a `~> 1.0.0` version
constraint are not upgraded automatically. Applying the new host caching mode to an existing cluster is disruptive. See
the upgrade instructions in the README before upgrading.

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
