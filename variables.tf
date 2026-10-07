# General Variables

variable "azure_location" {
  description = "The region to deploy Rubrik Cloud Cluster resources."
}

variable "azure_resource_group" {
  description = "The Azure Resource Group into which deploy Rubrik Cloud Cluster resources."
  type        = string
  default     = "RubrikCloudCluster"
}

variable "azure_resource_lock" {
  description = "Enable the Azure Resource Lock on critical components that are created by this module."
  type        = bool
  default     = true
}

variable "azure_subscription_id" {
  description = "Subscription ID of the Azure account to deploy Rubrik Cloud Cluster resources. Deprecated: This variable is no longer required as the subscription ID is now determined by the provider configuration."
  type        = string
  default     = null

  validation {
    condition     = var.azure_subscription_id == null ? true : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.azure_subscription_id))
    error_message = "The subscription ID must be a valid UUID format if provided."
  }
}

variable "azure_tags" {
  description = "Tags to add to the Azure resources that this Terraform script creates, including the Rubrik cluster nodes."
  type        = map(string)
  default     = {}
}

# Cloud Cluster Node Information

variable "azure_allow_extension_operations" {
  description = "Whether virtual machine extensions can be installed on the Rubrik Cloud Cluster nodes. CDM manages its own operating system, so the module installs no extensions. Set to `false` to block extension operations on the nodes. Do this only if no extensions, such as monitoring or security agents, are required on the nodes. Defaults to `true` to not change the behavior of existing deployments."
  type        = bool
  default     = true
}

variable "azure_cces_plan_name" {
  description = "The Azure Marketplace Plan Name/ID of the CCES image to deploy. See the README.MD file of this module for information on finding the plan name."
}

variable "azure_cces_sku" {
  description = "The SKU for the Azure Marketplace Image of CCES to deploy. See the README.MD file of this module for information on finding the SKU."
  type        = string

  validation {
    condition     = can(regex("^rubrik-cdm-(\\d+)$", var.azure_cces_sku))
    error_message = "The SKU must be in the format 'rubrik-cdm-<version>'. For example, 'rubrik-cdm-92'."
  }
}

variable "azure_cces_version" {
  description = "The version of CCES to deploy. Use 'latest' to deploy the latest available version. Note: This only applies to the version within a SKU (major/minor version)."
  type        = string
  default     = "latest"

  validation {
    condition     = can(regex("^(\\d+).(\\d+).(\\d+)$|^(latest)$", var.azure_cces_version))
    error_message = "The version must be in the format '<minor>.<maintenance>.<build>' for CDM version 8.1 and later or '<major>.<minor>.<maintenance>' for CDM 8.0 and earlier. For example, '2.1.29213'."
  }
}

variable "azure_cces_vm_size" {
  description = "The Azure VM Machine Type to use for the Cloud Cluster nodes."
  type        = string
  default     = "Standard_D16s_v5"
}

variable "azure_enable_boot_diagnostics" {
  description = "Enable boot diagnostics, using a Microsoft managed storage account, on the Rubrik Cloud Cluster nodes. Defaults to `false` to not change the behavior of existing deployments."
  type        = bool
  default     = false
}

variable "azure_enable_encryption_at_host" {
  description = "Enable encryption at host on the Rubrik Cloud Cluster nodes, which encrypts the host cache of the disks and the data flowing to Azure Storage. The `Microsoft.Compute/EncryptionAtHost` feature must be registered on the Azure subscription, and `azure_cces_vm_size` must support encryption at host. Changing this on a running cluster deallocates and restarts the nodes, so apply it during a maintenance window. Defaults to `false` to not change the behavior of existing deployments."
  type        = bool
  default     = false
}

variable "azure_key_vault_name" {
  description = "The name of the Azure Key Vault to create, into which the CCES private ssh key will be stored."
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Unique name to assign to the Rubrik Cloud Cluster. This will also be used as part of the Storage Account name. For example, rubrik-cloud-cluster-1, rubrik-cloud-cluster-2 etc."
  type        = string
  default     = "rubrik-cloud-cluster"
}

