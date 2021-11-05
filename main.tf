
locals {
  name                = "${replace(var.vpc_name, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${var.label}"
  tags                = tolist(setunion(var.tags, [var.label]))
  base_security_group = var.base_security_group != null ? var.base_security_group : data.ibm_is_vpc.vpc.default_security_group
  ssh_security_group_rule = var.allow_ssh_from != "" ? [{
    name      = "ssh-inbound"
    direction = "inbound"
    remote    = var.allow_ssh_from
    tcp = {
      port_min = 22
      port_max = 22
    }
  }] : []
  internal_network_rules = [{
    name      = "services-outbound"
    direction = "outbound"
    remote    = "166.8.0.0/14"
  }, {
    name      = "adn-dns-outbound"
    direction = "outbound"
    remote    = "161.26.0.0/16"
    udp = {
      port_min = 53
      port_max = 53
    }
  }, {
    name      = "adn-http-outbound"
    direction = "outbound"
    remote    = "161.26.0.0/16"
    tcp = {
      port_min = 80
      port_max = 80
    }
  }, {
    name      = "adn-https-outbound"
    direction = "outbound"
    remote    = "161.26.0.0/16"
    tcp = {
      port_min = 443
      port_max = 443
    }
  }]
  security_group_rules = concat(local.ssh_security_group_rule, var.security_group_rules, local.internal_network_rules)
  forward_acl_rules_from_sg_rules = [for rule in var.security_group_rules: {
    action = "allow"
    name = "${rule.name}-sg"
    direction = rule.direction
    source = rule.direction == "inbound" ? rule.remote : var.target_network_range
    destination = rule.direction == "outbound" ? rule.remote : var.target_network_range
    tcp = lookup(rule, "tcp", null) != null ? {
      port_min = rule.tcp.port_min
      port_max = rule.tcp.port_max
      source_port_min = rule.tcp.port_min
      source_port_max = rule.tcp.port_max
    } : null
    udp = lookup(rule, "udp", null) != null ? {
      port_min = rule.udp.port_min
      port_max = rule.udp.port_max
      source_port_min = rule.udp.port_min
      source_port_max = rule.udp.port_max
    } : null
    icmp = lookup(rule, "icmp", null) != null ? {
      type = rule.icmp.type
      code = lookup(rule.icmp, "code", null)
    } : null
  }]
  reverse_acl_rules_from_sg_rules = [for rule in var.security_group_rules: {
    action = "allow"
    name = length(regexall(rule.direction, rule.name)) > 0 ? replace(rule.name, rule.direction, rule.direction == "inbound" ? "outbound-sg" : "inbound-sg") : "${rule.name}-${rule.direction == "inbound" ? "outbound" : "inbound"}-sg"
    direction = rule.direction == "inbound" ? "outbound" : "inbound"
    source = rule.direction == "outbound" ? rule.remote : var.target_network_range
    destination = rule.direction == "inbound" ? rule.remote : var.target_network_range
    tcp = lookup(rule, "tcp", null) != null ? {
      port_min = rule.tcp.port_min
      port_max = rule.tcp.port_max
      source_port_min = rule.tcp.port_min
      source_port_max = rule.tcp.port_max
    } : null
    udp = lookup(rule, "udp", null) != null ? {
      port_min = rule.udp.port_min
      port_max = rule.udp.port_max
      source_port_min = rule.udp.port_min
      source_port_max = rule.udp.port_max
    } : null
    icmp = lookup(rule, "icmp", null) != null ? {
      type = rule.icmp.type
      code = lookup(rule.icmp, "code", null)
    } : null
  }]
  acl_rules = reverse(concat(local.forward_acl_rules_from_sg_rules, local.reverse_acl_rules_from_sg_rules, var.acl_rules))
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

resource ibm_is_security_group_rule additional_rules {
  count = length(local.security_group_rules)

  group      = ibm_is_security_group.vsi.id
  direction  = local.security_group_rules[count.index]["direction"]
  remote     = lookup(local.security_group_rules[count.index], "remote", null)
  ip_version = lookup(local.security_group_rules[count.index], "ip_version", null)

  dynamic "tcp" {
    for_each = lookup(local.security_group_rules[count.index], "tcp", null) != null ? [ lookup(local.security_group_rules[count.index], "tcp", null) ] : []

    content {
      port_min = tcp.value["port_min"]
      port_max = tcp.value["port_max"]
    }
  }

  dynamic "udp" {
    for_each = lookup(local.security_group_rules[count.index], "udp", null) != null ? [ lookup(local.security_group_rules[count.index], "udp", null) ] : []

    content {
      port_min = udp.value["port_min"]
      port_max = udp.value["port_max"]
    }
  }

  dynamic "icmp" {
    for_each = lookup(local.security_group_rules[count.index], "icmp", null) != null ? [ lookup(local.security_group_rules[count.index], "icmp", null) ] : []

    content {
      type = icmp.value["type"]
      code = lookup(icmp.value, "code", null)
    }
  }
}

resource null_resource print_key_crn {
  count = var.kms_enabled ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Key crn: ${var.kms_key_crn == null ? "null" : var.kms_key_crn}'"
  }
}

data ibm_is_subnet subnet {
  count = var.vpc_subnet_count > 0 ? 1 : 0

  identifier = var.vpc_subnets[0].id
}

resource ibm_is_network_acl_rule acl_rules {
  count = length(local.acl_rules)

  network_acl = data.ibm_is_subnet.subnet[0].network_acl
  name        = local.acl_rules[count.index].name
  action      = local.acl_rules[count.index].action
  source      = local.acl_rules[count.index].source
  destination = local.acl_rules[count.index].destination
  direction   = local.acl_rules[count.index].direction
  before      = count.index > 0 ? ibm_is_network_acl_rule.acl_rules[count.index - 1].rule_id : null

  dynamic "tcp" {
    for_each = lookup(local.acl_rules[count.index], "tcp", null) != null ? [ lookup(local.acl_rules[count.index], "tcp", null) != null ] : []

    content {
      port_min = tcp.value["port_min"]
      port_max = tcp.value["port_max"]
      source_port_min = tcp.value["source_port_min"]
      source_port_max = tcp.value["source_port_max"]
    }
  }

  dynamic "udp" {
    for_each = lookup(local.acl_rules[count.index], "udp", null) != null ? [ lookup(local.acl_rules[count.index], "udp", null) != null ] : []

    content {
      port_min = udp.value["port_min"]
      port_max = udp.value["port_max"]
      source_port_min = udp.value["source_port_min"]
      source_port_max = udp.value["source_port_max"]
    }
  }

  dynamic "icmp" {
    for_each = lookup(local.acl_rules[count.index], "icmp", null) != null ? [ lookup(local.acl_rules[count.index], "icmp", null) ] : []

    content {
      type = icmp.value["type"]
      code = lookup(icmp.value, "code", null)
    }
  }
}

resource ibm_is_instance vsi {
  depends_on = [null_resource.print_key_crn, null_resource.print_deprecated, ibm_is_security_group_rule.additional_rules, ibm_is_network_acl_rule.acl_rules]
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
    security_groups = [local.base_security_group, ibm_is_security_group.vsi.id]
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
