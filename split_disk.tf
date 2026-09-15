locals {
  # Regular expressions parsing the CCES SKU and version. Note, version can be
  # either a version number or latest.
  sku_regex     = "^rubrik-cdm-(\\d+)$"
  version_regex = "^(\\d+).(\\d+).(\\d+)$|^(latest)$"

  # Extract the major, minor and maintenance version numbers from the CCES SKU
  # and version strings.
  major_minor_version = parseint(regex(local.sku_regex, var.azure_cces_sku)[0], 10)
  maint_patch_build   = regex(local.version_regex, var.azure_cces_version)
  maint_version       = local.maint_patch_build[0] == null ? 0 : parseint(local.maint_patch_build[0], 10)

  # Determine if the split disk feature is enabled based on the major, minor and
  # maintenance version numbers.
  split_disk = local.major_minor_version > 92 || (local.major_minor_version == 92 && (var.azure_cces_version == "latest" || local.maint_version >= 2)) ? true : false

  # Versions with the split disk feature follow the Rubrik host caching
  # recommendation of None for the OS disk. Earlier versions keep ReadWrite, so
  # that upgrading the module doesn't restart the nodes of those deployments.
  os_disk_caching = var.azure_os_disk_caching != null ? var.azure_os_disk_caching : (local.split_disk ? "None" : "ReadWrite")
}