variable "number_of_nodes" {
  description = "The total number of nodes in Rubrik Cloud Cluster."
  type        = number
  default     = 3
}

# Networking

variable "azure_subnet_name" {
  description = "Name of the Azure subnet to deploy Rubrik Cloud Cluster into. This subnet must be in the VNet that is defined in the 'azure_vnet_name' variable."
  type        = string
}

variable "azure_vnet_name" {
  description = "Name of the Azure Virtual Network (VNet) to deploy Rubrik Cloud Cluster ES into."
  type        = string
}

variable "azure_vnet_rg_name" {
  description = "Name of the Resource Group of the Azure VNet that is defined in the 'azure_vnet_name' variable."
  type        = string
}

# Storage Variables

variable "azure_cmk_user_assigned_identity_id" {
  description = "The ID of a user-assigned managed identity that Azure uses to access the Key Vault keys in `azure_sa_cmk_key_vault_key_id` and `azure_disk_cmk_key_vault_key_id`. The identity must be granted the `Get`, `Wrap Key` and `Unwrap Key` key permissions, or the `Key Vault Crypto Service Encryption User` role, on the keys before applying the module. The module doesn't create the identity, the key vault or the keys, as the key ownership is a customer decision."
  type        = string
  default     = null
}

variable "azure_disk_cmk_key_vault_key_id" {
  description = "The ID of the Azure Key Vault key used to encrypt the Rubrik Cloud Cluster disks, including the OS disks, with a customer-managed key. The module creates a disk encryption set for the key, which double encrypts the disks with both a platform-managed key and the customer-managed key. Use a key ID without a version to have Azure automatically use the latest key version. Requires `azure_cmk_user_assigned_identity_id`. The key vault must have soft delete and purge protection enabled. Azure Key Vault becomes a hard dependency of the nodes, if the key is deleted or disabled, or if the identity loses access to the key, the nodes fail to start and the disks become inaccessible. Changing this on a running cluster deallocates and restarts the nodes, so apply it during a maintenance window. When not set, the disks are encrypted with a platform-managed key."
  type        = string
  default     = null
}

variable "azure_disk_restrict_network_access" {
  description = "Restrict network access to the managed disks of the Rubrik Cloud Cluster nodes. When `true`, the network access policy of the disks is `DenyAll` and public network access is disabled, which blocks exporting a disk through a SAS URL. It can also affect services that read the disks through a SAS URL, such as backup, disaster recovery and security scanning tools. Defaults to `false` to not change the behavior of existing deployments."
  type        = bool
  default     = false
}

variable "azure_enable_subnet_storage_endpoint" {
  description = "Whether to enable the Storage service endpoint on the VPC subnet. Defaults to `true`."
  type        = bool
  default     = true
}

variable "azure_metadata_disk_caching" {
  description = "Host caching mode for the Rubrik Cloud Cluster metadata disk. CDM 9.3.3 and later require 'None'. The metadata disk exists on CDM 9.2.2 and later. Changing this on a running cluster detaches and reattaches the disk, so apply it during a maintenance window."
  type        = string
  default     = "None"

  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.azure_metadata_disk_caching)
    error_message = "The host caching mode must be one of 'None', 'ReadOnly' or 'ReadWrite'."
  }
}

variable "azure_os_disk_caching" {
  description = "Host caching mode for the Rubrik Cloud Cluster OS disk. Can be 'None', 'ReadOnly' or 'ReadWrite'. When not set, it defaults to 'None' on CDM 9.2.2 and later, following the Rubrik host caching recommendation, and to 'ReadWrite' on earlier versions, which leaves those deployments unchanged. Changing this on a running cluster restarts the nodes, so on an upgrade either apply it during a maintenance window or set it to 'ReadWrite' to keep the current behaviour."
  type        = string
  default     = null

  validation {
    condition     = var.azure_os_disk_caching == null ? true : contains(["None", "ReadOnly", "ReadWrite"], var.azure_os_disk_caching)
    error_message = "The host caching mode must be one of 'None', 'ReadOnly' or 'ReadWrite'."
  }
}

