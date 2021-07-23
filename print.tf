##############################################################################
# Contains Print Null Resources
##############################################################################

resource null_resource print_names {
  provisioner local-exec {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
}

resource null_resource print_deprecated {
  provisioner local-exec {
    command = "${path.module}/scripts/check-image.sh '${data.ibm_is_image.image.status}' '${data.ibm_is_image.image.name}' '${var.allow_deprecated_image}'"
  }
}

resource null_resource print_key_crn {
  count = var.kms_enabled ? 1 : 0

  provisioner local-exec {
    command = "echo 'Key crn: ${var.kms_key_crn == null ? "null" : var.kms_key_crn}'"
  }
}

##############################################################################