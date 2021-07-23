##############################################################################
# VSI Outputs
##############################################################################

output ids {
  description = "The instance ids"
  value       = [ for i in ibm_is_instance.vsi: i.id ]
}

output names {
  description = "The instance names"
  value       = [ for i in ibm_is_instance.vsi: i.name ]
}

output crns {
  description = "The crn of the instances"
  value       = [ for i in ibm_is_instance.vsi: i.id ]
}

output private_ips {
  value       = [ for i in ibm_is_instance.vsi: i.primary_network_interface[0].primary_ipv4_address ]
  description = "The private ips of the instances"
}

output location {
  description = "The instance2 location"
  value       = var.region
  depends_on  = [ibm_is_instance.vsi]
}

output label {
  description = "The label used for the instance2"
  value       = var.label
  depends_on = [ibm_is_instance.vsi]
}

output network_interface_ids {
  description = "Primary network interface id"
  value       = [ for i in ibm_is_instance.vsi: i.primary_network_interface[0].id ]
}

output vsi_detail {
  description = "A comprehensive list of VSI created and their attributes"
  value       = [
    for i in ibm_is_instance.vsi:
    {
      name                         = i.name
      id                           = i.id
      private_ip                   = i.primary_network_interface[0].primary_ipv4_address
      primary_network_interface_id = i.primary_network_interface[0].id 
      location                     = var.region
      label                        = var.label
      public_ip                    = var.enable_fip ? ibm_is_floating_ip.vsi[i.name].address : null
      security_group               = local.security_group_id
    }
  ]
}

##############################################################################


##############################################################################
# Floating IP Variables
##############################################################################

output public_ips {
  depends_on  = [ ibm_is_floating_ip.vsi ]
  description = "The public ips of the instances"
  value       = var.enable_fip ? [ for i in ibm_is_floating_ip.vsi: i.address ] : []
}

##############################################################################


##############################################################################
# Service Outputs
##############################################################################

output service {
  description = "The name of the service for the instance"
  value       = "is"
  depends_on = [ibm_is_instance.vsi]
}

output type {
  description = "The type of the service for the instance"
  value       = "instance"
  depends_on = [ibm_is_instance.vsi]
}

##############################################################################


##############################################################################
# Security Group Outputs
##############################################################################

output security_group_id {
  description = "The id of the security group used for the instances"
  value       = local.security_group_id
}

##############################################################################