variable "azure_sa_allowed_ip_ranges" {
  description = "Public IPv4 addresses or CIDR ranges that are allowed to access the Azure Storage Account when `azure_sa_restrict_network_access` is `true`. Use it to allow the hosts that manage the Storage Account, for example the Terraform runner, when they are outside of the CCES subnet. Azure doesn't support private IP ranges, or `/31` and `/32` ranges, use single IP addresses instead of `/31` and `/32` ranges."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for r in var.azure_sa_allowed_ip_ranges : can(cidrnetmask(length(split("/", r)) == 2 ? r : "${r}/32"))])
    error_message = "Each IP range must be an IPv4 address or an IPv4 CIDR range."
  }

  validation {
    condition     = alltrue([for r in var.azure_sa_allowed_ip_ranges : try(tonumber(split("/", r)[1]) <= 30, true)])
    error_message = "Azure doesn't support /31 and /32 IP ranges, use a single IP address instead."
  }

  validation {
    condition     = alltrue([for r in var.azure_sa_allowed_ip_ranges : !can(regex("^(10\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.|192\\.168\\.)", r))])
    error_message = "Azure doesn't support private IP ranges."
  }
}

variable "azure_sa_cmk_key_vault_key_id" {
  description = "The ID of the Azure Key Vault key used to encrypt the Azure Storage Account with a customer-managed key. Use a key ID without a version to have Azure automatically use the latest key version. Requires `azure_cmk_user_assigned_identity_id`. The key vault must have soft delete and purge protection enabled. Azure Key Vault becomes a hard dependency of the Storage Account, if the key is deleted or disabled, or if the identity loses access to the key, the cluster data becomes inaccessible. When not set, the Storage Account is encrypted with a Microsoft-managed key."
  type        = string
  default     = null
}

variable "azure_sa_container_soft_delete_days" {
  description = "The number of days a deleted container is retained in the Azure Storage Account, 1 to 365. Set to `0` to disable container soft delete. Rubrik requires blob soft delete to be disabled, which is not changed by this setting. Rubrik doesn't document container soft delete for CCES, so it is disabled by default."
  type        = number
  default     = 0

  validation {
    condition     = var.azure_sa_container_soft_delete_days >= 0 && var.azure_sa_container_soft_delete_days <= 365
    error_message = "The container soft delete retention must be 0, to disable it, or between 1 and 365 days."
  }
}

variable "azure_sa_logs_eventhub_authorization_rule_id" {
  description = "The ID of an Event Hub authorization rule to send the read, write and delete logs of the Azure Storage Account blob, queue, table and file services to."
  type        = string
  default     = null
}

variable "azure_sa_logs_eventhub_name" {
  description = "The name of the Event Hub to send the logs to, requires `azure_sa_logs_eventhub_authorization_rule_id`. When not set, the default Event Hub of the namespace is used."
  type        = string
  default     = null
}

variable "azure_sa_logs_log_analytics_workspace_id" {
  description = "The ID of a Log Analytics workspace to send the read, write and delete logs of the Azure Storage Account blob, queue, table and file services to. Do not send the logs to the CCES Storage Account itself, the log volume of a backup workload is high."
  type        = string
  default     = null
}

variable "azure_sa_logs_storage_account_id" {
  description = "The ID of a Storage Account to send the read, write and delete logs of the Azure Storage Account blob, queue, table and file services to. Do not use the CCES Storage Account, the log volume of a backup workload is high."
  type        = string
  default     = null
}

variable "azure_sa_name" {
  description = "The name of the Azure Storage Account to create for Rubrik Cloud Cluster resources."
  type        = string
}

