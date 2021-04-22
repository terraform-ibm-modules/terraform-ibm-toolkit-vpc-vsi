variable "ibmcloud_api_key" {
  type        = string
  description = "The api key for IBM Cloud access"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where the cluster has been provisioned."
    
}

variable "resource_location" {
  type        = string
  description = "Geographic location of the resource (e.g. us-south, us-east)"
  default = "dal10"
}

variable "tags" {
  type        = list(string)
  description = "Tags that should be applied to the service"
  default     = []
}

variable "name_prefix" {
  type        = string
  description = "The prefix name for the service. If not provided it will default to the resource group name"
  default     = ""
}

variable "name" {
  type        = string
  description = "The name that should be used for the service, particularly when connecting to an existing service. If not provided then the name will be defaulted to {name prefix}-{service}"
  default     = ""
}

variable "plan" {
  type        = string
  description = "The type of plan the service instance should run under (free, entry, small, medium)"
  default     = "entry"
}

variable "sshPublicKey" {
  type        = string
  description = "sshPublicKey that should be applied to the service"  
}

variable "label" {
  type        = string
  description = "The label used to build the resource name along with the name_prefix"
  default     = "hpvs"
}


