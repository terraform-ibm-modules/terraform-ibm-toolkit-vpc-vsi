
locals {
  name        = "${replace(var.vpc_name, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${var.label}"
  tags        = tolist(setunion(var.tags, [var.label]))
}

resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_id}'"
  }
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
}

data "ibm_is_image" "image" {
  name = var.image_name
}

data ibm_is_vpc vpc {
  depends_on = [null_resource.print_names]

  name  = var.vpc_name
}

resource ibm_is_security_group vsi {
  name           = "${local.name}-group"
  vpc            = data.ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id
}

resource ibm_is_security_group_rule ssh_inbound {
  count = var.allow_ssh_from != "" ? 1 : 0

  group     = ibm_is_security_group.vsi.id
  direction = "inbound"
  remote    = var.allow_ssh_from
  tcp {
    port_min = 22
    port_max = 22
  }
}

data ibm_kms_key root_key {
  count = var.kms_enabled ? 1 : 0

  instance_id = var.kms_id
  key_name    = var.kms_key_name
}

resource null_resource print_key_crn {
  count = var.kms_enabled ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Key crn: ${data.ibm_kms_key.root_key[0].keys[0].crn}'"
  }
}

resource ibm_is_instance vsi {
  depends_on = [null_resource.print_key_crn]
  count = var.vpc_subnet_count

  name           = "${local.name}${format("%02s", count.index)}"
  vpc            = data.ibm_is_vpc.vpc.id
  zone           = var.vpc_subnets[count.index].zone
  profile        = var.profile_name
  image          = data.ibm_is_image.image.id
  keys           = var.ssh_key_ids
  resource_group = var.resource_group_id
  auto_delete_volume = var.auto_delete_volume

  user_data = var.init_script != "" ? var.init_script : file("${path.module}/scripts/init-script-ubuntu.sh")

  primary_network_interface {
    subnet          = var.vpc_subnets[count.index].id
    security_groups = [ibm_is_security_group.vsi.id]
  }

  boot_volume {
    name       = "${local.name}${format("%02s", count.index)}-boot"
//    encryption = var.kms_enabled ? data.ibm_kms_key.root_key[0].keys[0].crn : null
  }

  tags = var.tags
}

resource ibm_is_floating_ip vsi {
  count = var.create_public_ip ? var.vpc_subnet_count : 0

  name           = "${local.name}${format("%02s", count.index)}-ip"
  target         = ibm_is_instance.vsi[count.index].primary_network_interface[0].id
  resource_group = var.resource_group_id

  tags = var.tags
}

resource ibm_is_security_group_rule ssh_to_self_public_ip {
  count = var.create_public_ip ? var.vpc_subnet_count : 0

  group     = ibm_is_security_group.vsi.id
  direction = "outbound"
  remote    = ibm_is_floating_ip.vsi[count.index].address
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource ibm_is_flow_log flowlog_instance {
  count = var.flow_log_cos_bucket_name != "" ? var.vpc_subnet_count : 0
  depends_on = [ibm_is_floating_ip.vsi]

  name = "${local.name}${format("%02s", count.index)}-flowlog"
  active = true
  target = ibm_is_instance.vsi[count.index].id
  resource_group = var.resource_group_id
  storage_bucket = var.flow_log_cos_bucket_name
}
