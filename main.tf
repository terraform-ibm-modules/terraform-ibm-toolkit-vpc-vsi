
resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
  provisioner "local-exec" {
    command = "echo 'Public key: ${var.sshPublicKey}'"
  }
}

data "ibm_resource_group" "resource_group" {
  depends_on = [null_resource.print_names]

  name = var.resource_group_name
}

locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name        = var.name != "" ? var.name : "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${var.label}"
  service     = "hpvs"
}

resource "ibm_resource_instance" "hpvs_instance" {
  name              = local.name
  service           = local.service
  plan              = var.plan
  location          = var.resource_location
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = var.tags

  parameters = {
    sshPublicKey = var.sshPublicKey
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

data "ibm_resource_instance" "hpvs_instance" {
  depends_on        = [ibm_resource_instance.hpvs_instance]

  name              = local.name
  resource_group_id = data.ibm_resource_group.resource_group.id
  location          = var.resource_location
  service           = local.service
}
