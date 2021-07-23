# VPC Virtual Server instance

Module to provision a Virtual Server Instance (VSI) within an existing Virtual Private Cloud instance. The VSI can optionally be configured with Flow Logs to satisfy requirements imposed by security contraints.

## Software dependencies

The module depends on the following software components:

### Command-line tools

- terraform - v13

### Terraform providers

- IBM Cloud provider >= 1.23.0

## Module dependencies

## Example usage

```hcl-terraform
module "vsi" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-vsi.git"

  resource_group_id = module.resource_group.id
  region            = var.region
  ibmcloud_api_key  = var.ibmcloud_api_key
  vpc_name          = module.vpc.name
  vpc_subnets       = module.subnets.subnets
  vsi_per_subnet    = 2
  ssh_key_id        = module.vpcssh.id
}
```

## Module Variables

Name                   | Type                                                       | Description                                                                                                                                                                                 | Sensitive | Default
---------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ----------------------------------
resource_group_id      | string                                                     | The id of the IBM Cloud resource group where the VPC has been provisioned.                                                                                                                  |           | 
region                 | string                                                     | The IBM Cloud region where the cluster will be/has been installed.                                                                                                                          |           | 
ibmcloud_api_key       | string                                                     | The IBM Cloud api token                                                                                                                                                                     | true      | 
label                  | string                                                     | The label for the server instance                                                                                                                                                           |           | server
vpc_name               | string                                                     | The name of the vpc instance                                                                                                                                                                |           | 
vpc_subnets            | list(object({ label = string id = string zone = string })) | List of subnets with labels                                                                                                                                                                 |           | 
acl_rules              |                                                            | List of rules add to the subnet access control list where the VSI will be provisioned.                                                                                                      |           | []
image_name             | string                                                     | The name of the image to use for the virtual server                                                                                                                                         |           | ibm-ubuntu-18-04-1-minimal-amd64-2
vsi_per_subnet         | number                                                     | The number of VSI to create on each of the subnets                                                                                                                                          |           | 1
profile_name           | string                                                     | Instance profile to use for the bastion instance                                                                                                                                            |           | cx2-2x4
ssh_key_id             | string                                                     | SSH key ID to inject into the virtual server instance. Conflicts with `ssh_public_key`                                                                                                      |           | 
ssh_public_key         | string                                                     | SSH Public key to use when creating VSI. This will create a new VPC SSH key. Conflicts with `ssh_key_id`                                                                                    |           | 
enable_fip             | bool                                                       | Set whether to allocate a public IP address for the virtual server instance                                                                                                                 |           | false
tags                   | list(string)                                               | Tags that should be added to the instance                                                                                                                                                   |           | []
kms_enabled            | bool                                                       | Flag indicating that the volumes should be encrypted using a KMS.                                                                                                                           |           | false
kms_key_crn            | string                                                     | The crn of the root key in the kms instance. Required if kms_enabled is true                                                                                                                |           | 
init_script            | string                                                     | Script to run during the instance initialization. Defaults to an Ubuntu specific script when set to empty                                                                                   |           | 
auto_delete_volume     | bool                                                       | Flag indicating that any attached volumes should be deleted when the instance is deleted                                                                                                    |           | true
security_group         | string                                                     | To use the default VPC security group, leave as `default`. To create a new security group, provide `new`. To use an existing security group, provide the ID.                                |           | new
allow_ssh_from         | string                                                     | An IP address, a CIDR block, or a single security group identifier to allow incoming SSH connection to the virtual server                                                                   |           | 
security_group_rules   |                                                            | List of security group rules to set on the bastion security group in addition to the SSH rules                                                                                              |           | []
allow_deprecated_image | bool                                                       | Flag indicating that deprecated images should be allowed for use in the Virtual Server instance. If the value is `false` and the image is deprecated then the module will fail to provision |           | true

## Module Outputs

Name                  | Description
--------------------- | --------------------------------------------------------
ids                   | The instance ids
names                 | The instance names
crns                  | The crn of the instances
private_ips           | The private ips of the instances
location              | The instance2 location
label                 | The label used for the instance2
network_interface_ids | Primary network interface id
vsi_detail            | A comprehensive list of VSI created and their attributes
public_ips            | The public ips of the instances
service               | The name of the service for the instance
type                  | The type of the service for the instance
security_group_id     | The id of the security group used for the instances