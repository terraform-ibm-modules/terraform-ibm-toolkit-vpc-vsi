##############################################################################
# Local Variables
##############################################################################

locals {
    # Create security group, can be `default`, `new`, or the ID of an existing security group
    security_group = (
        var.security_group == "default" 
            ? data.ibm_is_vpc.vpc.default_security_group
            : var.security_group
    )
    # Security Group ID
    security_group_id = var.security_group == "new" ? ibm_is_security_group.vsi_sg[0].id : local.security_group 
}

##############################################################################


##############################################################################
# Optionally Create new Security Group
##############################################################################

resource ibm_is_security_group vsi_sg {
    count          = var.security_group == "new" ? 1 : 0
    name           = "${local.name}-group"
    vpc            = data.ibm_is_vpc.vpc.id
    resource_group = var.resource_group_id
}

##############################################################################


##############################################################################
# Security Group SSH Rule
##############################################################################

resource ibm_is_security_group_rule ssh_inbound {
    count = var.allow_ssh_from != "" ? 1 : 0

    group     = local.security_group_id
    direction = "inbound"
    remote    = var.allow_ssh_from
    tcp {
        port_min = 22
        port_max = 22
    }
}

resource ibm_is_security_group_rule ssh_to_self_public_ip {
  for_each        = var.enable_fip ? ibm_is_instance.vsi : {}

  group      = local.security_group_id
  direction  = "outbound"
  remote     = each.value.primary_network_interface.0.primary_ipv4_address
  tcp {
      port_min = 22
      port_max = 22
  }
}

##############################################################################


##############################################################################
# Additional Security Group Rules
##############################################################################

resource ibm_is_security_group_rule additional_rules {
  count = length(var.security_group_rules)

  group      = local.security_group_id
  direction  = var.security_group_rules[count.index]["direction"]
  remote     = lookup(var.security_group_rules[count.index], "remote", null)
  ip_version = lookup(var.security_group_rules[count.index], "ip_version", null)

  dynamic tcp {
    for_each = lookup(var.security_group_rules[count.index], "tcp", null) != null ? [ lookup(var.security_group_rules[count.index], "tcp", null) ] : []

    content {
      port_min = tcp.value["port_min"]
      port_max = tcp.value["port_max"]
    }
  }

  dynamic udp {
    for_each = lookup(var.security_group_rules[count.index], "udp", null) != null ? [ lookup(var.security_group_rules[count.index], "udp", null) ] : []

    content {
      port_min = udp.value["port_min"]
      port_max = udp.value["port_max"]
    }
  }

  dynamic icmp {
    for_each = lookup(var.security_group_rules[count.index], "icmp", null) != null ? [ lookup(var.security_group_rules[count.index], "icmp", null) ] : []

    content {
      type = icmp.value["type"]
      code = lookup(icmp.value, "code", null)
    }
  }
}

##############################################################################