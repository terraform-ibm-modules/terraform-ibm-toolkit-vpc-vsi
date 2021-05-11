
locals {
  name        = "${replace(var.vpc_name, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${var.label}"
  tags        = tolist(setunion(var.tags, [var.label]))
}

resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
}

data ibm_is_image image {
  name = var.image_name
}

resource null_resource print_deprecated {
  provisioner "local-exec" {
    command = "${path.module}/scripts/check-image.sh '${data.ibm_is_image.image.status}' '${data.ibm_is_image.image.name}' '${var.allow_deprecated_image}'"
  }
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

resource ibm_is_security_group_rule additional_rules {
  count = length(var.security_group_rules)

  group      = ibm_is_security_group.vsi.id
  direction  = var.security_group_rules[count.index]["direction"]
  remote     = lookup(var.security_group_rules[count.index], "remote", null)
  ip_version = lookup(var.security_group_rules[count.index], "ip_version", null)

  dynamic "tcp" {
    for_each = lookup(var.security_group_rules[count.index], "tcp", null) != null ? [ lookup(var.security_group_rules[count.index], "tcp", null) ] : []

    content {
      port_min = tcp.value["port_min"]
      port_max = tcp.value["port_max"]
    }
  }

  dynamic "udp" {
    for_each = lookup(var.security_group_rules[count.index], "udp", null) != null ? [ lookup(var.security_group_rules[count.index], "udp", null) ] : []

    content {
      port_min = udp.value["port_min"]
      port_max = udp.value["port_max"]
    }
  }

  dynamic "icmp" {
    for_each = lookup(var.security_group_rules[count.index], "icmp", null) != null ? [ lookup(var.security_group_rules[count.index], "icmp", null) ] : []

    content {
      type = icmp.value["type"]
      code = lookup(icmp.value, "code", null)
    }
  }
}

resource null_resource print_key_crn {
  count = var.kms_enabled ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Key crn: ${var.kms_key_crn}'"
  }
}

resource ibm_is_instance vsi {
  depends_on = [null_resource.print_key_crn, null_resource.print_deprecated]
  count = var.vpc_subnet_count

  name           = "${local.name}${format("%02s", count.index)}"
  vpc            = data.ibm_is_vpc.vpc.id
  zone           = var.vpc_subnets[count.index].zone
  profile        = var.profile_name
  image          = data.ibm_is_image.image.id
  keys           = tolist(setsubtract([var.ssh_key_id], [""]))
  resource_group = var.resource_group_id
  auto_delete_volume = var.auto_delete_volume

  user_data = var.init_script != "" ? var.init_script : file("${path.module}/scripts/init-script-ubuntu.sh")

  primary_network_interface {
    subnet          = var.vpc_subnets[count.index].id
    security_groups = [data.ibm_is_vpc.vpc.default_security_group, ibm_is_security_group.vsi.id]
  }

  boot_volume {
    name       = "${local.name}${format("%02s", count.index)}-boot"
    encryption = var.kms_enabled ? var.kms_key_crn : null
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
