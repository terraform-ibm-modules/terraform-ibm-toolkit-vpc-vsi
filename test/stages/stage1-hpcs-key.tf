module "hpcs_key" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-kms-key.git"

  provision = false
  kms_id = module.hpcs.guid
  name = var.kms_key_name
}
