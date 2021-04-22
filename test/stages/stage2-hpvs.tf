module "dev_hpvs" {
  source = "./module"

  ibmcloud_api_key    = var.ibmcloud_api_key
  resource_group_name = module.resource_group.name
  resource_location   = "dal10"
  name_prefix         = var.name_prefix
  plan                = "entry"
  sshPublicKey        = module.vpcssh.public_key_pem
}
