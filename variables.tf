variable "resource_group_id" {
  type        = string
  description = "The id of the IBM Cloud resource group where the VPC has been provisioned."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster will be/has been installed."
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
}

variable "vpc_name" {
  type        = string
  description = "The name of the vpc instance"
}

variable "label" {
  type        = string
  description = "The label for the server instance"
  default     = "server"
}

variable "image_name" {
  type        = string
  description = "The name of the image to use for the virtual server"
  default     = "ibm-ubuntu-18-04-1-minimal-amd64-2"
}

variable "vpc_subnet_count" {
  type        = number
  description = "Number of vpc subnets"
}

variable "vpc_subnets" {
  type        = list(object({
    label = string
    id    = string
    zone  = string
  }))
  description = "List of subnets with labels"
}

variable "profile_name" {
  type        = string
  description = "Instance profile to use for the bastion instance"
  default     = "cx2-2x4"
}

variable "ssh_key_ids" {
  type        = list(string)
  description = "List of SSH key IDs to inject into the virtual server instance"
  default     = []
}

variable "allow_ssh_from" {
  type        = string
  description = "An IP address, a CIDR block, or a single security group identifier to allow incoming SSH connection to the virtual server"
  default     = ""
}

variable "create_public_ip" {
  type        = bool
  description = "Set whether to allocate a public IP address for the virtual server instance"
  default     = false
}

variable "init_script" {
  type        = string
  default     = ""
  description = "Script to run during the instance initialization. Defaults to an Ubuntu specific script when set to empty"
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Tags that should be added to the instance"
}

variable "flow_log_cos_bucket_name" {
  type        = string
  description = "Cloud Object Storage bucket id for flow logs (optional)"
  default     = ""
}

variable "kms_enabled" {
  type        = bool
  description = "Flag indicating that the volumes should be encrypted using a KMS."
  default     = false
}

variable "kms_key_crn" {
  type        = string
  description = "The crn of the root key in the kms instance. Required if kms_enabled is true"
  default     = ""
}

variable "auto_delete_volume" {
  type        = bool
  description = "Flag indicating that any attached volumes should be deleted when the instance is deleted"
  default     = true
}
