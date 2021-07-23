##############################################################################
# Module Variables
##############################################################################

variable resource_group_id {
  type        = string
  description = "The id of the IBM Cloud resource group where the VPC has been provisioned."
}

variable region {
  type        = string
  description = "The IBM Cloud region where the cluster will be/has been installed."
}

variable ibmcloud_api_key {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable label {
  type        = string
  description = "The label for the server instance"
  default     = "server"
}

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable vpc_name {
  type        = string
  description = "The name of the vpc instance"
}

variable vpc_subnets {
  type        = list(object({
    label = string
    id    = string
    zone  = string
  }))
  description = "List of subnets with labels"
}

variable acl_rules {
  # type = list(object({
  #   name=string,
  #   action=string,
  #   direction=string,
  #   source=string,
  #   destination=string,
  #   tcp=optional(object({
  #     port_min=number,
  #     port_max=number,
  #     source_port_min=number,
  #     source_port_max=number
  #   })),
  #   udp=optional(object({
  #     port_min=number,
  #     port_max=number,
  #     source_port_min=number,
  #     source_port_max=number
  #   })),
  #   icmp=optional(object({
  #     type=number,
  #     code=optional(number)
  #   })),
  # }))
  description = "List of rules add to the subnet access control list where the VSI will be provisioned."
  default = []
}

##############################################################################


##############################################################################
# VSI Variables
##############################################################################

variable image_name {
  type        = string
  description = "The name of the image to use for the virtual server"
  default     = "ibm-ubuntu-18-04-1-minimal-amd64-2"
}

variable vsi_per_subnet {
  description = "The number of VSI to create on each of the subnets"
  type        = number
  default     = 1
  validation {
    error_message = "The number of VSI per subnet must be at least 1."
    condition     = var.vsi_per_subnet > 0
  }
}

variable profile_name {
  type        = string
  description = "Instance profile to use for the bastion instance"
  default     = "cx2-2x4"
}

variable ssh_key_id {
  type        = string
  description = "SSH key ID to inject into the virtual server instance. Conflicts with `ssh_public_key`"
  default     = ""
}

variable ssh_public_key {
  type        = string
  description = "SSH Public key to use when creating VSI. This will create a new VPC SSH key. Conflicts with `ssh_key_id`"
  default     = ""
}

variable enable_fip {
  type        = bool
  description = "Set whether to allocate a public IP address for the virtual server instance"
  default     = false
}

variable tags {
  type        = list(string)
  default     = []
  description = "Tags that should be added to the instance"
}

variable kms_enabled {
  type        = bool
  description = "Flag indicating that the volumes should be encrypted using a KMS."
  default     = false
}

variable kms_key_crn {
  type        = string
  description = "The crn of the root key in the kms instance. Required if kms_enabled is true"
  default     = ""
}

variable init_script {
  type        = string
  default     = ""
  description = "Script to run during the instance initialization. Defaults to an Ubuntu specific script when set to empty"
}

variable auto_delete_volume {
  type        = bool
  description = "Flag indicating that any attached volumes should be deleted when the instance is deleted"
  default     = true
}

##############################################################################


##############################################################################
# Security Group Variables
##############################################################################

variable security_group {
  type        = string
  description = "To use the default VPC security group, leave as `default`. To create a new security group, provide `new`. To use an existing security group, provide the ID."
  default     = "new"
}


variable allow_ssh_from {
  type        = string
  description = "An IP address, a CIDR block, or a single security group identifier to allow incoming SSH connection to the virtual server"
  default     = ""
}

variable security_group_rules {
  # type = list(object({
  #   name=string,
  #   direction=string,
  #   remote=optional(string),
  #   ip_version=optional(string),
  #   tcp=optional(object({
  #     port_min=number,
  #     port_max=number
  #   })),
  #   udp=optional(object({
  #     port_min=number,
  #     port_max=number
  #   })),
  #   icmp=optional(object({
  #     type=number,
  #     code=optional(number)
  #   })),
  # }))
  description = "List of security group rules to set on the bastion security group in addition to the SSH rules"
  default = []
}

variable allow_deprecated_image {
  type        = bool
  description = "Flag indicating that deprecated images should be allowed for use in the Virtual Server instance. If the value is `false` and the image is deprecated then the module will fail to provision"
  default     = true
}

##############################################################################


