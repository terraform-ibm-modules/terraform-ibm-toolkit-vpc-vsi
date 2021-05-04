
module "cos" {
  source = "github.com/ibm-garage-cloud/terraform-ibm-object-storage.git"

  resource_group_name = module.resource_group.name
  name_prefix         = var.name_prefix
}

resource null_resource print_cos_id {
  depends_on = [module.cos.id]
  provisioner "local-exec" {
    command = "echo 'Provisioning bucket into COS instance: ${module.cos.id}'"
  }
}

resource "ibm_iam_authorization_policy" "policy" {
  source_service_name = "is"
  source_resource_type = "flow-log-collector"
  target_service_name = "cloud-object-storage"
  roles = ["Writer"]
}

module "dev_cos_bucket" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-object-storage-bucket.git"

  resource_group_name = module.resource_group.name
  cos_instance_id     = module.cos.id
  name_prefix         = var.name_prefix
  ibmcloud_api_key    = var.ibmcloud_api_key
  name                = "${var.name_prefix}-fl-testing-gsi"
  region              = var.region
}

resource null_resource print_bucket {
  provisioner "local-exec" {
    command = "echo 'Bucket created: ${module.dev_cos_bucket.bucket_name}'"
  }
}
