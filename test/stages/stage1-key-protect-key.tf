module "key_protect_key" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-kms-key.git"

  kms_id = module.key_protect.guid
  name = var.kms_key_name
  provision = true
}
