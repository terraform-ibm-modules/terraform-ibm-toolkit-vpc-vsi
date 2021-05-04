module "hpcs_key" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-kms-key.git"

  region = module.hpcs.location
  ibmcloud_api_key = var.ibmcloud_api_key
  provision = false
  kms_id = module.hpcs.guid
  name = var.kms_key_name
}
