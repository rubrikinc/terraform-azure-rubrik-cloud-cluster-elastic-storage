## Changelog

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
