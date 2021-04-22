output "id" {
  description = "The instance id"
  value       = data.ibm_resource_instance.hpvs_instance.id
}

output "name" {
  description = "The instance name"
  value       = local.name
  depends_on  = [data.ibm_resource_instance.hpvs_instance]
}

output "crn" {
  description = "The crn of the instance"
  value       = data.ibm_resource_instance.hpvs_instance.id
}

output "location" {
  description = "The instance location"
  value       = var.resource_location
  depends_on  = [data.ibm_resource_instance.hpvs_instance]
}

output "service" {
  description = "The name of the key provisioned for the instance"
  value       = local.service
  depends_on = [data.ibm_resource_instance.hpvs_instance]
}

output "label" {
  description = "The label used for the instance"
  value       = var.label
  depends_on = [data.ibm_resource_instance.hpvs_instance]
}
