module "key_protect" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-key-protect"

  resource_group_name      = module.resource_group.name
  region                   = var.region
  name_prefix              = var.name_prefix
  provision                = true
}
