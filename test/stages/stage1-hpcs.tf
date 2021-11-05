module "hpcs" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-hpcs.git"

  resource_group_name      = module.hpcs_resource_group.name
  region                   = var.hpcs_region
  name_prefix              = var.name_prefix
  name                     = var.hpcs_name
  provision                = false
  number_of_crypto_units   = 2
}
