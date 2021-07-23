##############################################################################
# Local Variables
##############################################################################

locals {
  name                = "${replace(var.vpc_name, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${var.label}"
  tags                = tolist(setunion(var.tags, [var.label]))
}

##############################################################################


##############################################################################
# VPC Data
##############################################################################

data ibm_is_vpc vpc {
  depends_on = [null_resource.print_names]

  name  = var.vpc_name
}

data ibm_is_subnet vpc_subnets {
  count = length(var.vpc_subnets)

  identifier = var.vpc_subnets[count.index].id
}

##############################################################################


##############################################################################
# VSI Image
##############################################################################

data ibm_is_image image {
  name = var.image_name
}

##############################################################################


##############################################################################
# Add Additional ACL Rules
##############################################################################

resource null_resource update_acl_rules {
  count = length(var.acl_rules) > 0 || length(var.security_group_rules) > 0 ? length(var.vpc_subnets) : 0

  provisioner local-exec {
    command = "${path.module}/scripts/setup-acl-rules.sh '${data.ibm_is_subnet.vpc_subnets[count.index].network_acl}' '${var.region}' '${var.resource_group_id}'"

    environment = {
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
      ACL_RULES        = jsonencode(var.acl_rules)
      SG_RULES         = jsonencode(var.security_group_rules)
    }
  }
}

##############################################################################


##############################################################################
# SSH key for creating VSI
##############################################################################

resource ibm_is_ssh_key ssh_key {
  # Create if SSH key ID is not passed
  count      = var.ssh_key_id == "" ? 1 : 0
  name       = "${var.label}-ssh-key" 
  public_key = var.ssh_public_key
}

##############################################################################


##############################################################################
# Create list of VSI to be created
##############################################################################

locals {
  vsi_list = flatten([
    for subnet in var.vpc_subnets: [
      for count in range(0, var.vsi_per_subnet):
      {
        zone      = data.ibm_is_subnet.vpc_subnets[index(var.vpc_subnets, subnet)].zone
        subnet_id = data.ibm_is_subnet.vpc_subnets[index(var.vpc_subnets, subnet)].id
        name      = "${local.name}-${index(var.vpc_subnets, subnet) + count + 1}"
      }
    ]
  ])

  vsi_map = {
    for i in local.vsi_list:
    (i.name) => i
  }
  ssh_key_id = var.ssh_key_id == "" ? ibm_is_ssh_key.ssh_key[0].id : var.ssh_key_id
}

##############################################################################


##############################################################################
# Create VSI
##############################################################################

resource ibm_is_instance vsi {
  depends_on = [
    null_resource.print_key_crn, 
    null_resource.print_deprecated, 
    ibm_is_security_group_rule.additional_rules, 
    null_resource.update_acl_rules
  ]

  for_each           = local.vsi_map
  name               = each.key
  vpc                = data.ibm_is_vpc.vpc.id
  zone               = each.value.zone
  profile            = var.profile_name
  image              = data.ibm_is_image.image.id
  keys               = [
    local.ssh_key_id
  ]
  resource_group     = var.resource_group_id
  auto_delete_volume = var.auto_delete_volume

  user_data = var.init_script != "" ? var.init_script : file("${path.module}/scripts/init-script-ubuntu.sh")

  primary_network_interface {
    subnet          = each.value.subnet_id
    security_groups = [
      local.security_group_id
    ]
  }

  boot_volume {
    name       = "${each.key}-boot"
    encryption = var.kms_enabled ? var.kms_key_crn : null
  }

  tags = var.tags
}

##############################################################################


##############################################################################
# Optionally Create Floating IP
##############################################################################

resource ibm_is_floating_ip vsi {
  for_each        = var.enable_fip ? ibm_is_instance.vsi : {}

  name           = "${local.name}${each.key}-fip"
  target         = each.value.primary_network_interface.0.id
  resource_group = var.resource_group_id
  tags           = var.tags
}

##############################################################################