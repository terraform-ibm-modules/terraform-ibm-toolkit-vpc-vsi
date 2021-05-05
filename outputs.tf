output "ids" {
  description = "The instance id"
  value       = ibm_is_instance.vsi[*].id
}

output "names" {
  description = "The instance name"
  value       = ibm_is_instance.vsi[*].name
}

output "crns" {
  description = "The crn of the instance"
  value       = ibm_is_instance.vsi[*].id
}

output "public_ips" {
  description = "The public ips of the instances"
  value       = var.create_public_ip ? ibm_is_floating_ip.vsi[*].address : []
}

output "private_ips" {
  value = ibm_is_instance.vsi[*].primary_network_interface[0].primary_ipv4_address
  description = "The private ips of the instances"
}

output "location" {
  description = "The instance location"
  value       = var.region
  depends_on  = [ibm_is_instance.vsi]
}

output "service" {
  description = "The name of the service for the instance"
  value       = "is"
  depends_on = [ibm_is_instance.vsi]
}

output "type" {
  description = "The type of the service for the instance"
  value       = "instance"
  depends_on = [ibm_is_instance.vsi]
}

output "label" {
  description = "The label used for the instance"
  value       = var.label
  depends_on = [ibm_is_instance.vsi]
}

output "security_group_id" {
  description = "The id of the security group that was created"
  value       = ibm_is_security_group.vsi.id
}

output "security_group" {
  description = "The security group that was created"
  value       = ibm_is_security_group.vsi
}

output network_interface_ids {
  value = ibm_is_instance.vsi[*].primary_network_interface[0].id
}