variable "azure_sa_replication_type" {
  description = "The type of replication to use with the the Azure Storage Account for Rubrik Cloud Cluster. Defaults to `LRS` to avoid doubling the storage cost. Use `GRS` or `GZRS` to enable geo-redundant storage."
  type        = string
  default     = "LRS"
}

variable "azure_sa_restrict_network_access" {
  description = "Restrict network access to the Azure Storage Account. When `true`, the default action of the network rules is `Deny` and only the CCES subnet, the IP ranges in `azure_sa_allowed_ip_ranges` and trusted Azure services are allowed access. Clients outside of the CCES subnet are denied access unless their IP address is allowed. The CCES subnet must have the `Microsoft.Storage` service endpoint, see `azure_enable_subnet_storage_endpoint`. Defaults to `false` to not change the behavior of existing deployments."
  type        = bool
  default     = false
}

variable "azure_sa_sas_expiration_period" {
  description = "The maximum validity of a shared access signature (SAS) for the Azure Storage Account, in the format `DD.HH:MM:SS`. The module doesn't create any SAS tokens, and the policy only logs SAS tokens that are valid for longer than this."
  type        = string
  default     = "7.00:00:00"

  validation {
    condition     = can(regex("^\\d+\\.([01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d$", var.azure_sa_sas_expiration_period))
    error_message = "The SAS expiration period must be in the format 'DD.HH:MM:SS'. For example, '7.00:00:00'."
  }
}

variable "enableImmutability" {
  description = "Enables object lock and versioning on the Storage Account and Container. Sets the object lock flag during bootstrap. Not supported on CDM v8.0.1 and earlier."
  type        = bool
  default     = true
}

# Bootstrap Information

variable "admin_email" {
  description = "The Rubrik Cloud Cluster sends messages for the admin account to this email address."
  type        = string
}

variable "admin_password" {
  description = "Password for the Rubrik Cloud Cluster admin account."
  type        = string
  sensitive   = true
  default     = "ChangeMe"
}

variable "dns_search_domain" {
  type        = list(any)
  description = "List of search domains that the DNS Service will use to resolve host names that are not fully qualified."
  default     = []
}

variable "dns_name_servers" {
  type        = list(any)
  description = "List of the IPv4 addresses of the DNS servers."
  default     = ["169.254.169.253"]
}

variable "ntp_server1_name" {
  description = "The FQDN or IPv4 addresses of network time protocol (NTP) server #1."
  type        = string
  default     = "8.8.8.8"
}

variable "ntp_server1_key_id" {
  description = "The ID number of the symmetric key used with NTP server #1. (Typically this is 0)"
  type        = number
  default     = 0
}

variable "ntp_server1_key" {
  description = "Symmetric key material for NTP server #1."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ntp_server1_key_type" {
  description = "Symmetric key type for NTP server #1."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ntp_server2_name" {
  description = "The FQDN or IPv4 addresses of network time protocol (NTP) server #2."
  type        = string
  default     = "8.8.4.4"
}

variable "ntp_server2_key_id" {
  description = "The ID number of the symmetric key used with NTP server #2. (Typically this is 0)"
  type        = number
  default     = 0
}

variable "ntp_server2_key" {
  description = "Symmetric key material for NTP server #2."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ntp_server2_key_type" {
  description = "Symmetric key type for NTP server #2."
  type        = string
  sensitive   = true
  default     = ""
}

variable "register_cluster_with_rsc" {
  description = "Register the Rubrik Cloud Cluster with Rubrik Security Cloud."
  type        = bool
  default     = false
}

variable "timeout" {
  description = "The number of seconds to wait to establish a connection the Rubrik cluster before returning a timeout error."
  type        = string
  default     = "4m"
}

check "deprecations" {
  assert {
    condition     = var.azure_subscription_id == null
    error_message = "The 'azure_subscription_id' variable is deprecated and should not be used as it will be removed in a future release. Configure the subscription ID in the azurerm provider configuration instead."
  }
}
