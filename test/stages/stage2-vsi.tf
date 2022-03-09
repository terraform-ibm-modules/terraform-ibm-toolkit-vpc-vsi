module "vsi" {
  source = "./module"

  resource_group_id = module.resource_group.id
  region            = var.region
  ibmcloud_api_key  = var.ibmcloud_api_key
  vpc_name          = module.vpc.name
  vpc_subnet_count  = module.subnets.count
  vpc_subnets       = module.subnets.subnets
  ssh_key_id        = module.vpcssh.id
  kms_key_crn       = module.key_protect_key.crn
  kms_enabled       = var.kms_enabled
  allow_deprecated_image = false
  base_security_group = module.vpc.base_security_group
  security_group_rules = [
    {
      name      = "private-network"
      direction = "outbound"
      remote    = "10.0.0.0/8"
    },
    {
      name      = "service-endpoints"
      direction = "outbound"
      remote    = "161.26.0.0/16"
    },
    {
      name      = "iaas-endpoints"
      direction = "outbound"
      remote    = "166.8.0.0/14"
    },
    {
      name      = "outbound-http"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name      = "outbound-https"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name      = "outbound-dns"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      udp = {
        port_min = 53
        port_max = 53
      }
    }
  ]
  acl_rules = [{
    name = "allow-all-ingress"
    action = "allow"
    direction = "inbound"
    source = "0.0.0.0/0"
    destination = "0.0.0.0/0"
  }, {
    name = "allow-all-egress"
    action = "allow"
    direction = "outbound"
    source = "0.0.0.0/0"
    destination = "0.0.0.0/0"
  }]
}
